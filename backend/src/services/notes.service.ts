import { prisma, Prisma } from '../db';
import { assertCategoryAvailable } from './categories.service';

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
  searchIn?: 'all' | 'title' | 'content' | 'tags';
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

/**
 * Column names can never be bound as SQL parameters, so the only safe way to
 * expose a client-controlled ordering is a fixed allow-list. Anything the
 * client sends that is not a key here falls back to the default column.
 */
const SORT_COLUMNS: Record<string, string> = {
  createdAt: 'n."createdAt"',
  updatedAt: 'n."updatedAt"',
  title: 'n."title"',
};

const NOTE_DTO_COLUMNS = `
  n."id", n."userId", n."title", n."content", n."category", n."color",
  n."isPinned", n."isFavorite", n."isArchived",
  n."createdAt", n."updatedAt", n."deletedAt"
`;

interface NoteDto {
  id: string;
  userId: string;
  title: string;
  content: string;
  category: string;
  color: string;
  isPinned: boolean;
  isFavorite: boolean;
  isArchived: boolean;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  tags: string[];
}

/**
 * The `q` branch needs raw SQL because `searchVector` is an
 * Unsupported("tsvector") column the Prisma client cannot filter on.
 * Every client-supplied value goes through `Prisma.sql` placeholders ($1, $2…)
 * so it is bound, never concatenated — see the sort allow-list for the one
 * thing that cannot be bound.
 */
function buildSearchWhere(options: ListNotesOptions): Prisma.Sql {
  const conditions: Prisma.Sql[] = [
    Prisma.sql`n."userId" = ${options.userId}`,
    Prisma.sql`n."deletedAt" IS NULL`,
  ];

  if (!options.includeArchived) {
    conditions.push(Prisma.sql`n."isArchived" = false`);
  } else if (options.isArchived !== undefined) {
    conditions.push(Prisma.sql`n."isArchived" = ${options.isArchived}`);
  }

  if (options.isPinned !== undefined) {
    conditions.push(Prisma.sql`n."isPinned" = ${options.isPinned}`);
  }
  if (options.isFavorite !== undefined) {
    conditions.push(Prisma.sql`n."isFavorite" = ${options.isFavorite}`);
  }
  if (options.category) {
    conditions.push(Prisma.sql`n."category" = ${options.category}`);
  }
  if (options.tags && options.tags.length > 0) {
    conditions.push(Prisma.sql`
      EXISTS (
        SELECT 1
        FROM note_tags nt
        JOIN tags t ON nt."tagId" = t."id"
        WHERE nt."noteId" = n."id" AND t."name" IN (${Prisma.join(options.tags)})
      )
    `);
  }

  return Prisma.join(conditions, ' AND ');
}

async function attachTags(notes: NoteDto[]): Promise<NoteDto[]> {
  if (notes.length === 0) return notes;

  const links = await prisma.noteTag.findMany({
    where: { noteId: { in: notes.map(note => note.id) } },
    include: { tag: true },
  });

  const tagsByNote = new Map<string, string[]>();
  for (const link of links) {
    const names = tagsByNote.get(link.noteId) ?? [];
    names.push(link.tag.name);
    tagsByNote.set(link.noteId, names);
  }

  return notes.map(note => ({ ...note, tags: tagsByNote.get(note.id) ?? [] }));
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

  // `q` is not applied here: `searchVector` is an Unsupported("tsvector") column,
  // so it cannot be filtered through the Prisma client. listNotes() routes `q`
  // through a raw SQL query instead.

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
  const { userId, page, limit, q, sort, searchIn, ...filters } = options;
  const skip = (page - 1) * limit;

  // Build base where clause
  const where = buildWhereClause(options);

  let notes: NoteDto[];
  let total: number;

  if (q) {
    const searchWhere = buildSearchWhere(options);
    const pattern = `%${q}%`;
    const mode = searchIn || 'all';

    const titleCond = Prisma.sql`n."title" ILIKE ${pattern}`;
    const contentCond = Prisma.sql`n."content" ILIKE ${pattern}`;
    const tagCond = Prisma.sql`EXISTS (
            SELECT 1 FROM note_tags nt JOIN tags t ON nt."tagId" = t."id"
            WHERE nt."noteId" = n."id" AND t."name" ILIKE ${pattern}
          )`;

    let matchCond: Prisma.Sql;
    if (mode === 'title') matchCond = titleCond;
    else if (mode === 'content') matchCond = contentCond;
    else if (mode === 'tags') matchCond = tagCond;
    else matchCond = Prisma.sql`${titleCond} OR ${contentCond} OR ${tagCond}`;

    const [field, direction] = sort.split(':');
    const column = SORT_COLUMNS[field] ?? SORT_COLUMNS.createdAt;
    const order = direction === 'asc' ? 'ASC' : 'DESC';

    const searchSql = Prisma.sql`
      SELECT ${Prisma.raw(NOTE_DTO_COLUMNS)}
      FROM notes n
      WHERE ${searchWhere}
        AND (${matchCond})
      ORDER BY ${Prisma.raw(`${column} ${order}`)}
      LIMIT ${limit} OFFSET ${skip}
    `;

    const countSql = Prisma.sql`
      SELECT COUNT(*)::int AS count
      FROM notes n
      WHERE ${searchWhere}
        AND (${matchCond})
    `;

    const [rows, countRows] = await Promise.all([
      prisma.$queryRaw<NoteDto[]>(searchSql),
      prisma.$queryRaw<{ count: number }[]>(countSql),
    ]);

    notes = await attachTags(rows);
    total = countRows[0]?.count ?? 0;
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

    notes = notesResult.map(note => ({
      ...note,
      tags: note.tags.map(nt => nt.tag.name),
    }));
    total = totalResult;
  }

  return {
    data: notes,
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
  await assertCategoryAvailable(userId, data.category || 'Ideas');

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

  if (data.category !== undefined) {
    await assertCategoryAvailable(userId, data.category);
  }

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