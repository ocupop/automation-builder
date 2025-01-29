const allowedDomain = 'ocupop.com';

exports.handler = async (event) => {
    const email = event.request.userAttributes.email;
    
    // Check if email is from ocupop.com domain
    if (!email.endsWith(`@${allowedDomain}`)) {
        throw new Error(`Only ${allowedDomain} email addresses are allowed.`);
    }
    
    // Auto confirm the user if email domain is valid
    event.response.autoConfirmUser = true;
    event.response.autoVerifyEmail = true;
    
    return event;
};
