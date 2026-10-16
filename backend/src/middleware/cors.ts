import { NextFunction, Request, Response } from 'express';

/**
 * Minimal CORS middleware for development.
 *
 * Why needed: a Flutter **web** build runs on http://localhost:PORT and calls
 * this API on :3000. Browsers treat that as cross-origin and block the response
 * unless the server says it is allowed. Native (Android/iOS) apps are not
 * subject to CORS at all — this exists so `flutter run -d chrome` works.
 *
 * We reflect the caller's Origin instead of hardcoding one so the port can
 * change. In production you would allow-list known origins instead.
 */
export function cors(req: Request, res: Response, next: NextFunction): void {
  res.header('Access-Control-Allow-Origin', req.headers.origin ?? '*');
  res.header('Vary', 'Origin');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header(
    'Access-Control-Allow-Methods',
    'GET, POST, PATCH, PUT, DELETE, OPTIONS'
  );

  // Preflight: the browser asks permission first with OPTIONS; answer and stop.
  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }

  next();
}
