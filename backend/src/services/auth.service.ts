import bcrypt from 'bcryptjs';
import { createHash, randomBytes } from 'node:crypto';
import { prisma } from '../db';
import { AppError } from '../middleware/error';
import { signAccessToken } from '../config/jwt';
import { OAuth2Client } from 'google-auth-library';

const BCRYPT_COST = 12;
const VERIFICATION_TTL_MS = 24 * 60 * 60 * 1000;
const googleClient = new OAuth2Client();

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  emailVerified?: boolean;
}

interface UserRecord {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
  emailVerified?: Date | null;
}

function toAuthUser(user: UserRecord): AuthUser {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    emailVerified: Boolean(user.emailVerified),
  };
}

export async function register(input: { email: string; password: string; name: string }) {
  const email = input.email.trim().toLowerCase();

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new AppError(409, 'Email already registered');
  }

  const passwordHash = await bcrypt.hash(input.password, BCRYPT_COST);

  let user;
  try {
    user = await prisma.user.create({
      data: { email, name: input.name.trim(), passwordHash },
    });
  } catch (error) {
    // Two concurrent registrations can both pass the check above; the unique
    // constraint on email is what actually guarantees it. Map that race to 409.
    if (isUniqueViolation(error)) {
      throw new AppError(409, 'Email already registered');
    }
    throw error;
  }

  await sendVerificationEmail(user.id, user.email, user.name);
  return {
    message: 'Account created. Check your email for a verification link before signing in.',
    email: user.email,
  };
}

export async function login(input: { email: string; password: string }) {
  const email = input.email.trim().toLowerCase();

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    throw new AppError(401, 'Invalid credentials');
  }

  if (!user.passwordHash) {
    throw new AppError(401, 'This account uses Google sign-in');
  }

  const passwordMatches = await bcrypt.compare(input.password, user.passwordHash);
  if (!passwordMatches) {
    throw new AppError(401, 'Invalid credentials');
  }

  if (!user.emailVerified) {
    throw new AppError(403, 'Verify your email before signing in', {
      code: 'EMAIL_NOT_VERIFIED',
    });
  }

  return { accessToken: signAccessToken(user.id), user: toAuthUser(user) };
}

export async function verifyEmail(token: string) {
  const tokenHash = hashToken(token);
  const verification = await prisma.emailVerificationToken.findUnique({
    where: { tokenHash },
    include: { user: true },
  });
  if (
    !verification ||
    verification.usedAt ||
    verification.expiresAt.getTime() <= Date.now()
  ) {
    throw new AppError(400, 'Verification link is invalid or expired');
  }

  const used = await prisma.emailVerificationToken.updateMany({
    where: {
      id: verification.id,
      usedAt: null,
      expiresAt: { gt: new Date() },
    },
    data: { usedAt: new Date() },
  });
  if (used.count !== 1) {
    throw new AppError(400, 'Verification link is invalid or expired');
  }

  await prisma.user.update({
    where: { id: verification.userId },
    data: { emailVerified: new Date() },
  });
  return { message: 'Email verified. You can now sign in.' };
}

export async function resendVerificationEmail(emailInput: string) {
  const email = emailInput.trim().toLowerCase();
  const user = await prisma.user.findUnique({ where: { email } });
  if (user && !user.emailVerified && user.passwordHash) {
    try {
      await sendVerificationEmail(user.id, user.email, user.name);
    } catch (error) {
      if (!(error instanceof AppError) || error.statusCode !== 503) {
        throw error;
      }
      console.error('Verification resend could not be delivered.');
    }
  }
  return {
    message: 'If that address needs verification, a new link will be sent.',
  };
}

