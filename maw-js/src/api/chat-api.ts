/**
 * Chat API — Agent-to-Agent messaging endpoints
 *
 * POST /api/chat/send       — Send a message from one agent to another
 * GET  /api/chat/:agent     — Get unread messages for an agent
 * POST /api/chat/read       — Mark a message as read
 * GET  /api/chat/history    — Chat history between two agents
 * GET  /api/chat/all        — List all active chats
 */

import { Elysia, t } from "elysia";
import {
  sendChatMessage,
  getChatMessages,
  markChatRead,
  getChatHistory,
  listAllChats,
  dispatchChat,
} from "../core/chat";

export const chatApi = new Elysia({ prefix: "/chat" });

// Send a chat message
chatApi.post("/send", async ({ body }) => {
  const { from, to, message } = body as { from: string; to: string; message: string };

  if (!from || !to || !message) {
    return { error: "Missing required fields: from, to, message" };
  }

  const chatMsg = sendChatMessage(from, to, message);

  // Try to dispatch immediately
  const dispatched = await dispatchChat(chatMsg);

  return {
    ok: true,
    message: chatMsg,
    dispatched,
  };
}, {
  body: t.Object({
    from: t.String(),
    to: t.String(),
    message: t.String(),
  }),
});

// Get unread messages for an agent
chatApi.get("/:agent", ({ params }) => {
  const messages = getChatMessages(params.agent);
  return { agent: params.agent, messages, count: messages.length };
});

// Mark a message as read
chatApi.post("/read", ({ body }) => {
  const { filename } = body as { filename: string };
  markChatRead(filename);
  return { ok: true };
}, {
  body: t.Object({ filename: t.String() }),
});

// Get chat history between two agents
chatApi.get("/history/:agent1/:agent2", ({ params, query }) => {
  const limit = parseInt(query?.limit || "20");
  const messages = getChatHistory(params.agent1, params.agent2, limit);
  return { agents: [params.agent1, params.agent2], messages };
});

// List all active chats
chatApi.get("/all", () => {
  const messages = listAllChats();
  return { messages, count: messages.length };
});
