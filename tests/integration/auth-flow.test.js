const axios = require('axios');
const AWS = require('aws-sdk');
const { Firestore } = require('@google-cloud/firestore');

describe('Authentication Flow Integration Tests', () => {
    const BASE_URL = process.env.API_BASE_URL;
    const TEST_EMAIL = 'test@ocupop.com';

    describe('AWS Flow', () => {
        let cognitoIdentity;
        
        beforeAll(() => {
            cognitoIdentity = new AWS.CognitoIdentityServiceProvider({
                region: process.env.AWS_REGION
            });
        });

        test('complete authentication flow', async () => {
            // Step 1: Request magic link
            const magicLinkResponse = await axios.post(`${BASE_URL}/auth/magic-link`, {
                email: TEST_EMAIL
            });
            expect(magicLinkResponse.status).toBe(200);

            // Step 2: Get magic link from email (mock)
            const magicLink = await getMagicLinkFromEmail(TEST_EMAIL);
            expect(magicLink).toBeTruthy();

            // Step 3: Verify magic link
            const verifyResponse = await axios.get(magicLink);
            expect(verifyResponse.status).toBe(200);
            expect(verifyResponse.data.token).toBeTruthy();

            // Step 4: Access protected resource
            const protectedResponse = await axios.get(`${BASE_URL}/protected`, {
                headers: {
                    Authorization: `Bearer ${verifyResponse.data.token}`
                }
            });
            expect(protectedResponse.status).toBe(200);
        });

        test('rate limiting', async () => {
            const attempts = [];
            
            // Make 6 requests (exceeding limit)
            for (let i = 0; i < 6; i++) {
                try {
                    const response = await axios.post(`${BASE_URL}/auth/magic-link`, {
                        email: TEST_EMAIL
                    });
                    attempts.push(response.status);
                } catch (error) {
                    attempts.push(error.response.status);
                }
            }

            // Verify rate limiting kicked in
            expect(attempts).toContain(429);
        });
    });

    describe('GCP Flow', () => {
        let firestore;

        beforeAll(() => {
            firestore = new Firestore();
        });

        test('complete authentication flow', async () => {
            // Step 1: Request magic link
            const magicLinkResponse = await axios.post(`${BASE_URL}/auth/magic-link`, {
                email: TEST_EMAIL
            });
            expect(magicLinkResponse.status).toBe(200);

            // Step 2: Get magic link from email (mock)
            const magicLink = await getMagicLinkFromEmail(TEST_EMAIL);
            expect(magicLink).toBeTruthy();

            // Step 3: Verify magic link
            const verifyResponse = await axios.get(magicLink);
            expect(verifyResponse.status).toBe(200);
            expect(verifyResponse.data.token).toBeTruthy();

            // Step 4: Verify session creation
            const sessionDoc = await firestore
                .collection('sessions')
                .where('userId', '==', TEST_EMAIL)
                .limit(1)
                .get();
            
            expect(sessionDoc.empty).toBe(false);
        });

        test('domain restriction', async () => {
            const response = await axios.post(`${BASE_URL}/auth/magic-link`, {
                email: 'test@invalid.com'
            }).catch(error => error.response);

            expect(response.status).toBe(403);
        });
    });
});

// Mock function to simulate email retrieval
async function getMagicLinkFromEmail(email) {
    // In a real test, this would integrate with your email testing infrastructure
    return `${BASE_URL}/auth/verify?token=test-token`;
}
