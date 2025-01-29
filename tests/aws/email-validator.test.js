const { handler } = require('../../terraform/aws/lambda/email-validator');

describe('Email Validator Tests', () => {
    let event;

    beforeEach(() => {
        event = {
            request: {
                userAttributes: {
                    email: 'test@ocupop.com'
                }
            },
            response: {}
        };
    });

    test('should allow valid ocupop.com email', async () => {
        const result = await handler(event);
        expect(result.response.autoConfirmUser).toBe(true);
        expect(result.response.autoVerifyEmail).toBe(true);
    });

    test('should reject non-ocupop email', async () => {
        event.request.userAttributes.email = 'test@invalid.com';
        await expect(handler(event)).rejects.toThrow('Only ocupop.com email addresses are allowed');
    });

    test('should handle empty email', async () => {
        event.request.userAttributes.email = '';
        await expect(handler(event)).rejects.toThrow();
    });

    test('should handle malformed email', async () => {
        event.request.userAttributes.email = 'invalid-email';
        await expect(handler(event)).rejects.toThrow();
    });
});