export async function loginWithGoogle(idToken: string) {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  if (!clientId) {
    throw new AppError(503, 'Google sign-in is not configured');
  }

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: clientId,
    });
    payload = ticket.getPayload();
  } catch {
    throw new AppError(401, 'Google credential is invalid or expired');
  }

  if (!payload?.sub || !payload.email || payload.email_verified !== true) {
    throw new AppError(401, 'Google account must have a verified email');
  }

  const existingBySubject = await prisma.user.findUnique({
    where: { googleSubject: payload.sub },
  });
  if (existingBySubject) return createAuthSession(existingBySubject);

  const email = payload.email.toLowerCase();
  const existingByEmail = await prisma.user.findUnique({ where: { email } });
  if (existingByEmail && !existingByEmail.emailVerified) {
    throw new AppError(403, 'Verify your email before connecting Google', {
      code: 'EMAIL_NOT_VERIFIED',
    });
  }

  if (existingByEmail) {
    const linked = await prisma.user.update({
      where: { id: existingByEmail.id },
      data: { googleSubject: payload.sub },
    });
    return createAuthSession(linked);
  }

  try {
    const user = await prisma.user.create({
      data: {
        email,
        name: payload.name?.trim() || email,
        googleSubject: payload.sub,
        emailVerified: new Date(),
      },
    });
    return createAuthSession(user);
  } catch (error) {
    if (isUniqueViolation(error)) {
      const racedUser = await prisma.user.findUnique({
        where: { googleSubject: payload.sub },
      });
      if (racedUser) return createAuthSession(racedUser);
    }
    throw error;
  }
}

async function sendVerificationEmail(userId: string, email: string, name: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const from = process.env.RESEND_FROM_EMAIL;
  const publicApiUrl = process.env.PUBLIC_API_URL?.replace(/\/+$/, '');
  if (!apiKey || !from || !publicApiUrl) {
    throw new AppError(
      503,
      'Registration was saved, but email verification is not configured. Contact support or try again later.'
    );
  }

  const token = randomBytes(32).toString('base64url');
  const tokenHash = hashToken(token);
  const expiresAt = new Date(Date.now() + VERIFICATION_TTL_MS);
  await prisma.emailVerificationToken.deleteMany({
    where: { userId, usedAt: null },
  });
  await prisma.emailVerificationToken.create({
    data: { userId, tokenHash, expiresAt },
  });

  const verificationUrl = `${publicApiUrl}/api/auth/verify-email?token=${encodeURIComponent(token)}`;
  let response: Response;
  try {
    response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: [email],
        subject: 'Verify your Branaye email',
        text: `Hello ${name},\n\nVerify your Branaye account using this link (valid for 24 hours):\n${verificationUrl}\n\nIf you did not create this account, ignore this email.`,
      }),
    });
  } catch (error) {
    console.error('Resend email request failed:', error);
    throw new AppError(
      503,
      'Registration was saved, but we could not send the verification email. Request a new verification link later.'
    );
  }
  if (!response.ok) {
    const detail = await response.text();
    console.error('Resend email delivery failed:', response.status, detail);
    throw new AppError(
      503,
      'Registration was saved, but we could not send the verification email. Request a new verification link later.'
    );
  }
}

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

function createAuthSession(user: UserRecord) {
  return { accessToken: signAccessToken(user.id), user: toAuthUser(user) };
}

export async function getMe(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }

  return { user: { ...toAuthUser(user), createdAt: user.createdAt } };
}

export async function updateMe(userId: string, input: { name: string }) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }

  const updated = await prisma.user.update({
    where: { id: userId },
    data: { name: input.name.trim() },
  });

  return { user: { ...toAuthUser(updated), createdAt: updated.createdAt } };
}

export async function changePassword(userId: string, input: { currentPassword: string; newPassword: string }) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }
  if (!user.passwordHash) {
    throw new AppError(400, 'This Google account does not have a password set');
  }
  const matches = await bcrypt.compare(input.currentPassword, user.passwordHash);
  if (!matches) {
    throw new AppError(400, 'Current password is incorrect');
  }
  const newHash = await bcrypt.hash(input.newPassword, BCRYPT_COST);
  await prisma.user.update({ where: { id: userId }, data: { passwordHash: newHash } });
  return { message: 'Password changed successfully' };
}

export async function updateFcmToken(userId: string, token: string) {
  await prisma.user.update({ where: { id: userId }, data: { fcmToken: token } });
  return { message: 'FCM token updated' };
}

function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { code?: string }).code === 'P2002';
}
