const fs = require('fs');
const path = require('path');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const nodemailer = require('nodemailer');

const secretManager = new SecretManagerServiceClient();

async function getSecret(name) {
    const [version] = await secretManager.accessSecretVersion({
        name: `projects/${process.env.PROJECT_ID}/secrets/${name}/versions/latest`,
    });
    return version.payload.data.toString();
}

exports.sendMagicLink = async (req, res) => {
    try {
        const { email, magicLink, deviceInfo } = req.body;
        
        // Read email template
        const templatePath = path.join(__dirname, '..', 'email-templates', 'magic-link.html');
        let emailTemplate = fs.readFileSync(templatePath, 'utf8');
        
        // Get SMTP credentials from Secret Manager
        const smtpUsername = await getSecret('smtp-username');
        const smtpPassword = await getSecret('smtp-password');
        
        // Configure email transport
        const transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: 587,
            secure: false,
            auth: {
                user: smtpUsername,
                pass: smtpPassword
            }
        });
        
        // Prepare template variables
        const currentYear = new Date().getFullYear();
        const requestTime = new Date().toLocaleString('en-US', { timeZone: 'America/Los_Angeles' });
        
        // Replace template variables
        emailTemplate = emailTemplate
            .replace(/{{APP_NAME}}/g, process.env.APP_NAME)
            .replace(/{{MAGIC_LINK}}/g, magicLink)
            .replace(/{{CURRENT_YEAR}}/g, currentYear)
            .replace(/{{OCUPOP_LOGO_URL}}/g, process.env.OCUPOP_LOGO_URL)
            .replace(/{{REQUEST_TIME}}/g, requestTime)
            .replace(/{{DEVICE_INFO}}/g, deviceInfo)
            .replace(/{{REQUEST_LOCATION}}/g, 'Secure Location'); // You can implement IP geolocation here
        
        // Send email
        await transporter.sendMail({
            from: `"${process.env.APP_NAME}" <noreply@ocupop.com>`,
            to: email,
            subject: `Sign in to ${process.env.APP_NAME}`,
            html: emailTemplate
        });
        
        res.status(200).json({ message: 'Magic link email sent successfully' });
    } catch (error) {
        console.error('Error sending magic link email:', error);
        res.status(500).json({ error: 'Failed to send magic link email' });
    }
};
