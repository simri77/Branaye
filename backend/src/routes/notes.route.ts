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

router.get('/', validate(listNotesQuerySchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;

    const { page, limit, category, isPinned, isFavorite, isArchived, includeArchived, q, tags, sort } = req.query;
    const result = await listNotes({
      userId,
      page: Number(page),
      limit: Number(limit),
      category: category as string,
      isPinned: isPinned !== undefined ? isPinned === 'true' : undefined,
      isFavorite: isFavorite !== undefined ? isFavorite === 'true' : undefined,
      isArchived: isArchived !== undefined ? isArchived === 'true' : undefined,
      includeArchived: includeArchived === 'true',
      q: q as string,
      tags: tags ? (tags as string).split(',') : undefined,
      sort: sort as string,
    });
    res.json(result);
  } catch (error) {
    next(error);
  }
});

router.get('/:id', validate(noteIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await getNoteById(userId, req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    res.json(note);
  } catch (error) {
    next(error);
  }
});

router.post('/', validate(createNoteSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await createNote(userId, req.body);
    res.status(201).json(note);
  } catch (error) {
    next(error);
  }
});

router.patch('/:id', validate(updateNoteSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const note = await updateNote(userId, req.params.id, req.body);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    res.json(note);
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', validate(noteIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const deleted = await deleteNote(userId, req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Note not found' });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;