const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const RATE_LIMIT = {
    MAX_ATTEMPTS: 5,      // Maximum attempts per time window
    WINDOW_MINUTES: 15,   // Time window in minutes
    LOCKOUT_MINUTES: 60   // Lockout duration after exceeding attempts
};

exports.handler = async (event) => {
    const email = event.request.userAttributes.email;
    const ip = event.request.userAttributes.sourceIp;
    const timestamp = Math.floor(Date.now() / 1000);
    const windowStart = timestamp - (RATE_LIMIT.WINDOW_MINUTES * 60);
    
    // Check both email and IP-based rate limits
    const [emailAttempts, ipAttempts] = await Promise.all([
        checkRateLimit(`email:${email}`, windowStart),
        checkRateLimit(`ip:${ip}`, windowStart)
    ]);
    
    if (emailAttempts.isLocked || ipAttempts.isLocked) {
        throw new Error('Too many attempts. Please try again later.');
    }
    
    if (emailAttempts.count >= RATE_LIMIT.MAX_ATTEMPTS || 
        ipAttempts.count >= RATE_LIMIT.MAX_ATTEMPTS) {
        // Lock the account/IP
        await Promise.all([
            setLockout(`email:${email}`, timestamp),
            setLockout(`ip:${ip}`, timestamp)
        ]);
        throw new Error('Rate limit exceeded. Account locked for security.');
    }
    
    // Record the attempt
    await Promise.all([
        recordAttempt(`email:${email}`, timestamp),
        recordAttempt(`ip:${ip}`, timestamp)
    ]);
    
    return event;
};

async function checkRateLimit(identifier, windowStart) {
    const params = {
        TableName: process.env.RATE_LIMIT_TABLE,
        KeyConditionExpression: 'identifier = :id AND timestamp >= :start',
        ExpressionAttributeValues: {
            ':id': identifier,
            ':start': windowStart
        }
    };
    
    const result = await dynamoDB.query(params).promise();
    const lockoutRecord = await getLockoutStatus(identifier);
    
    return {
        count: result.Items.length,
        isLocked: lockoutRecord && 
                 lockoutRecord.lockoutUntil > Math.floor(Date.now() / 1000)
    };
}

async function recordAttempt(identifier, timestamp) {
    await dynamoDB.put({
        TableName: process.env.RATE_LIMIT_TABLE,
        Item: {
            identifier,
            timestamp,
            ttl: timestamp + (RATE_LIMIT.WINDOW_MINUTES * 60)
        }
    }).promise();
}

async function setLockout(identifier, timestamp) {
    await dynamoDB.put({
        TableName: process.env.RATE_LIMIT_TABLE,
        Item: {
            identifier: `lockout:${identifier}`,
            timestamp,
            lockoutUntil: timestamp + (RATE_LIMIT.LOCKOUT_MINUTES * 60),
            ttl: timestamp + (RATE_LIMIT.LOCKOUT_MINUTES * 60)
        }
    }).promise();
}

async function getLockoutStatus(identifier) {
    const result = await dynamoDB.get({
        TableName: process.env.RATE_LIMIT_TABLE,
        Key: {
            identifier: `lockout:${identifier}`
        }
    }).promise();
    
    return result.Item;
}
