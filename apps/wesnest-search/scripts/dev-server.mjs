// scripts/dev-server.mjs
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import handler from '../api/search.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_DIR = path.resolve(__dirname, '..');
const PORT = Number(process.env.PORT) || 3000;

if (typeof process.loadEnvFile === 'function') {
  const envPath = path.join(APP_DIR, '.env');
  if (existsSync(envPath)) {
    process.loadEnvFile(envPath);
  }
}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
};

export function createDevApp() {
  return createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.statusCode = 204;
      res.end();
      return;
    }

    const host = req.headers.host || 'localhost';
    const parsedUrl = new URL(req.url, `http://${host}`);

    if (parsedUrl.pathname === '/api/search') {
      if (req.method !== 'POST') {
        res.statusCode = 405;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ error: 'Method not allowed' }));
        return;
      }

      let bodyText = '';
      req.on('data', (chunk) => {
        bodyText += chunk;
      });

      req.on('end', async () => {
        try {
          const body = bodyText ? JSON.parse(bodyText) : {};
          const vercelRes = {
            statusCode: 200,
            status(code) {
              this.statusCode = code;
              return this;
            },
            json(data) {
              res.statusCode = this.statusCode;
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify(data));
            },
          };
          const vercelReq = {
            method: req.method,
            body,
            headers: req.headers,
            url: req.url,
          };
          await handler(vercelReq, vercelRes);
        } catch (err) {
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ error: 'Internal Server Error', message: err.message }));
        }
      });
      return;
    }

    let filePath = parsedUrl.pathname === '/' ? '/index.html' : parsedUrl.pathname;
    const safePath = path.normalize(filePath).replace(/^(\.\.[/\\])+/, '');
    const absolutePath = path.join(APP_DIR, safePath);

    try {
      const data = await readFile(absolutePath);
      const ext = path.extname(absolutePath).toLowerCase();
      res.setHeader('Content-Type', MIME_TYPES[ext] || 'application/octet-stream');
      res.statusCode = 200;
      res.end(data);
    } catch {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain');
      res.end('Not Found');
    }
  });
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  const server = createDevApp();
  server.listen(PORT, () => {
    console.log(`WesNest Search dev server running at http://localhost:${PORT}`);
    if (!process.env.GEMINI_API_KEY) {
      console.warn('Notice: GEMINI_API_KEY not set. Running in keyword-fallback mode.');
    }
  });
}
