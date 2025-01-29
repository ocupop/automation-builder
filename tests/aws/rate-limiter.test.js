const AWS = require('aws-sdk-mock');
const awsSdk = require('aws-sdk');
const { handler } = require('../../terraform/aws/lambda/rate-limiter');

AWS.setSDK(require.resolve('aws-sdk'));

describe('Rate Limiter Tests', () => {
    beforeEach(() => {
        process.env.AWS_REGION = 'us-west-2';
        process.env.AWS_ACCESS_KEY_ID = 'test';
        process.env.AWS_SECRET_ACCESS_KEY = 'test';
        process.env.RATE_LIMIT_TABLE = 'test-rate-limit-table';
        
        awsSdk.config.update({
            region: process.env.AWS_REGION,
            credentials: new awsSdk.Credentials({
                accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
            })
        });
        
        AWS.restore();
        
        // Mock DynamoDB methods
        AWS.mock('DynamoDB.DocumentClient', 'query', (params, callback) => {
            callback(null, { Items: [] });
        });
        
        AWS.mock('DynamoDB.DocumentClient', 'get', (params, callback) => {
            callback(null, { Item: null });
        });
        
        AWS.mock('DynamoDB.DocumentClient', 'put', (params, callback) => {
            callback(null, {});
        });
    });

    afterEach(() => {
        AWS.restore();
    });

    test('should allow first attempt', async () => {
        const event = {
            request: {
                userAttributes: {
                    email: 'test@ocupop.com',
                    sourceIp: '127.0.0.1'
                }
            }
        };

        const result = await handler(event);
        expect(result).toEqual(event);
    });

    test('should block after max attempts', async () => {
        AWS.remock('DynamoDB.DocumentClient', 'query', (params, callback) => {
            callback(null, {
                Items: Array(5).fill({
                    timestamp: Math.floor(Date.now() / 1000) - 60
                })
            });
        });

        const event = {
            request: {
                userAttributes: {
                    email: 'test@ocupop.com',
                    sourceIp: '127.0.0.1'
                }
            }
        };

        await expect(handler(event)).rejects.toThrow('Rate limit exceeded');
    });

    test('should reset after window expires', async () => {
        AWS.remock('DynamoDB.DocumentClient', 'query', (params, callback) => {
            callback(null, {
                Items: Array(5).fill({
                    timestamp: Math.floor(Date.now() / 1000) - (16 * 60)
                })
            });
        });

        const event = {
            request: {
                userAttributes: {
                    email: 'test@ocupop.com',
                    sourceIp: '127.0.0.1'
                }
            }
        };

        const result = await handler(event);
        expect(result).toEqual(event);
    });
});
