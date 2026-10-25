import { prisma } from "../db";
import { AppError } from "../middleware/error";
import { BUILT_IN_CATEGORIES } from "./categories.service";

export interface BackupImport {
  format: "branaye-backup";
  version: 1;
  createdAt: string;
  account: { id: string; email: string };
  notes: Array<{
    title: string;
    content: string;
    category: string;
    color: string;
    createdAt: string;
    isPinned: boolean;
    isFavorite: boolean;
    isArchived: boolean;
    tags: string[];
  }>;
  categories: Array<{ name: string; iconCodePoint: number }>;
  tags: Array<{ name: string; color: string | null }>;
}

export async function replaceUserBackup(userId: string, backup: BackupImport) {
  if (backup.account.id !== userId) {
    throw new AppError(
      403,
      "This backup belongs to a different Branaye account",
    );
  }

  const builtInNames = new Set(
    BUILT_IN_CATEGORIES.map((name) => name.toLowerCase()),
  );
  const customCategories = backup.categories.filter(
    (category) => !builtInNames.has(category.name.toLowerCase()),
  );
  const availableCategories = new Set([
    ...BUILT_IN_CATEGORIES,
    ...customCategories.map((category) => category.name),
  ]);
  for (const note of backup.notes) {
    if (!availableCategories.has(note.category)) {
      throw new AppError(
        400,
        `Backup note uses an unavailable category: ${note.category}`,
      );
    }
  }

  const tagNames = new Set(backup.tags.map((tag) => tag.name));
  for (const note of backup.notes) {
    for (const tag of note.tags) tagNames.add(tag);
  }
  const tagColors = new Map(backup.tags.map((tag) => [tag.name, tag.color]));

  await prisma.$transaction(
    async (transaction) => {
      await transaction.note.deleteMany({ where: { userId } });
      await transaction.tag.deleteMany({ where: { userId } });
      await transaction.category.deleteMany({ where: { userId } });

      if (customCategories.length > 0) {
        await transaction.category.createMany({
          data: customCategories.map((category) => ({
            userId,
            name: category.name,
            iconCodePoint: category.iconCodePoint,
          })),
        });
      }

      if (tagNames.size > 0) {
        await transaction.tag.createMany({
          data: [...tagNames].map((name) => ({
            userId,
            name,
            color: tagColors.get(name) ?? null,
          })),
        });
      }

      const tags = await transaction.tag.findMany({
        where: { userId },
        select: { id: true, name: true },
      });
      const tagIds = new Map(tags.map((tag) => [tag.name, tag.id]));

      for (const note of backup.notes) {
        await transaction.note.create({
          data: {
            userId,
            title: note.title,
            content: note.content,
            category: note.category,
            color: note.color,
            isPinned: note.isPinned,
            isFavorite: note.isFavorite,
            isArchived: note.isArchived,
            createdAt: new Date(note.createdAt),
            tags:
              note.tags.length > 0
                ? {
                    create: note.tags.map((name) => {
                      const tagId = tagIds.get(name);
                      if (!tagId) {
                        throw new AppError(
                          400,
                          `Backup references an unavailable tag: ${name}`,
                        );
                      }
                      return { tagId };
                    }),
                  }
                : undefined,
          },
        });
      }
    },
    { maxWait: 10_000, timeout: 120_000 },
  );

  return {
    message: "Backup restored successfully.",
    restored: {
      notes: backup.notes.length,
      tags: tagNames.size,
      categories: customCategories.length,
    },
  };
}
