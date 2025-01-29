exports.validateEmail = async (req, res) => {
    const allowedDomain = process.env.ALLOWED_DOMAIN;
    const email = req.body.email;

    if (!email) {
        res.status(400).json({ error: 'Email is required' });
        return;
    }

    if (!email.endsWith(`@${allowedDomain}`)) {
        res.status(403).json({ error: `Only ${allowedDomain} email addresses are allowed` });
        return;
    }

    // Generate a magic link
    const magicLink = await generateMagicLink(email);
    
    // Send email with magic link
    await sendMagicLinkEmail(email, magicLink);

    res.status(200).json({ message: 'Magic link sent successfully' });
};

const generateMagicLink = async (email) => {
    // Implementation for generating secure magic link
    const token = crypto.randomBytes(32).toString('hex');
    // Store token with expiration in database/cache
    return `https://${process.env.DOMAIN}/auth/verify?token=${token}`;
};

const sendMagicLinkEmail = async (email, magicLink) => {
    // Implementation for sending email using Cloud Functions
    // You can use services like Sendgrid, Mailgun, or Cloud Tasks
};
