import { Request, Response, NextFunction } from 'express';

export const authMiddleware = (req: Request, _res: Response, next: NextFunction) => {
  // TODO: Replace with JWT validation
  // For now, accept userId from header (for development/testing)
  const userId = req.headers['x-user-id'] as string;
  
  if (userId) {
    (req as any).userId = userId;
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