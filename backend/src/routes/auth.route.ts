import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import { register, login, getMe, updateMe } from '../services/auth.service';
import { registerSchema, loginSchema, updateMeSchema } from '../validation/schemas';
import { validate } from '../validation/middleware';
import { authMiddleware, requireAuth } from '../middleware/auth';

const router = Router();

// Brute-force protection: 5 attempts per minute per IP on the credential routes.
// `limit` is read per request so tests can raise it via AUTH_RATE_LIMIT.
const credentialLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: () => Number(process.env.AUTH_RATE_LIMIT ?? 5),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Try again in a minute.' },
});

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password, name]
 *             properties:
 *               email: { type: string, format: email }
 *               password: { type: string, minLength: 8 }
 *               name: { type: string, minLength: 1 }
 *     responses:
 *       201:
 *         description: Registered; returns an access token and the user
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       409:
 *         description: Email already registered
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       429:
 *         description: Too many attempts
 */
router.post('/register', validate(registerSchema), credentialLimiter, async (req, res, next) => {
  try {
    const result = await register(req.body);
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Log in and receive an access token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, format: email }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: Logged in; returns an access token and the user
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       429:
 *         description: Too many attempts
 */
router.post('/login', validate(loginSchema), credentialLimiter, async (req, res, next) => {
  try {
    const result = await login(req.body);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /auth/me:
 *   get:
 *     summary: Get the authenticated user
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: The authenticated user
 *       401:
 *         description: Missing, invalid or expired token
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       404:
 *         description: User no longer exists
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.get('/me', authMiddleware, requireAuth, async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const result = await getMe(userId);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /auth/me:
 *   patch:
 *     summary: Update the authenticated user's profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name: { type: string, minLength: 1, maxLength: 100 }
 *     responses:
 *       200:
 *         description: The updated user
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 *       401:
 *         description: Missing, invalid or expired token
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/Error' }
 */
router.patch('/me', authMiddleware, requireAuth, validate(updateMeSchema), async (req, res, next) => {
  try {
    const userId = (req as any).userId;
    const result = await updateMe(userId, req.body);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

export default router;
