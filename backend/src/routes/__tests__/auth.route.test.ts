import { describe, it, expect, vi, beforeAll, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import bcrypt from 'bcryptjs';
import authRoute from '../auth.route';
import notesRoute from '../notes.route';
import { prisma } from '../../db';
import { setupTestApp } from './setup';
import { errorHandler } from '../../middleware/error';
import { signAccessToken } from '../../config/jwt';

// The suite exercises the *real* auth middleware (no vi.mock of ../../middleware/auth),
// so raise the credential rate limit out of the way.
process.env.AUTH_RATE_LIMIT = '100';

const PASSWORD = 'correct-horse-battery';

function buildAuthApp(): express.Express {
  return setupTestApp(authRoute, '/api/auth');
}

function buildNotesApp(): express.Express {
  const app = express();
  app.use(express.json());
  app.use('/api/notes', notesRoute);
  app.use(errorHandler);
  return app;
}

describe('Auth Routes', () => {
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await bcrypt.hash(PASSWORD, 12);
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('POST /api/auth/register', () => {
    it('registers a user and returns an access token', async () => {
      (prisma.user.findUnique as any).mockResolvedValue(null);
      (prisma.user.create as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        createdAt: new Date(),
      });

      const response = await request(buildAuthApp())
        .post('/api/auth/register')
        .send({ email: 'Ada@Example.com', password: PASSWORD, name: 'Ada' });

      expect(response.status).toBe(201);
      expect(typeof response.body.accessToken).toBe('string');
      expect(response.body.user).toEqual({ id: 'user1', email: 'ada@example.com', name: 'Ada' });
      expect(response.body.user).not.toHaveProperty('passwordHash');
      expect(prisma.user.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ email: 'ada@example.com' }),
        })
      );
    });

    it('rejects a duplicate email with 409', async () => {
      (prisma.user.findUnique as any).mockResolvedValue({ id: 'user1', email: 'ada@example.com' });

      const response = await request(buildAuthApp())
        .post('/api/auth/register')
        .send({ email: 'ada@example.com', password: PASSWORD, name: 'Ada' });

      expect(response.status).toBe(409);
      expect(prisma.user.create).not.toHaveBeenCalled();
    });

    it('rejects a password shorter than 8 characters with 400', async () => {
      const response = await request(buildAuthApp())
        .post('/api/auth/register')
        .send({ email: 'ada@example.com', password: 'short', name: 'Ada' });

      expect(response.status).toBe(400);
      expect(prisma.user.findUnique).not.toHaveBeenCalled();
    });

    it('never stores the raw password', async () => {
      (prisma.user.findUnique as any).mockResolvedValue(null);
      (prisma.user.create as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        createdAt: new Date(),
      });

      await request(buildAuthApp())
        .post('/api/auth/register')
        .send({ email: 'ada@example.com', password: PASSWORD, name: 'Ada' });

      const storedHash = (prisma.user.create as any).mock.calls[0][0].data.passwordHash;
      expect(storedHash).not.toBe(PASSWORD);
      expect(await bcrypt.compare(PASSWORD, storedHash)).toBe(true);
    });
  });

  describe('POST /api/auth/login', () => {
    it('logs in with valid credentials', async () => {
      (prisma.user.findUnique as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        passwordHash,
        createdAt: new Date(),
      });

      const response = await request(buildAuthApp())
        .post('/api/auth/login')
        .send({ email: 'ada@example.com', password: PASSWORD });

      expect(response.status).toBe(200);
      expect(typeof response.body.accessToken).toBe('string');
      expect(response.body.user.id).toBe('user1');
    });

    it('rejects a wrong password with 401', async () => {
      (prisma.user.findUnique as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        passwordHash,
        createdAt: new Date(),
      });

      const response = await request(buildAuthApp())
        .post('/api/auth/login')
        .send({ email: 'ada@example.com', password: 'wrong-password' });

      expect(response.status).toBe(401);
    });

    it('rejects an unknown email with 401', async () => {
      (prisma.user.findUnique as any).mockResolvedValue(null);

      const response = await request(buildAuthApp())
        .post('/api/auth/login')
        .send({ email: 'nobody@example.com', password: PASSWORD });

      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Invalid credentials');
    });
  });

  describe('GET /api/auth/me', () => {
    it('returns the authenticated user for a valid token', async () => {
      (prisma.user.findUnique as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        passwordHash,
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      });

      const token = signAccessToken('user1');

      const response = await request(buildAuthApp())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
      expect(response.body.user).toEqual({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        createdAt: '2026-01-01T00:00:00.000Z',
      });
      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { id: 'user1' } });
    });

    it('rejects a request without a token with 401', async () => {
      const response = await request(buildAuthApp()).get('/api/auth/me');

      expect(response.status).toBe(401);
      expect(prisma.user.findUnique).not.toHaveBeenCalled();
    });

    it('rejects a malformed token with 401', async () => {
      const response = await request(buildAuthApp())
        .get('/api/auth/me')
        .set('Authorization', 'Bearer not-a-real-token');

      expect(response.status).toBe(401);
    });

    it('rejects a token signed with the wrong secret with 401', async () => {
      const foreignToken = signAccessToken('user1').split('.').slice(0, 2).join('.') + '.tampered';

      const response = await request(buildAuthApp())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${foreignToken}`);

      expect(response.status).toBe(401);
    });
  });

  describe('PATCH /api/auth/me', () => {
    it('updates the caller\'s name', async () => {
      (prisma.user.findUnique as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada',
        passwordHash,
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      });
      (prisma.user.update as any).mockResolvedValue({
        id: 'user1',
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        passwordHash,
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      });

      const response = await request(buildAuthApp())
        .patch('/api/auth/me')
        .set('Authorization', `Bearer ${signAccessToken('user1')}`)
        .send({ name: 'Ada Lovelace' });

      expect(response.status).toBe(200);
      expect(response.body.user.name).toBe('Ada Lovelace');
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user1' },
        data: { name: 'Ada Lovelace' },
      });
    });

    it('requires a token', async () => {
      const response = await request(buildAuthApp())
        .patch('/api/auth/me')
        .send({ name: 'Nobody' });

      expect(response.status).toBe(401);
    });

    it('rejects an empty name with 400', async () => {
      const response = await request(buildAuthApp())
        .patch('/api/auth/me')
        .set('Authorization', `Bearer ${signAccessToken('user1')}`)
        .send({ name: '' });

      expect(response.status).toBe(400);
    });
  });

  describe('protected resources', () => {
    it('notes route rejects a request without a token with 401', async () => {
      const response = await request(buildNotesApp()).get('/api/notes');

      expect(response.status).toBe(401);
      expect(prisma.note.findMany).not.toHaveBeenCalled();
    });

    it('notes route accepts a request with a valid token', async () => {
      (prisma.note.findMany as any).mockResolvedValue([]);
      (prisma.note.count as any).mockResolvedValue(0);

      const response = await request(buildNotesApp())
        .get('/api/notes')
        .set('Authorization', `Bearer ${signAccessToken('user1')}`);

      expect(response.status).toBe(200);
      expect(prisma.note.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ userId: 'user1' }) })
      );
    });
  });

  describe('credential rate limiting', () => {
    it('returns 429 once an IP exceeds the attempt limit', async () => {
      (prisma.user.findUnique as any).mockResolvedValue(null);
      process.env.AUTH_RATE_LIMIT = '2';

      let last: request.Response | undefined;
      for (let attempt = 0; attempt < 5; attempt += 1) {
        last = await request(buildAuthApp())
          .post('/api/auth/login')
          .send({ email: 'ada@example.com', password: 'wrong-password' });
      }

      expect(last?.status).toBe(429);
      expect(last?.body.error).toMatch(/too many attempts/i);

      process.env.AUTH_RATE_LIMIT = '100';
    });
  });
});
