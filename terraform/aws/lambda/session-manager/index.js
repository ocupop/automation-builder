const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const sessionId = event.request.session;
    const userId = event.request.userAttributes.sub;
    
    // Session configuration
    const sessionDuration = 3600; // 1 hour in seconds
    const maxInactiveDuration = 900; // 15 minutes in seconds
    
    if (event.triggerSource === 'TokenGeneration_Authentication') {
        // Create or update session
        const timestamp = Math.floor(Date.now() / 1000);
        const expirationTime = timestamp + sessionDuration;
        
        await dynamoDB.put({
            TableName: process.env.SESSION_TABLE_NAME,
            Item: {
                sessionId: sessionId,
                userId: userId,
                lastActivity: timestamp,
                expirationTime: expirationTime,
                status: 'active'
            }
        }).promise();
        
        // Add session information to the token
        event.response.claimsOverrideDetails = {
            claimsToAddOrOverride: {
                sessionId: sessionId,
                sessionExpires: expirationTime.toString()
            }
        };
    } else if (event.triggerSource === 'TokenGeneration_RefreshTokens') {
        // Check session validity
        const session = await dynamoDB.get({
            TableName: process.env.SESSION_TABLE_NAME,
            Key: { sessionId: sessionId }
        }).promise();
        
        if (!session.Item || 
            session.Item.status !== 'active' || 
            session.Item.lastActivity + maxInactiveDuration < Math.floor(Date.now() / 1000)) {
            throw new Error('Session expired or invalid');
        }
        
        // Update last activity
        await dynamoDB.update({
            TableName: process.env.SESSION_TABLE_NAME,
            Key: { sessionId: sessionId },
            UpdateExpression: 'set lastActivity = :time',
            ExpressionAttributeValues: {
                ':time': Math.floor(Date.now() / 1000)
            }
        }).promise();
    }
    
    return event;
};
