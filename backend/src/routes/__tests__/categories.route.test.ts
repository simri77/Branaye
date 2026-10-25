import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import categoriesRoute from '../categories.route';
import { prisma } from '../../db';
import { setupTestApp } from './setup';

vi.mock('../../middleware/auth', () => ({
  authMiddleware: (req: any, _res: any, next: any) => {
    req.userId = 'test-user-id';
    next();
  },
  requireAuth: (_req: any, _res: any, next: any) => next(),
}));

describe('Categories Routes', () => {
  let app: express.Express;

  beforeEach(() => {
    app = setupTestApp(categoriesRoute, '/api/categories');
    vi.clearAllMocks();
  });

  it('lists only categories owned by the authenticated user', async () => {
    (prisma.category.findMany as any).mockResolvedValue([
      { id: 'category1', userId: 'test-user-id', name: 'Recipes', iconCodePoint: 0xe2c7 },
    ]);

    const response = await request(app).get('/api/categories');

    expect(response.status).toBe(200);
    expect(response.body.map((category: { name: string }) => category.name)).toEqual(['Recipes']);
    expect(prisma.category.findMany).toHaveBeenCalledWith({
      where: { userId: 'test-user-id' },
      orderBy: { name: 'asc' },
    });
  });

  it('creates a category owned by the authenticated user', async () => {
    (prisma.category.findFirst as any).mockResolvedValue(null);
    (prisma.category.create as any).mockResolvedValue({
      id: 'category1',
      userId: 'test-user-id',
      name: 'Recipes',
      iconCodePoint: 0xe2c7,
    });

    const response = await request(app)
      .post('/api/categories')
      .send({ name: ' Recipes ', iconCodePoint: 0xe2c7 });

    expect(response.status).toBe(201);
    expect(prisma.category.create).toHaveBeenCalledWith({
      data: { userId: 'test-user-id', name: 'Recipes', iconCodePoint: 0xe2c7 },
    });
  });

  it('allows Music only as a user-created custom category', async () => {
    (prisma.category.findFirst as any).mockResolvedValue(null);
    (prisma.category.create as any).mockResolvedValue({
      id: 'category1',
      userId: 'test-user-id',
      name: 'Music',
      iconCodePoint: 0xe2c7,
    });

    const response = await request(app)
      .post('/api/categories')
      .send({ name: 'Music', iconCodePoint: 0xe2c7 });

    expect(response.status).toBe(201);
    expect(response.body.name).toBe('Music');
  });

  it('rejects creation of a built-in category as a custom category', async () => {
    const response = await request(app)
      .post('/api/categories')
      .send({ name: 'Work', iconCodePoint: 0xe2c7 });

    expect(response.status).toBe(409);
    expect(prisma.category.create).not.toHaveBeenCalled();
  });
});
