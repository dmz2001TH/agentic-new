import { Elysia, t } from "elysia";

/**
 * Web search API — uses multiple free search providers as fallback
 * Agents can search the web without external dependencies
 */

// Provider 1: DuckDuckGo Instant Answer API (free, no key)
async function searchDuckDuckGo(query: string, limit: number) {
  try {
    const url = `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1&skip_disambig=1`;
    const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
    if (!res.ok) return [];
    const data = await res.json() as any;

    const results: any[] = [];

    // Abstract
    if (data.Abstract) {
      results.push({
        title: data.Heading || query,
        snippet: data.Abstract,
        url: data.AbstractURL || "",
        source: data.AbstractSource || "DuckDuckGo",
      });
    }

    // Related topics
    if (data.RelatedTopics) {
      for (const topic of data.RelatedTopics.slice(0, limit - results.length)) {
        if (topic.Text) {
          results.push({
            title: topic.Text.slice(0, 80),
            snippet: topic.Text,
            url: topic.FirstURL || "",
            source: "DuckDuckGo",
          });
        }
      }
    }

    return results.slice(0, limit);
  } catch {
    return [];
  }
}

// Provider 2: Wikipedia API (free, no key)
async function searchWikipedia(query: string, limit: number) {
  try {
    const searchUrl = `https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&srlimit=${limit}&format=json&origin=*`;
    const res = await fetch(searchUrl, { signal: AbortSignal.timeout(10000) });
    if (!res.ok) return [];
    const data = await res.json() as any;

    return (data.query?.search || []).map((item: any) => ({
      title: item.title,
      snippet: item.snippet?.replace(/<[^>]*>/g, "") || "",
      url: `https://en.wikipedia.org/wiki/${encodeURIComponent(item.title.replace(/ /g, "_"))}`,
      source: "Wikipedia",
    }));
  } catch {
    return [];
  }
}

// Provider 3: Hacker News Algolia API (free, no key) — for tech queries
async function searchHackerNews(query: string, limit: number) {
  try {
    const url = `https://hn.algolia.com/api/v1/search_by_date?query=${encodeURIComponent(query)}&hitsPerPage=${limit}`;
    const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
    if (!res.ok) return [];
    const data = await res.json() as any;

    return (data.hits || []).map((item: any) => ({
      title: item.title || item.story_title || "(no title)",
      snippet: item.comment_text?.slice(0, 200) || item.story_text?.slice(0, 200) || "",
      url: item.url || item.story_url || `https://news.ycombinator.com/item?id=${item.objectID}`,
      source: "Hacker News",
      points: item.points,
      author: item.author,
    }));
  } catch {
    return [];
  }
}

export const searchApi = new Elysia({ prefix: "/search" });

// Web search: GET /api/search/web?q=...&limit=10&providers=ddg,wikipedia,hn
searchApi.get("/web", async ({ query, set }) => {
  const q = query.q;
  if (!q) { set.status = 400; return { error: "q required" }; }

  const limit = Math.min(Number(query.limit) || 10, 20);
  const providers = (query.providers || "ddg,wikipedia").split(",");

  const results: any[] = [];
  const errors: string[] = [];

  // Run providers in parallel
  const promises: Promise<any[]>[] = [];

  if (providers.includes("ddg")) {
    promises.push(searchDuckDuckGo(q, limit).catch(e => { errors.push(`ddg: ${e.message}`); return []; }));
  }
  if (providers.includes("wikipedia")) {
    promises.push(searchWikipedia(q, limit).catch(e => { errors.push(`wikipedia: ${e.message}`); return []; }));
  }
  if (providers.includes("hn")) {
    promises.push(searchHackerNews(q, limit).catch(e => { errors.push(`hn: ${e.message}`); return []; }));
  }

  const allResults = await Promise.all(promises);
  for (const r of allResults) {
    results.push(...r);
  }

  return {
    query: q,
    results: results.slice(0, limit),
    total: results.length,
    providers: providers,
    errors: errors.length > 0 ? errors : undefined,
  };
}, {
  query: t.Object({
    q: t.String(),
    limit: t.Optional(t.String()),
    providers: t.Optional(t.String()),
  }),
});

// Fetch URL content: GET /api/search/fetch?url=...
searchApi.get("/fetch", async ({ query, set }) => {
  const url = query.url;
  if (!url) { set.status = 400; return { error: "url required" }; }

  try {
    const res = await fetch(url, {
      signal: AbortSignal.timeout(15000),
      headers: { "User-Agent": "Oracle-Agent/1.0" },
    });

    const contentType = res.headers.get("content-type") || "";

    // If HTML, extract text (basic)
    if (contentType.includes("html")) {
      const html = await res.text();
      // Strip HTML tags for basic text extraction
      const text = html
        .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
        .replace(/<[^>]+>/g, " ")
        .replace(/\s+/g, " ")
        .trim()
        .slice(0, 5000);

      return { url, contentType, text, status: res.status };
    }

    // Otherwise return as text
    const text = (await res.text()).slice(0, 5000);
    return { url, contentType, text, status: res.status };
  } catch (e: any) {
    set.status = 502;
    return { error: e.message, url };
  }
}, {
  query: t.Object({ url: t.String() }),
});
