import { Router } from 'express';
import {
  listTags,
  getTagById,
  createTag,
  updateTag,
  deleteTag,
  getTagSuggestions,
  getPopularTags,
} from '../services/tags.service';
import {
  createTagSchema,
  updateTagSchema,
  tagIdParamSchema,
  tagSuggestionsQuerySchema,
  popularTagsQuerySchema,
} from '../validation/schemas';
import { validate } from '../validation/middleware';
import { authMiddleware, requireAuth } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);
router.use(requireAuth);

router.get('/', async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tags = await listTags(userId);
    res.json(tags);
  } catch (error) {
    next(error);
  }
});

router.get('/suggestions', validate(tagSuggestionsQuerySchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const { q, limit } = req.query;
    const tags = await getTagSuggestions(userId, q as string, Number(limit));
    res.json(tags);
  } catch (error) {
    next(error);
  }
});

router.get('/popular', validate(popularTagsQuerySchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const { limit } = req.query;
    const tags = await getPopularTags(userId, Number(limit));
    res.json(tags);
  } catch (error) {
    next(error);
  }
});

router.get('/:id', validate(tagIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tag = await getTagById(userId, req.params.id);
    if (!tag) return res.status(404).json({ error: 'Tag not found' });
    res.json(tag);
  } catch (error) {
    next(error);
  }
});

router.post('/', validate(createTagSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tag = await createTag(userId, req.body.name, req.body.color);
    res.status(201).json(tag);
  } catch (error) {
    if (error instanceof Error && error.message === 'Tag name already exists') {
      return res.status(400).json({ error: 'Tag name already exists' });
    }
    next(error);
  }
});

router.patch('/:id', validate(updateTagSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tag = await updateTag(userId, req.params.id, req.body);
    if (!tag) return res.status(404).json({ error: 'Tag not found' });
    res.json(tag);
  } catch (error) {
    if (error instanceof Error && error.message === 'Tag name already exists') {
      return res.status(400).json({ error: 'Tag name already exists' });
    }
    next(error);
  }
});

router.delete('/:id', validate(tagIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const deleted = await deleteTag(userId, req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Tag not found' });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;