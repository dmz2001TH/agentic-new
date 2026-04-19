import { startServer } from './src/core/server.ts';
import { loadConfig } from './src/config/load.ts';

const config = loadConfig();
const port = Number(process.env.MAW_PORT || config.port || 3456);

console.log(`🚀 Starting MAW Server on port ${port}...`);
await startServer(port);
