import { Elysia, t } from "elysia";
import { costsApi } from "./costs";
import { feedBuffer } from "./feed";
import { loadConfig } from "../config";

const ORACLE_URL = process.env.ORACLE_URL || loadConfig().oracleUrl;

// Helper: proxy GET to Oracle Core
async function oracleGet(path: string, fallback: any = {}) {
  try {
    const res = await fetch(`${ORACLE_URL}${path}`);
    if (!res.ok) {
      console.warn(`[oracle-proxy] ${path} → ${res.status} ${res.statusText}`);
      return fallback;
    }
    return await res.json();
  } catch (e: any) {
    console.warn(`[oracle-proxy] ${path} → unreachable (${e.message})`);
    return fallback;
  }
}

// Helper: proxy POST to Oracle Core
async function oraclePost(path: string, body: any, set: any) {
  try {
    const res = await fetch(`${ORACLE_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) { set.status = res.status; return data; }
    return data;
  } catch (e: any) {
    console.warn(`[oracle-proxy] POST ${path} → unreachable (${e.message})`);
    set.status = 502;
    return { error: `Oracle unreachable: ${e.message}` };
  }
}

// Shim for ALL deprecated APIs that the frontend expects.
// Routes that exist in Oracle Core are PROXIED (real data).
// Routes that are Maw-native stay as local handlers.
export const deprecatedApi = new Elysia()
  // 1. Maw-native: Tokens & Costs (Maw tracks these, not Oracle)
  .get("/tokens", () => ({ total: 0, breakdown: [], note: "Shim" }))
  .get("/tokens/rate", () => ({ rate: 0, window: 3600 }))

  // 2. Maw-native: Maw Log (live feed buffer)
  .get("/maw-log", ({ query }) => {
    const limit = Number(query.limit || 500);
    return feedBuffer.slice(-limit).map(event => ({
      ...event,
      timestamp: event.timestamp || new Date().toISOString()
    }));
  }, { query: t.Object({ limit: t.Optional(t.String()) }) })

  // 3. Oracle proxy: Stats, Reflect, Knowledge
  .get("/stats", async () => {
    const oracle = await oracleGet("/api/stats");
    return { ...oracle, sessions: 1, uptime: process.uptime() };
  })
  .get("/reflect", () => oracleGet("/api/reflect", { status: "online", identity: "Oracle v3", capabilities: ["memory", "fleet"] }))
  .get("/list", ({ query }) => {
    const params = new URLSearchParams();
    if (query.type) params.set("type", query.type);
    if (query.limit) params.set("limit", query.limit);
    if (query.offset) params.set("offset", query.offset);
    return oracleGet(`/api/list?${params}`, { results: [], total: 0 });
  }, { query: t.Object({
    type: t.Optional(t.String()),
    limit: t.Optional(t.String()),
    offset: t.Optional(t.String()),
  }) })
  .get("/graph", () => oracleGet("/api/graph", { nodes: [], links: [] }))
  .get("/map", () => oracleGet("/api/map", { clusters: [] }))
  .get("/similar", ({ query }) => {
    const params = new URLSearchParams();
    if (query.id) params.set("id", query.id);
    if (query.limit) params.set("limit", query.limit);
    return oracleGet(`/api/similar?${params}`, { results: [] });
  }, { query: t.Object({
    id: t.Optional(t.String()),
    limit: t.Optional(t.String()),
  }) })

  // 4. Oracle proxy: Search (CRITICAL — was completely missing)
  .get("/search", ({ query, set }) => {
    const q = query?.q;
    if (!q) { set.status = 400; return { error: "q required" }; }
    const params = new URLSearchParams({ q });
    if (query.mode) params.set("mode", query.mode);
    if (query.limit) params.set("limit", query.limit);
    if (query.type) params.set("type", query.type);
    if (query.model) params.set("model", query.model);
    if (query.offset) params.set("offset", query.offset);
    return oracleGet(`/api/search?${params}`, { results: [], total: 0, query: q });
  }, { query: t.Object({
    q: t.Optional(t.String()),
    mode: t.Optional(t.String()),
    limit: t.Optional(t.String()),
    type: t.Optional(t.String()),
    model: t.Optional(t.String()),
    offset: t.Optional(t.String()),
  }) })

  // 5. Oracle proxy: Learn (CRITICAL — was completely missing)
  .post("/learn", async ({ body, set }) => {
    return oraclePost("/api/learn", body, set);
  })

  // 6. Oracle proxy: Session Stats (Header)
  .get("/session/stats", () => oracleGet("/api/session/stats", { totalTokens: 0, cost: 0, duration: 0 }))

  // 7. Oracle proxy: Auth (CRITICAL — login was missing)
  .get("/auth/status", () => oracleGet("/api/auth/status", { authenticated: true, user: "local", role: "admin" }))
  .post("/auth/login", async ({ body, set }) => {
    return oraclePost("/api/auth/login", body, set);
  })

  // 8. Oracle proxy: Dashboard
  .get("/dashboard/summary", () => oracleGet("/api/dashboard/summary", { totalLearnings: 0, totalPatterns: 0, totalDecisions: 0 }))
  .get("/dashboard/activity", ({ query }) => {
    const params = new URLSearchParams();
    if (query.days) params.set("days", query.days);
    return oracleGet(`/api/dashboard/activity?${params}`, { activity: [] });
  }, { query: t.Object({ days: t.Optional(t.String()) }) })
  .get("/dashboard/growth", ({ query }) => {
    const params = new URLSearchParams();
    if (query.days) params.set("days", query.days);
    return oracleGet(`/api/dashboard/growth?${params}`, { growth: [] });
  }, { query: t.Object({ days: t.Optional(t.String()) }) })

  // 9. Oracle proxy: Settings (CRITICAL — was completely missing)
  .get("/settings", () => oracleGet("/api/settings", {}))
  .post("/settings", async ({ body, set }) => {
    return oraclePost("/api/settings", body, set);
  })

  // 10. Oracle proxy: OracleNet
  .get("/oraclenet/status", () => oracleGet("/api/oraclenet/status", { connected: false, peers: 0 }))

  // 11. Maw-native: Forum/Threads (no Oracle equivalent yet)
  .get("/threads", () => ({ threads: [] }))

  // 12. Oracle proxy: Health check (frontend uses this to verify backend)
  .get("/health", async () => {
    try {
      const res = await fetch(`${ORACLE_URL}/api/health`);
      if (res.ok) {
        const data = await res.json();
        return { status: "ok", oracle: data, maw: "ok", port: 3456 };
      }
      return { status: "degraded", oracle: "error", maw: "ok" };
    } catch {
      return { status: "degraded", oracle: "unreachable", maw: "ok" };
    }
  });
