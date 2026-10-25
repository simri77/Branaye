import { z } from "zod";

export const registerSchema = z.object({
  body: z.object({
    email: z.string().trim().email().max(254),
    password: z.string().min(8).max(128),
    name: z.string().trim().min(1).max(100),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().trim().email(),
    password: z.string().min(1),
  }),
});

export const resendVerificationSchema = z.object({
  body: z.object({
    email: z.string().trim().email().max(254),
  }),
});

export const googleLoginSchema = z.object({
  body: z.object({
    idToken: z.string().min(1).max(8192),
  }),
});

export const updateMeSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1).max(100),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1),
    newPassword: z.string().min(8).max(128),
  }),
});

export const fcmTokenSchema = z.object({
  body: z.object({
    token: z.string().min(1),
  }),
});

const backupTagSchema = z.object({
  name: z.string().trim().min(1).max(50),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/)
    .nullable(),
});

const backupCategorySchema = z.object({
  name: z.string().trim().min(1).max(50),
  iconCodePoint: z.number().int().min(1).max(0x10ffff),
});

const backupNoteSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().max(10000),
  category: z.string().trim().min(1).max(50),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  createdAt: z.string().datetime(),
  isPinned: z.boolean(),
  isFavorite: z.boolean(),
  isArchived: z.boolean(),
  tags: z.array(z.string().trim().min(1).max(50)).max(20),
});

export const restoreBackupSchema = z.object({
  body: z
    .object({
      format: z.literal("branaye-backup"),
      version: z.literal(1),
      createdAt: z.string().datetime(),
      account: z.object({
        id: z.string().min(1).max(100),
        email: z.string().email().max(254),
      }),
      notes: z.array(backupNoteSchema).max(5000),
      categories: z.array(backupCategorySchema).max(500),
      tags: z.array(backupTagSchema).max(2000),
    })
    .superRefine((backup, context) => {
      const categoryNames = backup.categories.map((category) =>
        category.name.toLowerCase(),
      );
      if (new Set(categoryNames).size !== categoryNames.length) {
        context.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Backup contains duplicate categories",
          path: ["categories"],
        });
      }

      const tagNames = backup.tags.map((tag) => tag.name);
      if (new Set(tagNames).size !== tagNames.length) {
        context.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Backup contains duplicate tags",
          path: ["tags"],
        });
      }

      backup.notes.forEach((note, index) => {
        if (new Set(note.tags).size !== note.tags.length) {
          context.addIssue({
            code: z.ZodIssueCode.custom,
            message: "A note contains duplicate tags",
            path: ["notes", index, "tags"],
          });
        }
      });
    }),
});

export const createCategorySchema = z.object({
  body: z.object({
    name: z.string().trim().min(1).max(50),
    iconCodePoint: z.number().int().min(1).max(0x10ffff),
  }),
});

export const createNoteSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200),
    content: z.string().max(10000).optional(),
    category: z.string().trim().min(1).max(50).optional(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .optional(),
    isPinned: z.boolean().optional(),
    isFavorite: z.boolean().optional(),
    tags: z.array(z.string().min(1).max(50)).max(20).optional(),
  }),
});

export const updateNoteSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200).optional(),
    content: z.string().max(10000).optional(),
    category: z.string().trim().min(1).max(50).optional(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .optional(),
    isPinned: z.boolean().optional(),
    isFavorite: z.boolean().optional(),
    isArchived: z.boolean().optional(),
    tags: z.array(z.string().min(1).max(50)).max(20).optional(),
  }),
  params: z.object({
    id: z.string().cuid(),
  }),
});

export const noteIdParamSchema = z.object({
  params: z.object({
    id: z.string().cuid(),
  }),
});

export const listNotesQuerySchema = z.object({
  query: z.object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    category: z.string().trim().min(1).max(50).optional(),
    isPinned: z.coerce.boolean().optional(),
    isFavorite: z.coerce.boolean().optional(),
    isArchived: z.coerce.boolean().optional(),
    includeArchived: z.coerce.boolean().optional(),
    q: z.string().optional(),
    tags: z.string().optional(),
    sort: z
      .enum([
        "createdAt:desc",
        "createdAt:asc",
        "updatedAt:desc",
        "updatedAt:asc",
        "title:asc",
        "title:desc",
      ])
      .default("createdAt:desc"),
  }),
});

export const createTagSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(50),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .optional(),
  }),
});

export const updateTagSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(50).optional(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .optional(),
  }),
  params: z.object({
    id: z.string().cuid(),
  }),
});

export const tagIdParamSchema = z.object({
  params: z.object({
    id: z.string().cuid(),
  }),
});

export const tagSuggestionsQuerySchema = z.object({
  query: z.object({
    q: z.string().min(1),
    limit: z.coerce.number().int().min(1).max(20).default(10),
  }),
});

export const popularTagsQuerySchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(50).default(10),
  }),
});
