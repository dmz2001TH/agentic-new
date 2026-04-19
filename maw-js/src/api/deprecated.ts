import { Elysia, t } from "elysia";
import { costsApi } from "./costs";
import { feedBuffer } from "./feed";

// Shim for ALL deprecated APIs that the frontend expects
export const deprecatedApi = new Elysia()
  // 1. Mock Tokens & Costs
  .get("/tokens", () => ({ total: 0, breakdown: [], note: "Shim" }))
  .get("/tokens/rate", () => ({ rate: 0, window: 3600 }))

  // 2. Mock Maw Log
  .get("/maw-log", ({ query }) => {
    const limit = Number(query.limit || 500);
    return feedBuffer.slice(-limit).map(event => ({
      ...event,
      timestamp: event.timestamp || new Date().toISOString()
    }));
  }, { query: t.Object({ limit: t.Optional(t.String()) }) })

  // 3. Mock Stats & Reflection (Overview)
  .get("/stats", () => ({ sessions: 1, tokens: 0, activeAgents: 2, uptime: process.uptime() }))
  .get("/reflect", () => ({ status: "online", identity: "Oracle v3", capabilities: ["memory", "fleet"] }))
  .get("/oraclenet/status", () => ({ connected: true, peers: 0 }))
  
  // 4. Mock Session Stats (Header)
  .get("/session/stats", () => ({ totalTokens: 0, cost: 0, duration: 0 }))

  // 5. Mock Auth Status (CRITICAL: Fixes 500 Error and JSON Parse Error)
  .get("/auth/status", () => ({ authenticated: true, user: "phasa", role: "admin" }))

  // 6. Mock Knowledge View
  .get("/list", () => ({ documents: [] }))
  .get("/graph", () => ({ nodes: [], links: [] }))
  .get("/map", () => ({ clusters: [] }))

  // 7. Mock Dashboard & Forum
  .get("/dashboard/summary", () => ({ totalLearnings: 0, totalPatterns: 0, totalDecisions: 0 }))
  .get("/dashboard/activity", () => ({ activity: [] }))
  .get("/dashboard/growth", () => ({ growth: [] }))
  .get("/threads", () => ({ threads: [] }));
