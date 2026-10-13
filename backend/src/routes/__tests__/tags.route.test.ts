import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import tagsRoute from '../tags.route';
import { prisma } from '../../db';
import { setupTestApp } from './setup';

describe('Tags Routes', () => {
  let app: express.Express;

  beforeEach(() => {
    app = setupTestApp(tagsRoute);
    vi.clearAllMocks();
  });

  describe('GET /api/tags', () => {
    it('returns user tags with note counts', async () => {
      const mockTags = [
        { id: 'tag1', name: 'work', color: '#FF0000', _count: { notes: 5 }, createdAt: new Date(), updatedAt: new Date() },
        { id: 'tag2', name: 'personal', color: null, _count: { notes: 3 }, createdAt: new Date(), updatedAt: new Date() },
      ];

      (prisma.tag.findMany as any).mockResolvedValue(mockTags);

      const response = await request(app).get('/api/tags');

      expect(response.status).toBe(200);
      expect(response.body).toHaveLength(2);
      expect(response.body[0].noteCount).toBe(5);
      expect(response.body[1].noteCount).toBe(3);
    });

    it('returns empty array when no tags', async () => {
      (prisma.tag.findMany as any).mockResolvedValue([]);

      const response = await request(app).get('/api/tags');

      expect(response.status).toBe(200);
      expect(response.body).toEqual([]);
    });
  });

  describe('GET /api/tags/suggestions', () => {
    it('returns tag suggestions for prefix', async () => {
      const mockTags = [
        { id: 'tag1', name: 'work', color: '#FF0000', _count: { notes: 5 }, createdAt: new Date(), updatedAt: new Date() },
      ];

      (prisma.tag.findMany as any).mockResolvedValue(mockTags);

      const response = await request(app).get('/api/tags/suggestions?q=wo&limit=5');

      expect(response.status).toBe(200);
      expect(response.body).toHaveLength(1);
      expect(response.body[0].name).toBe('work');
      expect(prisma.tag.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            name: { startsWith: 'wo', mode: 'insensitive' },
          }),
        })
      );
    });

    it('requires q parameter', async () => {
      const response = await request(app).get('/api/tags/suggestions');

      expect(response.status).toBe(400);
    });
  });

  describe('GET /api/tags/popular', () => {
    it('returns popular tags by usage count', async () => {
      const mockTags = [
        { id: 'tag1', name: 'work', color: '#FF0000', _count: { notes: 10 }, createdAt: new Date(), updatedAt: new Date() },
        { id: 'tag2', name: 'study', color: '#00FF00', _count: { notes: 8 }, createdAt: new Date(), updatedAt: new Date() },
      ];

      (prisma.tag.findMany as any).mockResolvedValue(mockTags);

      const response = await request(app).get('/api/tags/popular?limit=10');

      expect(response.status).toBe(200);
      expect(response.body).toHaveLength(2);
      expect(prisma.tag.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: { notes: { _count: 'desc' } },
        })
      );
    });
  });

  describe('POST /api/tags', () => {
    it('creates new tag', async () => {
      const mockTag = { id: 'newtag', name: 'newtag', color: '#464BD4', _count: { notes: 0 }, createdAt: new Date(), updatedAt: new Date() };

      (prisma.tag.create as any).mockResolvedValue(mockTag);

      const response = await request(app)
        .post('/api/tags')
        .send({ name: 'newtag', color: '#464BD4' });

      expect(response.status).toBe(201);
      expect(response.body.name).toBe('newtag');
    });

    it('validates name required', async () => {
      const response = await request(app)
        .post('/api/tags')
        .send({ color: '#464BD4' });

      expect(response.status).toBe(400);
    });

    it('returns 400 for duplicate tag name', async () => {
      const error = new Error('Tag name already exists');
      (prisma.tag.create as any).mockRejectedValue(error);

      const response = await request(app)
        .post('/api/tags')
        .send({ name: 'existing' });

      expect(response.status).toBe(400);
    });
  });

  describe('PATCH /api/tags/:id', () => {
    it('updates tag', async () => {
      const mockTag = { id: 'tag1', name: 'updated', color: '#00FF00', _count: { notes: 5 }, createdAt: new Date(), updatedAt: new Date() };

      (prisma.tag.findFirst as any).mockResolvedValue({ id: 'tag1', name: 'old', userId: 'test-user-id' });
      (prisma.tag.findUnique as any).mockResolvedValue(null);
      (prisma.tag.update as any).mockResolvedValue(mockTag);

      const response = await request(app)
        .patch('/api/tags/tag1')
        .send({ name: 'updated', color: '#00FF00' });

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('updated');
    });

    it('returns 404 for non-existent tag', async () => {
      (prisma.tag.findFirst as any).mockResolvedValue(null);

      const response = await request(app)
        .patch('/api/tags/nonexistent')
        .send({ name: 'updated' });

      expect(response.status).toBe(404);
    });

    it('returns 400 for duplicate name', async () => {
      (prisma.tag.findFirst as any).mockResolvedValue({ id: 'tag1', name: 'old', userId: 'test-user-id' });
      (prisma.tag.findUnique as any).mockResolvedValue({ id: 'other', name: 'updated' });

      const response = await request(app)
        .patch('/api/tags/tag1')
        .send({ name: 'updated' });

      expect(response.status).toBe(400);
    });
  });

  describe('DELETE /api/tags/:id', () => {
    it('deletes tag', async () => {
      (prisma.tag.deleteMany as any).mockResolvedValue({ count: 1 });

      const response = await request(app).delete('/api/tags/tag1');

      expect(response.status).toBe(204);
    });

    it('returns 404 for non-existent tag', async () => {
      (prisma.tag.deleteMany as any).mockResolvedValue({ count: 0 });

      const response = await request(app).delete('/api/tags/nonexistent');

      expect(response.status).toBe(404);
    });
  });
});