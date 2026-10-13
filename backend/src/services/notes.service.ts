import { prisma } from '../db';
import { Prisma } from '@prisma/client';

export interface ListNotesOptions {
  userId: string;
  page: number;
  limit: number;
  category?: string;
  isPinned?: boolean;
  isFavorite?: boolean;
  isArchived?: boolean;
  includeArchived?: boolean;
  q?: string;
  tags?: string[];
  sort: string;
}

export interface PaginatedResult<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

function buildSortOrder(sort: string): Prisma.NoteOrderByWithRelationInput {
  const [field, direction] = sort.split(':');
  return { [field]: direction } as Prisma.NoteOrderByWithRelationInput;
}

function buildWhereClause(options: ListNotesOptions): Prisma.NoteWhereInput {
  const where: Prisma.NoteWhereInput = {
    userId: options.userId,
    deletedAt: null,
  };

  if (!options.includeArchived) {
    where.isArchived = false;
  } else if (options.isArchived !== undefined) {
    where.isArchived = options.isArchived;
  }

  if (options.isPinned !== undefined) where.isPinned = options.isPinned;
  if (options.isFavorite !== undefined) where.isFavorite = options.isFavorite;
  if (options.category) where.category = options.category;

  if (options.q) {
    where.searchVector = {
      // Using Prisma's raw query for tsvector search
      // This will be handled in the raw query below
    };
  }

  if (options.tags && options.tags.length > 0) {
    where.tags = {
      some: {
        tag: {
          name: { in: options.tags },
        },
      },
    };
  }

  return where;
}

