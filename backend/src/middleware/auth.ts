import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../config/jwt';

export const authMiddleware = (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;

  if (header?.startsWith('Bearer ')) {
    try {
      const payload = verifyAccessToken(header.slice('Bearer '.length));
      (req as any).userId = payload.sub;
    } catch {
      // Invalid or expired token: leave userId unset.
      // requireAuth owns the 401 response so there is a single rejection path.
    }
  }

  next();
};

export const requireAuth = (req: Request, res: Response, next: NextFunction) => {
  // @ts-ignore
  if (!req.userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};
