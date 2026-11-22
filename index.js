const http = require('node:http');
const { readFile } = require('node:fs/promises');
const path = require('node:path');
const { Pool } = require('pg');

const database = process.env.PGHOST
    ? new Pool({ connectionTimeoutMillis: 2000, query_timeout: 2000 })
    : null;

database?.on('error', error => console.error('PostgreSQL connection error:', error.message));

const server = http.createServer(async (request, response) => {
    if (request.url === '/healthz') {
        try {
            if (database) await database.query('SELECT 1');
            response.writeHead(200).end(database ? 'postgresql: ok' : 'ok');
        } catch {
            response.writeHead(503).end('Database unavailable');
        }
        return;
    }

    if (request.url !== '/') {
        response.writeHead(404).end();
        return;
    }

    try {
        const html = await readFile(path.join(__dirname, 'dist', 'index.html'));
        response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(html);
    } catch {
        response.writeHead(500).end('Build output unavailable');
    }
});

async function start() {
    if (database) {
        await database.query('SELECT 1');
        console.log('Connected to PostgreSQL');
    }
    server.listen(3000, '0.0.0.0');
}

start().catch(error => {
    console.error('Application startup failed:', error.message);
    process.exitCode = 1;
});
