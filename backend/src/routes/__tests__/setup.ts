import express from 'express';
import { vi } from 'vitest';
import { errorHandler } from '../../middleware/error';
import { cors } from '../../middleware/cors';

// Mock Prisma client. This file runs as a vitest `setupFiles` entry, so the mock
// applies to every suite. Suites that need to exercise the real auth middleware
// simply do not stub `../../middleware/auth` themselves.
vi.mock('../../db', async () => ({
  // Services use `Prisma.sql` / `Prisma.join` at runtime to build bound
  // parameters, so the mock must expose the real namespace too.
  Prisma: (await import('../../generated/prisma/client')).Prisma,
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
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    noteTag: {
      findMany: vi.fn(),
      deleteMany: vi.fn(),
      createMany: vi.fn(),
    },
    $queryRaw: vi.fn(),
    $queryRawUnsafe: vi.fn(),
    $transaction: vi.fn(),
  },
}));

/**
 * Mounts a router on a throwaway Express app.
 *
 * `basePath` must match how `app.ts` mounts the router (`/api/notes`, `/api/tags`),
 * otherwise the test hits the wrong route and sees 404/400 instead of the handler.
 */
export function setupTestApp(router: express.Router, basePath = '/api'): express.Express {
  const app = express();
  app.use(cors);
  app.use(express.json());
  app.use(basePath, router);
  app.use(errorHandler);
  return app;
}
