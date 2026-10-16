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

/**
 * @swagger
 * /tags:
 *   get:
 *     summary: List the authenticated user's tags
 *     tags: [Tags]
 *     responses:
 *       200:
 *         description: The user's tags
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Tag' }
 *       401:
 *         description: Missing or invalid token
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.get('/', async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tags = await listTags(userId);
    res.json(tags);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /tags/suggestions:
 *   get:
 *     summary: Suggest tags whose name matches a prefix
 *     tags: [Tags]
 *     parameters:
 *       - { in: query, name: q, required: true, schema: { type: string } }
 *       - { in: query, name: limit, schema: { type: integer, minimum: 1, maximum: 20, default: 10 } }
 *     responses:
 *       200:
 *         description: Matching tags
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Tag' }
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
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

/**
 * @swagger
 * /tags/popular:
 *   get:
 *     summary: List the user's most-used tags
 *     tags: [Tags]
 *     parameters:
 *       - { in: query, name: limit, schema: { type: integer, minimum: 1, maximum: 50, default: 10 } }
 *     responses:
 *       200:
 *         description: Tags ordered by note count
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { $ref: '#/components/schemas/Tag' }
 */
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

/**
 * @swagger
 * /tags/{id}:
 *   get:
 *     summary: Get one of the authenticated user's tags
 *     tags: [Tags]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     responses:
 *       200:
 *         description: The tag
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Tag' }
 *       404:
 *         description: Tag not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.get('/:id', validate(tagIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tag = await getTagById(userId, req.params.id as string);
    if (!tag) return res.status(404).json({ error: 'Tag not found' });
    res.json(tag);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /tags:
 *   post:
 *     summary: Create a tag for the authenticated user
 *     tags: [Tags]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name: { type: string, minLength: 1, maxLength: 50 }
 *               color: { type: string, pattern: '^#[0-9A-Fa-f]{6}$' }
 *     responses:
 *       201:
 *         description: The created tag
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Tag' }
 *       400:
 *         description: Validation error, or the name already exists
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
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

/**
 * @swagger
 * /tags/{id}:
 *   patch:
 *     summary: Update a tag; omitted fields are left unchanged
 *     tags: [Tags]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string, minLength: 1, maxLength: 50 }
 *               color: { type: string, pattern: '^#[0-9A-Fa-f]{6}$' }
 *     responses:
 *       200:
 *         description: The updated tag
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Tag' }
 *       400:
 *         description: Validation error, or the name already exists
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       404:
 *         description: Tag not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.patch('/:id', validate(updateTagSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const tag = await updateTag(userId, req.params.id as string, req.body);
    if (!tag) return res.status(404).json({ error: 'Tag not found' });
    res.json(tag);
  } catch (error) {
    if (error instanceof Error && error.message === 'Tag name already exists') {
      return res.status(400).json({ error: 'Tag name already exists' });
    }
    next(error);
  }
});

/**
 * @swagger
 * /tags/{id}:
 *   delete:
 *     summary: Delete one of the authenticated user's tags
 *     tags: [Tags]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string, format: cuid } }
 *     responses:
 *       204:
 *         description: Deleted
 *       404:
 *         description: Tag not found (or not owned by the caller)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.delete('/:id', validate(tagIdParamSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const deleted = await deleteTag(userId, req.params.id as string);
    if (!deleted) return res.status(404).json({ error: 'Tag not found' });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;