import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import notesRoute from '../notes.route';
import { prisma } from '../../db';
import { setupTestApp } from './setup';

vi.mock('../../middleware/auth', () => ({
  authMiddleware: (req: any, _res: any, next: any) => {
    req.userId = 'test-user-id';
    next();
  },
  requireAuth: (_req: any, _res: any, next: any) => next(),
}));

describe('Notes Routes', () => {
  let app: express.Express;

  beforeEach(() => {
    app = setupTestApp(notesRoute, '/api/notes');
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
      (prisma.$queryRaw as any)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: 0 }]);

      await request(app).get('/api/notes?q=search+term');

      expect(prisma.$queryRaw).toHaveBeenCalledTimes(2);
      expect(prisma.note.findMany).not.toHaveBeenCalled();
    });

    it('returns search hits with the same shape as the list endpoint', async () => {
      (prisma.$queryRaw as any)
        .mockResolvedValueOnce([
          {
            id: 'note1',
            userId: 'test-user-id',
            title: 'Database Notes',
            content: 'Postgres full text search',
            category: 'Study',
            color: '#464BD4',
            isPinned: false,
            isFavorite: false,
            isArchived: false,
            createdAt: new Date(),
            updatedAt: new Date(),
            deletedAt: null,
          },
        ])
        .mockResolvedValueOnce([{ count: 1 }]);
      (prisma.noteTag.findMany as any).mockResolvedValue([
        { noteId: 'note1', tag: { id: 'tag1', name: 'postgres' } },
      ]);

      const response = await request(app).get('/api/notes?q=database');

      expect(response.status).toBe(200);
      expect(response.body.data[0].title).toBe('Database Notes');
      expect(response.body.data[0].tags).toEqual(['postgres']);
      expect(response.body.meta.total).toBe(1);
    });

    it('binds user input as parameters instead of interpolating it into SQL', async () => {
      (prisma.$queryRaw as any)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: 0 }]);

      const injection = "x'); DROP TABLE notes;--";
      await request(app).get('/api/notes').query({ q: 'term', tags: injection });

      expect(prisma.$queryRawUnsafe).not.toHaveBeenCalled();

      const [searchSql] = (prisma.$queryRaw as any).mock.calls[0];
      expect(searchSql.values).toContain(injection);
      expect(searchSql.sql).not.toContain('DROP TABLE');
      expect(searchSql.sql).toContain('?');
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

    // The "rejects requests without a token" case lives in auth.route.test.ts:
    // this file stubs the auth middleware, so the real 401 path cannot be observed here.
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

      const response = await request(app).get('/api/notes/cnote0001');

      expect(response.status).toBe(200);
      expect(response.body.title).toBe('Test Note');
    });

    it('returns 404 for non-existent note', async () => {
      (prisma.note.findFirst as any).mockResolvedValue(null);

      const response = await request(app).get('/api/notes/cnotfound000');

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
        .patch('/api/notes/cnote0001')
        .send({ title: 'Updated', isPinned: true });

      expect(response.status).toBe(200);
      expect(response.body.title).toBe('Updated');
      expect(response.body.isPinned).toBe(true);
    });

    it('replaces tags when provided', async () => {
      const mockNote = {
        id: 'note1',
        userId: 'test-user-id',
        title: 'Updated',
        content: 'Content',
        category: 'Ideas',
        color: '#464BD4',
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        createdAt: new Date(),
        updatedAt: new Date(),
        tags: [],
      };

      (prisma.note.findFirst as any).mockResolvedValue({ id: 'note1', userId: 'test-user-id' });
      (prisma.tag.findUnique as any).mockResolvedValue({ id: 'tag2', name: 'tag2' });
      (prisma.noteTag.deleteMany as any).mockResolvedValue({});
      (prisma.noteTag.createMany as any).mockResolvedValue({});
      (prisma.note.update as any).mockResolvedValue({
        ...mockNote,
        tags: [{ tag: { id: 'tag2', name: 'tag2' } }],
      });

      const response = await request(app)
        .patch('/api/notes/cnote0001')
        .send({ tags: ['tag2'] });

      expect(response.status).toBe(200);
    });
  });

  describe('DELETE /api/notes/:id', () => {
    it('deletes note', async () => {
      (prisma.note.deleteMany as any).mockResolvedValue({ count: 1 });

      const response = await request(app).delete('/api/notes/cnote0001');

      expect(response.status).toBe(204);
    });

    it('returns 404 for non-existent note', async () => {
      (prisma.note.deleteMany as any).mockResolvedValue({ count: 0 });

      const response = await request(app).delete('/api/notes/cnotfound000');

      expect(response.status).toBe(404);
    });
  });

  // Cross-user denial is implemented by *scoping every query to req.userId*.
  // With a mocked Prisma there is no second user to log in as, so instead we
  // assert the scope: if `userId` is always in the WHERE clause, another user's
  // note id can never match, and the row behaves as if it does not exist.
  describe('ownership scoping', () => {
    it("lists only the caller's notes", async () => {
      (prisma.note.findMany as any).mockResolvedValue([]);
      (prisma.note.count as any).mockResolvedValue(0);

      await request(app).get('/api/notes');

      expect(prisma.note.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ userId: 'test-user-id' }),
        })
      );
      expect(prisma.note.count).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ userId: 'test-user-id' }),
        })
      );
    });

    it('scopes a single-note read to the caller and 404s when it is not theirs', async () => {
      (prisma.note.findFirst as any).mockResolvedValue(null);

      const response = await request(app).get('/api/notes/cnote0001');

      expect(prisma.note.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ id: 'cnote0001', userId: 'test-user-id' }),
        })
      );
      expect(response.status).toBe(404);
    });

    it("cannot update a note that is not the caller's", async () => {
      (prisma.note.findFirst as any).mockResolvedValue(null);

      const response = await request(app).patch('/api/notes/cnote0001').send({ title: 'Hijacked' });

      expect(prisma.note.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ id: 'cnote0001', userId: 'test-user-id' }),
        })
      );
      expect(prisma.note.update).not.toHaveBeenCalled();
      expect(response.status).toBe(404);
    });

    it("cannot delete a note that is not the caller's", async () => {
      (prisma.note.deleteMany as any).mockResolvedValue({ count: 0 });

      const response = await request(app).delete('/api/notes/cnote0001');

      expect(prisma.note.deleteMany).toHaveBeenCalledWith({
        where: { id: 'cnote0001', userId: 'test-user-id' },
      });
      expect(response.status).toBe(404);
    });
  });
});