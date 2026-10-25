import { beforeEach, describe, expect, it, vi } from "vitest";
import request from "supertest";
import { prisma } from "../../db";
import { signAccessToken } from "../../config/jwt";
import { setupTestApp } from "./setup";
import backupsRoute from "../backups.route";

const backup = {
  format: "branaye-backup",
  version: 1,
  createdAt: "2026-10-24T10:00:00.000Z",
  account: { id: "user1", email: "ada@example.com" },
  notes: [
    {
      title: "Project idea",
      content: "A restored note",
      category: "Client Work",
      color: "#464BD4",
      createdAt: "2026-10-20T10:00:00.000Z",
      isPinned: true,
      isFavorite: false,
      isArchived: false,
      tags: ["planning"],
    },
  ],
  categories: [{ name: "Client Work", iconCodePoint: 0xe8f9 }],
  tags: [{ name: "planning", color: null }],
};

describe("POST /api/backups/restore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("replaces only the authenticated user data in one transaction", async () => {
    const transaction = {
      note: {
        deleteMany: vi.fn().mockResolvedValue({ count: 2 }),
        create: vi.fn().mockResolvedValue({ id: "restored-note" }),
      },
      tag: {
        deleteMany: vi.fn().mockResolvedValue({ count: 1 }),
        createMany: vi.fn().mockResolvedValue({ count: 1 }),
        findMany: vi.fn().mockResolvedValue([{ id: "tag1", name: "planning" }]),
      },
      category: {
        deleteMany: vi.fn().mockResolvedValue({ count: 1 }),
        createMany: vi.fn().mockResolvedValue({ count: 1 }),
      },
    };
    (prisma.$transaction as any).mockImplementation(
      (callback: (tx: typeof transaction) => Promise<unknown>) =>
        callback(transaction),
    );

    const response = await request(setupTestApp(backupsRoute, "/api/backups"))
      .post("/api/backups/restore")
      .set("Authorization", `Bearer ${signAccessToken("user1")}`)
      .send(backup);

    expect(response.status).toBe(200);
    expect(response.body.restored).toEqual({
      notes: 1,
      tags: 1,
      categories: 1,
    });
    expect(transaction.note.deleteMany).toHaveBeenCalledWith({
      where: { userId: "user1" },
    });
    expect(transaction.tag.deleteMany).toHaveBeenCalledWith({
      where: { userId: "user1" },
    });
    expect(transaction.category.deleteMany).toHaveBeenCalledWith({
      where: { userId: "user1" },
    });
    expect(transaction.note.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: "user1",
        title: "Project idea",
        category: "Client Work",
        tags: { create: [{ tagId: "tag1" }] },
      }),
    });
  });

  it("rejects unsupported or malformed backups before modifying data", async () => {
    const response = await request(setupTestApp(backupsRoute, "/api/backups"))
      .post("/api/backups/restore")
      .set("Authorization", `Bearer ${signAccessToken("user1")}`)
      .send({ ...backup, version: 2 });

    expect(response.status).toBe(400);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it("requires authentication", async () => {
    const response = await request(setupTestApp(backupsRoute, "/api/backups"))
      .post("/api/backups/restore")
      .send(backup);

    expect(response.status).toBe(401);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it("rejects a backup for a different Branaye account", async () => {
    const response = await request(setupTestApp(backupsRoute, "/api/backups"))
      .post("/api/backups/restore")
      .set("Authorization", `Bearer ${signAccessToken("user1")}`)
      .send({
        ...backup,
        account: { ...backup.account, id: "another-user" },
      });

    expect(response.status).toBe(403);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