export async function listNotes(options: ListNotesOptions): Promise<PaginatedResult<any>> {
  const { userId, page, limit, q, sort, ...filters } = options;
  const skip = (page - 1) * limit;

  // Build base where clause
  const where = buildWhereClause(options);

  let notes: any[];
  let total: number;

  if (q) {
    // Use raw query for full-text search with ranking
    const searchQuery = `
      SELECT n.*, 
        ts_rank_cd(n.search_vector, plainto_tsquery('english', $1)) as rank
      FROM notes n
      WHERE n.user_id = $2
        AND n.deleted_at IS NULL
        ${!options.includeArchived ? 'AND n.is_archived = false' : ''}
        ${options.isPinned !== undefined ? `AND n.is_pinned = ${options.isPinned}` : ''}
        ${options.isFavorite !== undefined ? `AND n.is_favorite = ${options.isFavorite}` : ''}
        ${options.category ? `AND n.category = '${options.category}'` : ''}
        ${options.tags && options.tags.length > 0 ? `
          AND EXISTS (
            SELECT 1 FROM note_tags nt
            JOIN tags t ON nt.tag_id = t.id
            WHERE nt.note_id = n.id AND t.name IN (${options.tags.map(t => `'${t}'`).join(',')})
          )
        ` : ''}
        AND n.search_vector @@ plainto_tsquery('english', $1)
      ORDER BY rank DESC, n.${sort.split(':')[0]} ${sort.split(':')[1].toUpperCase()}
      LIMIT $3 OFFSET $4
    `;

    const countQuery = `
      SELECT COUNT(*) 
      FROM notes n
      WHERE n.user_id = $1
        AND n.deleted_at IS NULL
        ${!options.includeArchived ? 'AND n.is_archived = false' : ''}
        ${options.isPinned !== undefined ? `AND n.is_pinned = ${options.isPinned}` : ''}
        ${options.isFavorite !== undefined ? `AND n.is_favorite = ${options.isFavorite}` : ''}
        ${options.category ? `AND n.category = '${options.category}'` : ''}
        ${options.tags && options.tags.length > 0 ? `
          AND EXISTS (
            SELECT 1 FROM note_tags nt
            JOIN tags t ON nt.tag_id = t.id
            WHERE nt.note_id = n.id AND t.name IN (${options.tags.map(t => `'${t}'`).join(',')})
          )
        ` : ''}
        AND n.search_vector @@ plainto_tsquery('english', $2)
    `;

    const [notesResult, countResult] = await Promise.all([
      prisma.$queryRawUnsafe(searchQuery, q, userId, limit, skip),
      prisma.$queryRawUnsafe(countQuery, userId, q),
    ]);

    notes = notesResult as any[];
    total = Number((countResult as any[])[0]?.count || 0);
  } else {
    // Regular query without search
    const [notesResult, totalResult] = await Promise.all([
      prisma.note.findMany({
        where,
        orderBy: buildSortOrder(sort),
        skip,
        take: limit,
        include: {
          tags: {
            include: {
              tag: true,
            },
          },
        },
      }),
      prisma.note.count({ where }),
    ]);

    notes = notesResult;
    total = totalResult;
  }

  return {
    data: notes.map(note => ({
      ...note,
      tags: note.tags.map((nt: any) => nt.tag.name),
    })),
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function getNoteById(userId: string, id: string) {
  const note = await prisma.note.findFirst({
    where: { id, userId, deletedAt: null },
    include: {
      tags: {
        include: {
          tag: true,
        },
      },
    },
  });

  if (!note) return null;

  return {
    ...note,
    tags: note.tags.map(nt => nt.tag.name),
  };
}

export async function createNote(
  userId: string,
  data: {
    title: string;
    content?: string;
    category?: string;
    color?: string;
    isPinned?: boolean;
    isFavorite?: boolean;
    tags?: string[];
  }
) {
  // Handle tags: find or create
  let tagIds: string[] = [];
  if (data.tags && data.tags.length > 0) {
    for (const tagName of data.tags) {
      let tag = await prisma.tag.findUnique({
        where: { userId_name: { userId, name: tagName } },
      });
      if (!tag) {
        tag = await prisma.tag.create({
          data: { userId, name: tagName },
        });
      }
      tagIds.push(tag.id);
    }
  }

  const note = await prisma.note.create({
    data: {
      userId,
      title: data.title,
      content: data.content || '',
      category: data.category || 'Ideas',
      color: data.color || '#464BD4',
      isPinned: data.isPinned || false,
      isFavorite: data.isFavorite || false,
      tags: tagIds.length > 0
        ? { create: tagIds.map(tagId => ({ tagId })) }
        : undefined,
    },
    include: {
      tags: { include: { tag: true } },
    },
  });

  return {
    ...note,
    tags: note.tags.map(nt => nt.tag.name),
  };
}

export async function updateNote(
  userId: string,
  id: string,
  data: {
    title?: string;
    content?: string;
    category?: string;
    color?: string;
    isPinned?: boolean;
    isFavorite?: boolean;
    isArchived?: boolean;
    tags?: string[];
  }
) {
  // Check ownership
  const existing = await prisma.note.findFirst({ where: { id, userId, deletedAt: null } });
  if (!existing) return null;

  // Handle tags replacement
  if (data.tags !== undefined) {
    let tagIds: string[] = [];
    for (const tagName of data.tags) {
      let tag = await prisma.tag.findUnique({
        where: { userId_name: { userId, name: tagName } },
      });
      if (!tag) {
        tag = await prisma.tag.create({ data: { userId, name: tagName } });
      }
      tagIds.push(tag.id);
    }

    // Delete existing NoteTag relations and create new ones
    await prisma.$transaction([
      prisma.noteTag.deleteMany({ where: { noteId: id } }),
      prisma.noteTag.createMany({
        data: tagIds.map(tagId => ({ noteId: id, tagId })),
      }),
    ]);
  }

  const note = await prisma.note.update({
    where: { id },
    data: {
      title: data.title,
      content: data.content,
      category: data.category,
      color: data.color,
      isPinned: data.isPinned,
      isFavorite: data.isFavorite,
      isArchived: data.isArchived,
    },
    include: {
      tags: { include: { tag: true } },
    },
  });

  return {
    ...note,
    tags: note.tags.map(nt => nt.tag.name),
  };
}

export async function deleteNote(userId: string, id: string): Promise<boolean> {
  const result = await prisma.note.deleteMany({
    where: { id, userId },
  });
  return result.count > 0;
}