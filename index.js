const http = require('node:http');
const { readFile } = require('node:fs/promises');
const path = require('node:path');

http.createServer(async (request, response) => {
    if (request.url !== '/') {
        response.writeHead(404).end();
        return;
    }

    try {
        const html = await readFile(path.join(__dirname, 'index.html'));
        response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        response.end(html);
    } catch {
        response.writeHead(500).end('Build output unavailable');
    }
}).listen(3000, '127.0.0.1');
