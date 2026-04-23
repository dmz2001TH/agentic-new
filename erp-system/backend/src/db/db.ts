import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema';

const sqlite = new Database('sqlite.db');
export const db = drizzle(sqlite, { schema });

// Initial Migration (Manual check for simple dev)
// In a real app, we'd use drizzle-kit push
console.log('Database connected!');
