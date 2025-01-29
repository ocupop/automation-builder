const { Firestore } = require('@google-cloud/firestore');
const { CloudTasksClient } = require('@google-cloud/tasks');

let firestoreClient;
let tasksClientInstance;

const initializeFirestore = () => {
    if (!firestoreClient) {
        firestoreClient = new Firestore();
    }
    return firestoreClient;
};

const initializeTasksClient = () => {
    if (!tasksClientInstance) {
        tasksClientInstance = new CloudTasksClient();
    }
    return tasksClientInstance;
};

const RATE_LIMIT = {
    MAX_ATTEMPTS: 5,
    WINDOW_MINUTES: 15,
    LOCKOUT_MINUTES: 60
};

exports.checkRateLimit = async (req, res) => {
    try {
        const db = initializeFirestore();
        const tasksClient = initializeTasksClient();
        const { email, ip } = req.body;
        const timestamp = Math.floor(Date.now() / 1000);
        const windowStart = timestamp - (RATE_LIMIT.WINDOW_MINUTES * 60);

        // Check both email and IP-based rate limits
        const [emailLimits, ipLimits] = await Promise.all([
            checkLimits(db, `email:${email}`, windowStart),
            checkLimits(db, `ip:${ip}`, windowStart)
        ]);

        if (emailLimits.isLocked || ipLimits.isLocked) {
            const retryAfter = Math.max(
                emailLimits.lockoutUntil || 0,
                ipLimits.lockoutUntil || 0
            ) - timestamp;

            res.status(429).json({
                error: 'Too many attempts. Please try again later.',
                retryAfter
            });
            return;
        }

        if (emailLimits.count >= RATE_LIMIT.MAX_ATTEMPTS ||
            ipLimits.count >= RATE_LIMIT.MAX_ATTEMPTS) {
            // Set lockout
            await Promise.all([
                setLockout(db, `email:${email}`, timestamp),
                setLockout(db, `ip:${ip}`, timestamp)
            ]);

            // Schedule lockout cleanup
            await scheduleLockoutCleanup(tasksClient, email, ip, timestamp);

            res.status(429).json({
                error: 'Rate limit exceeded. Account locked for security.',
                retryAfter: RATE_LIMIT.LOCKOUT_MINUTES * 60
            });
            return;
        }

        // Record attempts
        await Promise.all([
            recordAttempt(db, `email:${email}`, timestamp),
            recordAttempt(db, `ip:${ip}`, timestamp)
        ]);

        res.status(200).json({ allowed: true });
    } catch (error) {
        console.error('Rate limit check error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

async function checkLimits(db, identifier, windowStart) {
    const attemptsRef = db.collection('rateLimits')
        .where('identifier', '==', identifier)
        .where('timestamp', '>=', windowStart)
        .where('type', '==', 'attempt');

    const lockoutRef = db.collection('rateLimits')
        .doc(`lockout:${identifier}`);

    const [attempts, lockout] = await Promise.all([
        attemptsRef.get(),
        lockoutRef.get()
    ]);

    const lockoutData = lockout.exists ? lockout.data() : null;

    return {
        count: attempts.size,
        isLocked: lockoutData && lockoutData.lockoutUntil > Math.floor(Date.now() / 1000),
        lockoutUntil: lockoutData ? lockoutData.lockoutUntil : null
    };
}

async function recordAttempt(db, identifier, timestamp) {
    await db.collection('rateLimits').add({
        identifier,
        timestamp,
        type: 'attempt',
        ttl: timestamp + (RATE_LIMIT.WINDOW_MINUTES * 60)
    });
}

async function setLockout(db, identifier, timestamp) {
    const lockoutUntil = timestamp + (RATE_LIMIT.LOCKOUT_MINUTES * 60);
    await db.collection('rateLimits')
        .doc(`lockout:${identifier}`)
        .set({
            identifier,
            type: 'lockout',
            lockoutUntil,
            ttl: lockoutUntil
        });
}

async function scheduleLockoutCleanup(tasksClient, email, ip, timestamp) {
    const project = process.env.PROJECT_ID;
    const queue = 'rate-limit-cleanup';
    const location = process.env.REGION;

    const task = {
        httpRequest: {
            httpMethod: 'POST',
            url: `${process.env.CLEANUP_FUNCTION_URL}`,
            body: Buffer.from(JSON.stringify({
                email,
                ip,
                timestamp
            })).toString('base64'),
            headers: {
                'Content-Type': 'application/json'
            }
        },
        scheduleTime: {
            seconds: timestamp + (RATE_LIMIT.LOCKOUT_MINUTES * 60)
        }
    };

    await tasksClient.createTask({
        parent: tasksClient.queuePath(project, location, queue),
        task
    });
}
