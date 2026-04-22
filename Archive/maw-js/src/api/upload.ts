/**
 * POST /api/upload — Accept image uploads for agent context.
 * GET  /api/uploads/:filename — Serve uploaded files.
 *
 * Limits: 10MB per file, images only (png/jpg/gif/webp).
 * Uploaded files stored in /tmp/maw-uploads/
 */
import { Elysia } from "elysia";
import { mkdirSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { randomUUID } from "crypto";

const UPLOAD_DIR = join(tmpdir(), "maw-uploads");
const MAX_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_TYPES = ["image/png", "image/jpeg", "image/gif", "image/webp"];

function ensureDir() {
  if (!existsSync(UPLOAD_DIR)) mkdirSync(UPLOAD_DIR, { recursive: true });
}

export const uploadApi = new Elysia({ prefix: "/api" })
  .post("/upload", async ({ request, set }) => {
    ensureDir();

    const formData = await request.formData();
    const file = formData.get("file");

    if (!file || !(file instanceof File)) {
      set.status = 400;
      return { ok: false, error: "No file provided. Use multipart field 'file'." };
    }

    if (file.size > MAX_SIZE) {
      set.status = 413;
      return { ok: false, error: `File too large: ${file.size} bytes (max ${MAX_SIZE})` };
    }

    if (!ALLOWED_TYPES.includes(file.type)) {
      set.status = 415;
      return { ok: false, error: `Invalid type: ${file.type}. Allowed: ${ALLOWED_TYPES.join(", ")}` };
    }

    const ext = file.type.split("/")[1] || "png";
    const filename = `${randomUUID()}.${ext}`;
    const filepath = join(UPLOAD_DIR, filename);

    const buffer = Buffer.from(await file.arrayBuffer());
    writeFileSync(filepath, buffer);

    const origin = new URL(request.url).origin;

    return {
      ok: true,
      filename,
      url: `${origin}/api/uploads/${filename}`,
      path: filepath,
      size: buffer.length,
      type: file.type,
    };
  })
  .get("/uploads/:filename", ({ params, set }) => {
    const safe = params.filename.replace(/[^a-zA-Z0-9._-]/g, "");
    const filepath = join(UPLOAD_DIR, safe);

    if (!existsSync(filepath)) {
      set.status = 404;
      return "Not found";
    }

    const data = readFileSync(filepath);
    const ext = safe.split(".").pop()?.toLowerCase() || "png";
    const mime: Record<string, string> = {
      png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg",
      gif: "image/gif", webp: "image/webp",
    };
    set.headers["content-type"] = mime[ext] || "application/octet-stream";
    set.headers["cache-control"] = "public, max-age=86400";
    return data;
  });
