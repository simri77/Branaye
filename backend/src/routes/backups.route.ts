import { Router } from "express";
import { authMiddleware, requireAuth } from "../middleware/auth";
import { replaceUserBackup } from "../services/backups.service";
import { validate } from "../validation/middleware";
import { restoreBackupSchema } from "../validation/schemas";

const router = Router();

router.use(authMiddleware);
router.use(requireAuth);

router.post(
  "/restore",
  validate(restoreBackupSchema),
  async (req, res, next) => {
    try {
      const result = await replaceUserBackup((req as any).userId, req.body);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },
);

export default router;
