import express from 'express';
import { vi } from 'vitest';

// Mock Prisma client
vi.mock('../../db', () => ({
  prisma: {
    note: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      deleteMany: vi.fn(),
      count: vi.fn(),
    },
    tag: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      deleteMany: vi.fn(),
    },
    noteTag: {
      deleteMany: vi.fn(),
      createMany: vi.fn(),
    },
    $queryRawUnsafe: vi.fn(),
    $transaction: vi.fn(),
  },
}));

// Mock auth middleware
vi.mock('../../middleware/auth', () => ({
  authMiddleware: (req: any, _res: any, next: any) => {
    req.userId = 'test-user-id';
    next();
  },
  requireAuth: (_req: any, _res: any, next: any) => next(),
}));

export function setupTestApp(router: express.Router): express.Express {
  const app = express();
  app.use(express.json());
  app.use('/api', router);
  return app;
}