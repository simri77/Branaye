import { prisma } from '../db';
import { AppError } from '../middleware/error';

export const BUILT_IN_CATEGORIES = ['Personal', 'Work', 'Study', 'Ideas'];

export async function listCategories(userId: string) {
  return prisma.category.findMany({
    where: { userId },
    orderBy: { name: 'asc' },
  });
}

export async function createCategory(
  userId: string,
  data: { name: string; iconCodePoint: number }
) {
  const normalizedName = data.name.trim();
  if (BUILT_IN_CATEGORIES.some(name => name.toLowerCase() === normalizedName.toLowerCase())) {
    throw new AppError(409, 'That category already exists');
  }

  const existing = await prisma.category.findFirst({
    where: {
      userId,
      name: { equals: normalizedName, mode: 'insensitive' },
    },
  });
  if (existing) throw new AppError(409, 'That category already exists');

  try {
    return await prisma.category.create({
      data: { userId, name: normalizedName, iconCodePoint: data.iconCodePoint },
    });
  } catch (error) {
    if ((error as { code?: string }).code === 'P2002') {
      throw new AppError(409, 'That category already exists');
    }
    throw error;
  }
}

export async function assertCategoryAvailable(userId: string, name: string) {
  if (BUILT_IN_CATEGORIES.includes(name)) return;

  const category = await prisma.category.findFirst({
    where: { userId, name },
    select: { id: true },
  });
  if (!category) {
    throw new AppError(400, 'Category is not available to this user');
  }
}
