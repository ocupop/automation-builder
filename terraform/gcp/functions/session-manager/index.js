const { Firestore } = require('@google-cloud/firestore');
const firestore = new Firestore();

exports.manageSession = async (req, res) => {
    try {
        const { action, sessionId, userId } = req.body;
        
        // Session configuration
        const sessionDuration = 3600; // 1 hour in seconds
        const maxInactiveDuration = 900; // 15 minutes in seconds
        const timestamp = Math.floor(Date.now() / 1000);
        
        const sessionRef = firestore.collection('sessions').doc(sessionId);
        
        switch (action) {
            case 'create':
                await sessionRef.set({
                    userId,
                    createdAt: timestamp,
                    lastActivity: timestamp,
                    expiresAt: timestamp + sessionDuration,
                    status: 'active'
                });
                
                res.status(200).json({
                    sessionId,
                    expiresAt: timestamp + sessionDuration
                });
                break;
                
            case 'validate':
                const session = await sessionRef.get();
                
                if (!session.exists) {
                    res.status(404).json({ error: 'Session not found' });
                    return;
                }
                
                const sessionData = session.data();
                
                // Check session validity
                if (sessionData.status !== 'active' ||
                    sessionData.lastActivity + maxInactiveDuration < timestamp) {
                    await sessionRef.update({ status: 'expired' });
                    res.status(401).json({ error: 'Session expired' });
                    return;
                }
                
                // Update last activity
                await sessionRef.update({ lastActivity: timestamp });
                res.status(200).json({ valid: true });
                break;
                
            case 'invalidate':
                await sessionRef.update({
                    status: 'terminated',
                    terminatedAt: timestamp
                });
                
                res.status(200).json({ message: 'Session terminated' });
                break;
                
            default:
                res.status(400).json({ error: 'Invalid action' });
        }
    } catch (error) {
        console.error('Session management error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
