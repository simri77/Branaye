import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import notesRoute from '../notes.route';
import { prisma } from '../../db';
import { setupTestApp } from './setup';

describe('Notes Routes', () => {
  let app: express.Express;

  beforeEach(() => {
    app = setupTestApp(notesRoute);
    vi.clearAllMocks();
  });

  describe('GET /api/notes', () => {
    it('returns paginated notes for authenticated user', async () => {
      const mockNotes = [
        {
          id: 'note1',
          userId: 'test-user-id',
          title: 'Test Note',
          content: 'Content',
          category: 'Ideas',
          color: '#464BD4',
          isPinned: false,
          isFavorite: false,
          isArchived: false,
          createdAt: new Date(),
          updatedAt: new Date(),
          tags: [{ tag: { id: 'tag1', name: 'test' } }],
        },
      ];

      (prisma.note.findMany as any).mockResolvedValue(mockNotes);
      (prisma.note.count as any).mockResolvedValue(1);

      const response = await request(app).get('/api/notes');

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].title).toBe('Test Note');
      expect(response.body.meta.total).toBe(1);
    });

    it('filters by category', async () => {
      (prisma.note.findMany as any).mockResolvedValue([]);
      (prisma.note.count as any).mockResolvedValue(0);

      await request(app).get('/api/notes?category=Work');

      expect(prisma.note.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ category: 'Work' }),
        })
      );
    });

    it('searches with q parameter', async () => {
      (prisma.$queryRawUnsafe as any)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }]);

      await request(app).get('/api/notes?q=search+term');

      expect(prisma.$queryRawUnsafe).toHaveBeenCalled();
    });

    it('filters by tags', async () => {
      (prisma.note.findMany as any).mockResolvedValue([]);
      (prisma.note.count as any).mockResolvedValue(0);

      await request(app).get('/api/notes?tags=tag1,tag2');

      expect(prisma.note.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            tags: { some: { tag: { name: { in: ['tag1', 'tag2'] } } } },
          }),
        })
      );
    });

    it('returns 401 without auth', async () => {
      const appWithoutAuth = express();
      appWithoutAuth.use(express.json());
      appWithoutAuth.use('/api/notes', notesRoute);

      const response = await request(appWithoutAuth).get('/api/notes');
      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/notes/:id', () => {
    it('returns single note', async () => {
      const mockNote = {
        id: 'note1',
        userId: 'test-user-id',
        title: 'Test Note',
        content: 'Content',
        category: 'Ideas',
        color: '#464BD4',
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        tags: [{ tag: { id: 'tag1', name: 'test' } }],
      };

      (prisma.note.findFirst as any).mockResolvedValue(mockNote);

      const response = await request(app).get('/api/notes/note1');

      expect(response.status).toBe(200);
      expect(response.body.title).toBe('Test Note');
    });

    it('returns 404 for non-existent note', async () => {
      (prisma.note.findFirst as any).mockResolvedValue(null);

      const response = await request(app).get('/api/notes/nonexistent');

      expect(response.status).toBe(404);
    });
  });

  describe('POST /api/notes', () => {
    it('creates note with tags', async () => {
      const mockNote = {
        id: 'newnote',
        userId: 'test-user-id',
        title: 'New Note',
        content: 'Content',
        category: 'Ideas',
        color: '#464BD4',
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        tags: [{ tag: { id: 'tag1', name: 'tag1' } }],
      };

      (prisma.tag.findUnique as any).mockResolvedValue(null);
      (prisma.tag.create as any).mockResolvedValue({ id: 'tag1', name: 'tag1' });
      (prisma.note.create as any).mockResolvedValue(mockNote);

      const response = await request(app)
        .post('/api/notes')
        .send({ title: 'New Note', tags: ['tag1'] });

      expect(response.status).toBe(201);
      expect(response.body.title).toBe('New Note');
      expect(response.body.tags).toContain('tag1');
    });

    it('validates required title', async () => {
      const response = await request(app)
        .post('/api/notes')
        .send({ content: 'No title' });

      expect(response.status).toBe(400);
    });
  });

  describe('PATCH /api/notes/:id', () => {
    it('updates note', async () => {
      const mockNote = {
        id: 'note1',
        userId: 'test-user-id',
        title: 'Updated',
        content: 'Content',
        category: 'Ideas',
        color: '#464BD4',
        isPinned: true,
        isFavorite: false,
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        tags: [],
      };

      (prisma.note.findFirst as any).mockResolvedValue({ id: 'note1', userId: 'test-user-id' });
      (prisma.note.update as any).mockResolvedValue(mockNote);

      const response = await request(app)
        .patch('/api/notes/note1')
        .send({ title: 'Updated', isPinned: true });

      expect(response.status).toBe(200);
      expect(response.body.title).toBe('Updated');
      expect(response.body.isPinned).toBe(true);
    });

    it('replaces tags when provided', async () => {
      (prisma.note.findFirst as any).mockResolvedValue({ id: 'note1', userId: 'test-user-id' });
      (prisma.tag.findUnique as any).mockResolvedValue({ id: 'tag2', name: 'tag2' });
      (prisma.noteTag.deleteMany as any).mockResolvedValue({});
      (prisma.noteTag.createMany as any).mockResolvedValue({});
      (prisma.note.update as any).mockResolvedValue({
        ...mockNote,
        tags: [{ tag: { id: 'tag2', name: 'tag2' } }],
      });

      const response = await request(app)
        .patch('/api/notes/note1')
        .send({ tags: ['tag2'] });

      expect(response.status).toBe(200);
    });
  });

  describe('DELETE /api/notes/:id', () => {
    it('deletes note', async () => {
      (prisma.note.deleteMany as any).mockResolvedValue({ count: 1 });

      const response = await request(app).delete('/api/notes/note1');

      expect(response.status).toBe(204);
    });

    it('returns 404 for non-existent note', async () => {
      (prisma.note.deleteMany as any).mockResolvedValue({ count: 0 });

      const response = await request(app).delete('/api/notes/nonexistent');

      expect(response.status).toBe(404);
    });
  });
});