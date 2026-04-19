/**
 * Tests for src/api/upload.ts — POST /api/upload + GET /api/uploads/:filename.
 *
 * Routes:
 *   POST /api/upload          — accepts multipart file, returns JSON
 *   GET  /api/uploads/:name   — serves uploaded file by filename
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import { mkdtempSync, rmSync, existsSync, readdirSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { Elysia } from "elysia";

// --- Build test app ---

let app: Elysia;

beforeAll(async () => {
  const { uploadApi } = await import("../src/api/upload");
  app = new Elysia().use(uploadApi);
});

// Clean up uploaded files after tests
afterAll(() => {
  const UPLOAD_DIR = join(tmpdir(), "maw-uploads");
  if (existsSync(UPLOAD_DIR)) {
    rmSync(UPLOAD_DIR, { recursive: true, force: true });
  }
});

// --- POST /api/upload ---

describe("POST /api/upload", () => {
  test("valid image file → 200 + {ok, filename, url, path, size, type}", async () => {
    // Create a minimal PNG (1x1 pixel) for a valid image type
    const pngBytes = new Uint8Array([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG signature
      0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
      0x00, 0x00, 0x02, 0x00, 0x01, 0xe2, 0x21, 0xbc,
      0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
      0x44, 0xae, 0x42, 0x60, 0x82,
    ]);
    const form = new FormData();
    form.append(
      "file",
      new File([pngBytes], "test.png", { type: "image/png" }),
    );
    const res = await app.handle(
      new Request("http://localhost/api/upload", { method: "POST", body: form }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.filename).toMatch(/\.png$/);
    expect(body.url).toInclude("/api/uploads/");
    expect(body.path).toInclude("maw-uploads");
    expect(body.size).toBeGreaterThan(0);
    expect(body.type).toBe("image/png");
  });

  test("no file field → 400", async () => {
    const form = new FormData();
    // append something that isn't a File
    form.append("notfile", "just text");
    const res = await app.handle(
      new Request("http://localhost/api/upload", { method: "POST", body: form }),
    );
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.ok).toBe(false);
    expect(body.error).toBeDefined();
  });

  test("disallowed type → 415", async () => {
    const form = new FormData();
    form.append(
      "file",
      new File(["text content"], "doc.txt", { type: "text/plain" }),
    );
    const res = await app.handle(
      new Request("http://localhost/api/upload", { method: "POST", body: form }),
    );
    expect(res.status).toBe(415);
    const body = await res.json();
    expect(body.ok).toBe(false);
    expect(body.error).toInclude("Invalid type");
  });
});

// --- GET /api/uploads/:filename ---

describe("GET /api/uploads/:filename", () => {
  test("existing file → 200 + file content", async () => {
    // First upload a file to ensure it exists
    const pngBytes = new Uint8Array([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
      0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
      0x00, 0x00, 0x02, 0x00, 0x01, 0xe2, 0x21, 0xbc,
      0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
      0x44, 0xae, 0x42, 0x60, 0x82,
    ]);
    const form = new FormData();
    form.append("file", new File([pngBytes], "fetch-test.png", { type: "image/png" }));
    const uploadRes = await app.handle(
      new Request("http://localhost/api/upload", { method: "POST", body: form }),
    );
    const uploaded = await uploadRes.json();

    // Now fetch it back
    const res = await app.handle(
      new Request(`http://localhost/api/uploads/${uploaded.filename}`),
    );
    expect(res.status).toBe(200);
    const contentType = res.headers.get("content-type");
    expect(contentType).toBe("image/png");
  });

  test("missing file → 404", async () => {
    const res = await app.handle(
      new Request("http://localhost/api/uploads/no-such-file.png"),
    );
    expect(res.status).toBe(404);
  });
});
