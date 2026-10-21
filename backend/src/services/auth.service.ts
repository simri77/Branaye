import bcrypt from 'bcryptjs';
import { prisma } from '../db';
import { AppError } from '../middleware/error';
import { signAccessToken } from '../config/jwt';

const BCRYPT_COST = 12;

export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

interface UserRecord {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

function toAuthUser(user: UserRecord): AuthUser {
  return { id: user.id, email: user.email, name: user.name };
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

  return { accessToken: signAccessToken(user.id), user: toAuthUser(user) };
}

export async function login(input: { email: string; password: string }) {
  const email = input.email.trim().toLowerCase();

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    throw new AppError(401, 'Invalid credentials');
  }

  const passwordMatches = await bcrypt.compare(input.password, user.passwordHash);
  if (!passwordMatches) {
    throw new AppError(401, 'Invalid credentials');
  }

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
