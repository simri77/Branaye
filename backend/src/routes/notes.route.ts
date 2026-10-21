import { Router } from 'express';
import { listNotes, getNoteById, createNote, updateNote, deleteNote } from '../services/notes.service';
import {
  listNotesQuerySchema,
  createNoteSchema,
  updateNoteSchema,
  noteIdParamSchema,
} from '../validation/schemas';
import { validate } from '../validation/middleware';
import { authMiddleware, requireAuth } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);
router.use(requireAuth);

/**
 * @swagger
 * /notes:
 *   get:
 *     summary: List the authenticated user's notes
 *     tags: [Notes]
 *     parameters:
 *       - { in: query, name: page, schema: { type: integer, minimum: 1, default: 1 } }
 *       - { in: query, name: limit, schema: { type: integer, minimum: 1, maximum: 100, default: 20 } }
 *       - { in: query, name: category, schema: { type: string, enum: [Personal, Work, Study, Ideas] } }
 *       - { in: query, name: isPinned, schema: { type: boolean } }
 *       - { in: query, name: isFavorite, schema: { type: boolean } }
 *       - { in: query, name: isArchived, schema: { type: boolean } }
 *       - { in: query, name: includeArchived, schema: { type: boolean } }
 *       - { in: query, name: q, description: Full-text search term, schema: { type: string } }
 *       - { in: query, name: tags, description: Comma-separated tag names, schema: { type: string } }
 *       - { in: query, name: sort, schema: { type: string, enum: [createdAt:desc, createdAt:asc, updatedAt:desc, updatedAt:asc, title:asc, title:desc], default: createdAt:desc } }
 *     responses:
 *       200:
 *         description: A page of notes
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/PaginatedNotes' }
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       401:
 *         description: Missing or invalid token
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.get('/', validate(listNotesQuerySchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;

    const { page, limit, category, isPinned, isFavorite, isArchived, includeArchived, q, tags, sort, searchIn } = req.query;
    // `validate()` checks the query but does not write defaults back, so apply the
    // documented defaults here before they reach the service.
    const result = await listNotes({
      userId,
      page: Number(page ?? 1),
      limit: Number(limit ?? 20),
      category: category as string,
      isPinned: isPinned !== undefined ? isPinned === 'true' : undefined,
      isFavorite: isFavorite !== undefined ? isFavorite === 'true' : undefined,
      isArchived: isArchived !== undefined ? isArchived === 'true' : undefined,
      includeArchived: includeArchived === 'true',
      q: q as string,
      searchIn: searchIn as 'all' | 'title' | 'content' | 'tags' | undefined,
      tags: tags ? (tags as string).split(',') : undefined,
      sort: (sort as string) ?? 'createdAt:desc',
    });
    res.json(result);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /notes/{id}:
 *   get:
 *     summary: Get one of the authenticated user's notes
 *     tags: [Notes]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     responses:
 *       200:
 *         description: The note
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Note' }
 *       404:
 *         description: Note not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.get('/:id', validate(noteIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await getNoteById(userId, req.params.id as string);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    res.json(note);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /notes:
 *   post:
 *     summary: Create a note owned by the authenticated user
 *     tags: [Notes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title]
 *             properties:
 *               title: { type: string, minLength: 1, maxLength: 200 }
 *               content: { type: string, maxLength: 10000 }
 *               category: { type: string, enum: [Personal, Work, Study, Ideas] }
 *               color: { type: string, pattern: '^#[0-9A-Fa-f]{6}$' }
 *               isPinned: { type: boolean }
 *               isFavorite: { type: boolean }
 *               tags:
 *                 type: array
 *                 maxItems: 20
 *                 items: { type: string, minLength: 1, maxLength: 50 }
 *     responses:
 *       201:
 *         description: The created note
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Note' }
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.post('/', validate(createNoteSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await createNote(userId, req.body);
    res.status(201).json(note);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /notes/{id}:
 *   patch:
 *     summary: Update a note; omitted fields are left unchanged
 *     tags: [Notes]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title: { type: string, minLength: 1, maxLength: 200 }
 *               content: { type: string, maxLength: 10000 }
 *               category: { type: string, enum: [Personal, Work, Study, Ideas] }
 *               color: { type: string, pattern: '^#[0-9A-Fa-f]{6}$' }
 *               isPinned: { type: boolean }
 *               isFavorite: { type: boolean }
 *               isArchived: { type: boolean }
 *               tags:
 *                 type: array
 *                 maxItems: 20
 *                 items: { type: string, minLength: 1, maxLength: 50 }
 *     responses:
 *       200:
 *         description: The updated note
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Note' }
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       404:
 *         description: Note not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.patch('/:id', validate(updateNoteSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await updateNote(userId, req.params.id as string, req.body);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    res.json(note);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /notes/{id}:
 *   delete:
 *     summary: Permanently delete one of the authenticated user's notes
 *     tags: [Notes]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     responses:
 *       204:
 *         description: Deleted
 *       404:
 *         description: Note not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.delete('/:id', validate(noteIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const deleted = await deleteNote(userId, req.params.id as string);
    if (!deleted) return res.status(404).json({ error: 'Note not found' });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;