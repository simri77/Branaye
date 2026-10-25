import { Router } from 'express';
import { authMiddleware, requireAuth } from '../middleware/auth';
import { createCategory, listCategories } from '../services/categories.service';
import { validate } from '../validation/middleware';
import { createCategorySchema } from '../validation/schemas';

const router = Router();

router.use(authMiddleware);
router.use(requireAuth);

/**
 * @swagger
 * /categories:
 *   get:
 *     summary: List the authenticated user's custom categories
 *     tags: [Categories]
 *     responses:
 *       200:
 *         description: Custom categories owned by the caller
 *   post:
 *     summary: Create a custom category for the authenticated user
 *     tags: [Categories]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, iconCodePoint]
 *             properties:
 *               name: { type: string, minLength: 1, maxLength: 50 }
 *               iconCodePoint: { type: integer, minimum: 1, maximum: 1114111 }
 *     responses:
 *       201:
 *         description: The created category
 *       409:
 *         description: The name conflicts with an existing category
 */
router.get('/', async (req, res, next) => {
  try {
    const categories = await listCategories((req as any).userId);
    res.json(categories);
  } catch (error) {
    next(error);
  }
});

router.post('/', validate(createCategorySchema), async (req, res, next) => {
  try {
    const category = await createCategory((req as any).userId, req.body);
    res.status(201).json(category);
  } catch (error) {
    next(error);
  }
});

export default router;
