import { createReadStream, existsSync, statSync } from "fs";
import { extname, join, normalize, resolve } from "path";
import { createServer } from "http";

const root = resolve("_site");
const port = Number(process.env.PORT || 4000);

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".gif": "image/gif",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
  ".webp": "image/webp",
  ".xml": "application/xml; charset=utf-8"
};

function sendFile(filePath, res) {
  const type = contentTypes[extname(filePath).toLowerCase()] || "application/octet-stream";
  res.writeHead(200, { "Content-Type": type });
  createReadStream(filePath).pipe(res);
}

function notFound(res) {
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("Not found");
}

if (!existsSync(root)) {
  console.error("Build output not found. Run `npm run build` first.");
  process.exit(1);
}

const server = createServer((req, res) => {
  const requestPath = new URL(req.url || "/", "http://127.0.0.1").pathname;
  const safePath = normalize(decodeURIComponent(requestPath)).replace(/^(\.\.[/\\])+/, "");
  let filePath = join(root, safePath);

  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(filePath, "index.html");
  } else if (!existsSync(filePath) && existsSync(`${filePath}.html`)) {
    filePath = `${filePath}.html`;
  }

  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    return notFound(res);
  }

  sendFile(filePath, res);
});

server.listen(port, () => {
  console.log(`Previewing _site at http://127.0.0.1:${port}`);
});
