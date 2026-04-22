/**
 * Embedding Providers
 *
 * Ported from Nat-s-Agents data-aware-rag.
 * ChromaDB handles embeddings internally; other stores need these.
 */

import type { EmbeddingProvider, EmbeddingProviderType } from './types.ts';

/**
 * Placeholder for ChromaDB's internal embeddings.
 * ChromaDB generates embeddings server-side — this is never called directly.
 */
export class ChromaDBInternalEmbeddings implements EmbeddingProvider {
  readonly name = 'chromadb-internal';
  readonly dimensions = 384; // all-MiniLM-L6-v2 default

  async embed(_texts: string[]): Promise<number[][]> {
    throw new Error('ChromaDB handles embeddings internally. Use addDocuments() directly.');
  }
}

/**
 * Ollama local embeddings
 * 💡 วิชา 'Token Optimization':
 * ในโลกของ LLM และ Vector Embeddings, 'Token' คือลมปราณพื้นฐาน
 * การจัดการ Token ไม่ใช่แค่การตัด (Truncate) แต่คือการรักษา 'อารมณ์' และ 'บริบท' (Context Preservation)
 * 1. Smart Overlap: ป้องกันข้อมูลหายที่รอยตัด (Boundary Information Loss)
 * 2. Mean Pooling: รวบรวมพลังจากทุก Chunk ให้เป็นหนึ่งเดียว (Unified Semantic Vector)
 * 3. Semantic Density: การเตรียมความพร้อมสำหรับ Advanced RAG ด้วยการประเมินคุณภาพ Context
 */
export class OllamaEmbeddings implements EmbeddingProvider {
  readonly name = 'ollama';
  dimensions: number;
  private baseUrl: string;
  private model: string;
  private _dimensionsDetected = false;

  constructor(config: { baseUrl?: string; model?: string } = {}) {
    this.baseUrl = config.baseUrl || process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
    this.model = config.model || 'nomic-embed-text';
    // Known model dimensions (fallback before auto-detect)
    const KNOWN_DIMS: Record<string, number> = {
      'nomic-embed-text': 768,
      'qwen3-embedding': 4096,
      'bge-m3': 1024,
      'mxbai-embed-large': 1024,
      'all-minilm': 384,
    };
    this.dimensions = KNOWN_DIMS[this.model] || 768;
  }

  async embed(texts: string[]): Promise<number[][]> {
    const embeddings: number[][] = [];

    for (const text of texts) {
      const vector = await this.getSmartEmbedding(text);
      embeddings.push(vector);
    }

    return embeddings;
  }

  /**
   * Smart Overlap & Mean Pooling Implementation
   * ประมวลผลข้อความขนาดยาวด้วยการแบ่งเป็น Chunk ที่ซ้อนทับกัน (Overlap)
   * และหลอมรวมเวกเตอร์ด้วยวิธี Mean Pooling เพื่อไม่ให้ข้อมูลสำคัญสูญหาย
   */
  private async getSmartEmbedding(text: string): Promise<number[]> {
    const MAX_CHARS = 2048; // ปรับแต่งตามขีดจำกัดของ Model (Thai text safe-zone)
    const OVERLAP = 256;    // รักษาบริบทระหว่างรอยต่อ

    if (text.length <= MAX_CHARS) {
      return this.fetchEmbedding(text);
    }

    const chunks: string[] = [];
    let start = 0;
    while (start < text.length) {
      chunks.push(text.slice(start, start + MAX_CHARS));
      start += (MAX_CHARS - OVERLAP);
      if (start >= text.length - OVERLAP) break; // เลิกถ้าเหลือติ่งน้อยเกินไป
    }

    const chunkVectors = await Promise.all(chunks.map(c => this.fetchEmbedding(c)));
    
    // Mean Pooling: การรวมพลังของทุก Chunk ให้เป็นเวกเตอร์หนึ่งเดียวที่ทรงพลัง
    const dims = chunkVectors[0].length;
    const pooled = new Array(dims).fill(0);
    for (const vec of chunkVectors) {
      for (let i = 0; i < dims; i++) {
        pooled[i] += vec[i];
      }
    }
    
    return pooled.map(v => v / chunkVectors.length);
  }

  private async fetchEmbedding(prompt: string): Promise<number[]> {
    const response = await fetch(`${this.baseUrl}/api/embeddings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: this.model, prompt }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Ollama API error: ${error}`);
    }

    const data = await response.json() as { embedding: number[] };
    
    // Auto-detect dimensions dynamically
    if (!this._dimensionsDetected && data.embedding.length > 0) {
      this.dimensions = data.embedding.length;
      this._dimensionsDetected = true;
    }

    return data.embedding;
  }

  /**
   * [ADVANCED RAG] Context Scoring Placeholder
   * ระบบประเมิน 'ความเข้มข้น' ของข้อมูล เพื่อเตรียมการสำหรับวิชา Advanced RAG
   * ประเมินจาก Semantic Density และความสมบูรณ์ของบริบท
   */
  public scoreContext(text: string, embedding: number[]): number {
    // Placeholder: ในอนาคตจะใช้ AI ตรวจสอบความสอดคล้อง (Relevance) 
    // และความหนาแน่นของเอนทิตี (Entity Density)
    const lengthFactor = Math.min(text.length / 1000, 1.0);
    const vectorMagnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
    return (lengthFactor + vectorMagnitude) / 2;
  }
}

/**
 * OpenAI embeddings via API
 */
export class OpenAIEmbeddings implements EmbeddingProvider {
  readonly name = 'openai';
  readonly dimensions: number;
  private apiKey: string;
  private model: string;

  constructor(config: { apiKey?: string; model?: string } = {}) {
    this.apiKey = config.apiKey || process.env.OPENAI_API_KEY || '';
    this.model = config.model || 'text-embedding-3-small';
    this.dimensions = this.model === 'text-embedding-3-large' ? 3072 : 1536;

    if (!this.apiKey) {
      throw new Error('OpenAI API key required. Set OPENAI_API_KEY.');
    }
  }

  async embed(texts: string[]): Promise<number[][]> {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ input: texts, model: this.model }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const data = await response.json() as {
      data: { embedding: number[]; index: number }[];
    };

    return data.data
      .sort((a, b) => a.index - b.index)
      .map(d => d.embedding);
  }
}

/**
 * Create embedding provider from type string
 */
export function createEmbeddingProvider(
  type: EmbeddingProviderType = 'chromadb-internal',
  model?: string
): EmbeddingProvider {
  switch (type) {
    case 'ollama':
      return new OllamaEmbeddings({ model });
    case 'openai':
      return new OpenAIEmbeddings({ model });
    case 'cloudflare-ai': {
      // Dynamic import to avoid requiring CF credentials when not used
      const { CloudflareAIEmbeddings } = require('./adapters/cloudflare-vectorize.ts');
      return new CloudflareAIEmbeddings({ model });
    }
    case 'chromadb-internal':
    default:
      return new ChromaDBInternalEmbeddings();
  }
}
