const fs = require('fs');
const path = require('path');

exports.handler = async (event) => {
    if (event.triggerSource === "CustomMessage_SignUp" || 
        event.triggerSource === "CustomMessage_ResendCode") {
        
        // Read email template
        const templatePath = path.join(__dirname, 'templates', 'magic-link.html');
        let emailTemplate = fs.readFileSync(templatePath, 'utf8');
        
        const magicLink = event.request.linkParameter;
        const currentYear = new Date().getFullYear();
        
        // Replace template variables
        emailTemplate = emailTemplate
            .replace(/{{APP_NAME}}/g, process.env.APP_NAME)
            .replace(/{{MAGIC_LINK}}/g, magicLink)
            .replace(/{{CURRENT_YEAR}}/g, currentYear)
            .replace(/{{OCUPOP_LOGO_URL}}/g, process.env.OCUPOP_LOGO_URL);
        
        // Set custom email subject and message
        event.response.emailSubject = `Sign in to ${process.env.APP_NAME}`;
        event.response.emailMessage = emailTemplate;
        
        // Add session metadata
        const sessionMetadata = {
            createdAt: Date.now(),
            expiresIn: 900, // 15 minutes in seconds
            deviceInfo: event.request.userAttributes.deviceInfo || 'unknown'
        };
        
        // Store session metadata in the response
        event.response.claimsOverrideDetails = {
            claimsToAddOrOverride: {
                sessionMetadata: JSON.stringify(sessionMetadata)
            }
        };
    }
    
    return event;
};
