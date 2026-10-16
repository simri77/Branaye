import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public details?: any
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  console.error('Error:', err);

  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'Validation failed',
      details: err.flatten().fieldErrors,
    });
  }

  // Prisma errors are detected by their `code` rather than `instanceof`:
  // the error class identity is not stable across the generated client, the
  // adapter package, and mocked modules in tests.
  const prismaCode = (err as { code?: string }).code;
  if (prismaCode === 'P2002') {
    return res.status(400).json({
      error: 'Unique constraint violation',
      details: (err as { meta?: unknown }).meta,
    });
  }
  if (prismaCode === 'P2025') {
    return res.status(404).json({ error: 'Record not found' });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
      details: err.details,
    });
  }

  return res.status(500).json({ error: 'Internal server error' });
};

export const notFoundHandler = (_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
};