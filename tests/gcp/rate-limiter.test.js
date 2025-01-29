const { Firestore } = require('@google-cloud/firestore');
const { checkRateLimit } = require('../../terraform/gcp/functions/rate-limiter');

jest.mock('@google-cloud/firestore');

describe('GCP Rate Limiter Tests', () => {
    let mockFirestore;
    let mockCollection;
    let mockDoc;
    let mockWhere;
    let mockGet;
    let mockAdd;
    let mockSet;

    beforeEach(() => {
        mockGet = jest.fn();
        mockAdd = jest.fn().mockResolvedValue({});
        mockSet = jest.fn().mockResolvedValue({});
        mockDoc = jest.fn().mockReturnValue({ get: mockGet, set: mockSet });
        mockWhere = jest.fn().mockReturnThis();
        
        mockCollection = jest.fn().mockReturnValue({
            where: mockWhere,
            doc: mockDoc,
            add: mockAdd,
            get: mockGet
        });
        
        mockFirestore = {
            collection: mockCollection
        };

        Firestore.mockImplementation(() => mockFirestore);
        global.firestore = mockFirestore;
    });

    test('should allow request within limits', async () => {
        const req = {
            body: {
                email: 'test@ocupop.com',
                ip: '127.0.0.1'
            }
        };

        // Mock attempts query
        mockGet.mockResolvedValueOnce({ size: 2, docs: [] });
        // Mock lockout check
        mockGet.mockResolvedValueOnce({ exists: false });
        // Mock IP attempts query
        mockGet.mockResolvedValueOnce({ size: 1, docs: [] });
        // Mock IP lockout check
        mockGet.mockResolvedValueOnce({ exists: false });

        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        await checkRateLimit(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({ allowed: true });
    });

    test('should block request when rate limit exceeded', async () => {
        const req = {
            body: {
                email: 'test@ocupop.com',
                ip: '127.0.0.1'
            }
        };

        // Mock attempts query with exceeded limit
        mockGet.mockResolvedValueOnce({ size: 6, docs: [] });
        // Mock lockout check
        mockGet.mockResolvedValueOnce({ exists: false });
        // Mock IP attempts query
        mockGet.mockResolvedValueOnce({ size: 1, docs: [] });
        // Mock IP lockout check
        mockGet.mockResolvedValueOnce({ exists: false });

        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        await checkRateLimit(req, res);

        expect(res.status).toHaveBeenCalledWith(429);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({
                error: expect.any(String),
                retryAfter: expect.any(Number)
            })
        );
    });

    test('should respect existing lockout', async () => {
        const req = {
            body: {
                email: 'test@ocupop.com',
                ip: '127.0.0.1'
            }
        };

        const futureTimestamp = Math.floor(Date.now() / 1000) + 3600;

        // Mock attempts query
        mockGet.mockResolvedValueOnce({ size: 1, docs: [] });
        // Mock lockout check with active lockout
        mockGet.mockResolvedValueOnce({
            exists: true,
            data: () => ({
                lockoutUntil: futureTimestamp
            })
        });

        const res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        await checkRateLimit(req, res);

        expect(res.status).toHaveBeenCalledWith(429);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({
                error: 'Too many attempts. Please try again later.'
            })
        );
    });
});
