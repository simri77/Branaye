import 'dotenv/config';
import jwt from 'jsonwebtoken';

const ALGORITHM = 'HS256';
const ACCESS_TOKEN_TTL = '15m';

export interface AccessTokenPayload {
  sub: string;
}

function jwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (secret) return secret;
  if (process.env.NODE_ENV === 'test') return 'branaye-test-secret-only';

  throw new Error('JWT_SECRET is not set — add it to backend/.env');
}

export function signAccessToken(userId: string): string {
  return jwt.sign({ sub: userId }, jwtSecret(), {
    algorithm: ALGORITHM,
    expiresIn: ACCESS_TOKEN_TTL,
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, jwtSecret(), { algorithms: [ALGORITHM] }) as AccessTokenPayload;
}
