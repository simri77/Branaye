import { z } from 'zod';

export const createNoteSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200),
    content: z.string().max(10000).optional(),
    category: z.enum(['Personal', 'Work', 'Study', 'Ideas']).optional(),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
    isPinned: z.boolean().optional(),
    isFavorite: z.boolean().optional(),
    tags: z.array(z.string().min(1).max(50)).max(20).optional(),
  }),
});

export const updateNoteSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(200).optional(),
    content: z.string().max(10000).optional(),
    category: z.enum(['Personal', 'Work', 'Study', 'Ideas']).optional(),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
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
    category: z.enum(['Personal', 'Work', 'Study', 'Ideas']).optional(),
    isPinned: z.coerce.boolean().optional(),
    isFavorite: z.coerce.boolean().optional(),
    isArchived: z.coerce.boolean().optional(),
    includeArchived: z.coerce.boolean().optional(),
    q: z.string().optional(),
    tags: z.string().optional(),
    sort: z.enum(['createdAt:desc', 'createdAt:asc', 'updatedAt:desc', 'updatedAt:asc', 'title:asc', 'title:desc']).default('createdAt:desc'),
  }),
});

export const createTagSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(50),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
  }),
});

export const updateTagSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(50).optional(),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
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