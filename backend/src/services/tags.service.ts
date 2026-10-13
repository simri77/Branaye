import { prisma } from '../db';

export interface TagWithCount {
  id: string;
  name: string;
  color: string | null;
  noteCount: number;
  createdAt: Date;
  updatedAt: Date;
}

export async function listTags(userId: string): Promise<TagWithCount[]> {
  const tags = await prisma.tag.findMany({
    where: { userId },
    orderBy: { name: 'asc' },
    include: {
      _count: { select: { notes: true } },
    },
  });

  return tags.map(tag => ({
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  }));
}

export async function getTagById(userId: string, id: string): Promise<TagWithCount | null> {
  const tag = await prisma.tag.findFirst({
    where: { id, userId },
    include: { _count: { select: { notes: true } } },
  });

  if (!tag) return null;

  return {
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  };
}

export async function createTag(userId: string, name: string, color?: string): Promise<TagWithCount> {
  const tag = await prisma.tag.create({
    data: { userId, name, color },
    include: { _count: { select: { notes: true } } },
  });

  return {
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  };
}

export async function updateTag(
  userId: string,
  id: string,
  data: { name?: string; color?: string }
): Promise<TagWithCount | null> {
  const existing = await prisma.tag.findFirst({ where: { id, userId } });
  if (!existing) return null;

  // Check for name conflict if renaming
  if (data.name && data.name !== existing.name) {
    const conflict = await prisma.tag.findUnique({
      where: { userId_name: { userId, name: data.name } },
    });
    if (conflict) {
      throw new Error('Tag name already exists');
    }
  }

  const tag = await prisma.tag.update({
    where: { id },
    data: { name: data.name, color: data.color },
    include: { _count: { select: { notes: true } } },
  });

  return {
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  };
}

export async function deleteTag(userId: string, id: string): Promise<boolean> {
  const result = await prisma.tag.deleteMany({ where: { id, userId } });
  return result.count > 0;
}

export async function getTagSuggestions(userId: string, prefix: string, limit: number = 10): Promise<TagWithCount[]> {
  const tags = await prisma.tag.findMany({
    where: {
      userId,
      name: { startsWith: prefix, mode: 'insensitive' },
    },
    orderBy: { name: 'asc' },
    take: limit,
    include: { _count: { select: { notes: true } } },
  });

  return tags.map(tag => ({
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  }));
}

export async function getPopularTags(userId: string, limit: number = 10): Promise<TagWithCount[]> {
  const tags = await prisma.tag.findMany({
    where: { userId },
    orderBy: { notes: { _count: 'desc' } },
    take: limit,
    include: { _count: { select: { notes: true } } },
  });

  return tags.map(tag => ({
    id: tag.id,
    name: tag.name,
    color: tag.color,
    noteCount: tag._count.notes,
    createdAt: tag.createdAt,
    updatedAt: tag.updatedAt,
  }));
}