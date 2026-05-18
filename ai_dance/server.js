const http = require("node:http");
const fsSync = require("node:fs");
const fs = require("node:fs/promises");
const path = require("node:path");
const { Readable } = require("node:stream");

loadEnvFile();

const PORT = Number(process.env.PORT || 5173);
const RUNWAY_API_BASE = "https://api.dev.runwayml.com";
const RUNWAY_API_VERSION = "2024-11-06";
const PUBLIC_DIR = __dirname;

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".md": "text/markdown; charset=utf-8",
};

const server = http.createServer(async (req, res) => {
  try {
    setCors(res);

    if (req.method === "OPTIONS") {
      res.writeHead(204);
      res.end();
      return;
    }

    const url = new URL(req.url, `http://${req.headers.host}`);

    if (req.method === "POST" && url.pathname === "/api/generate") {
      await handleGenerate(req, res);
      return;
    }

    if (req.method === "GET" && url.pathname.startsWith("/api/jobs/")) {
      await handleJob(url.pathname.split("/").pop(), res);
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/health") {
      sendJson(res, 200, {
        ok: true,
        runwayConfigured: Boolean(getRunwaySecret()),
      });
      return;
    }

    if (req.method === "GET") {
      await serveStatic(url.pathname, res);
      return;
    }

    sendJson(res, 405, { error: "Method not allowed" });
  } catch (error) {
    console.error(error);
    sendJson(res, error.status || 500, { error: error.message || "Server error" });
  }
});

server.listen(PORT, () => {
  console.log(`DanceFrame Studio running at http://localhost:${PORT}`);
});

function loadEnvFile() {
  const envPath = path.join(__dirname, ".env");
  if (!fsSync.existsSync(envPath)) return;
  const text = fsSync.readFileSync(envPath, "utf8");
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) continue;
    const index = trimmed.indexOf("=");
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim().replace(/^['"]|['"]$/g, "");
    if (key && process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

async function handleGenerate(req, res) {
  ensureRunwaySecret();

  const form = await readMultipartForm(req);
  const photo = form.get("photo");
  const dance = form.get("dance");
  const ratio = normalizeRatio(form.get("ratio"));
  const motion = Number(form.get("motion") || 72);

  if (!photo || !dance) {
    throw httpError(400, "请上传人物全身照和参考舞蹈视频。");
  }

  const [characterUri, referenceUri] = await Promise.all([
    uploadToRunway(photo),
    uploadToRunway(dance),
  ]);

  const task = await runwayFetch("/v1/character_performance", {
    method: "POST",
    body: JSON.stringify({
      model: "act_two",
      character: {
        type: "image",
        uri: characterUri,
      },
      reference: {
        type: "video",
        uri: referenceUri,
      },
      bodyControl: true,
      expressionIntensity: normalizeExpressionIntensity(motion),
      ratio,
    }),
  });

  sendJson(res, 200, task);
}

async function handleJob(id, res) {
  ensureRunwaySecret();
  if (!id) throw httpError(400, "缺少 Runway 任务 ID。");
  const task = await runwayFetch(`/v1/tasks/${encodeURIComponent(id)}`, {
    method: "GET",
  });
  sendJson(res, 200, task);
}

async function uploadToRunway(file) {
  const upload = await runwayFetch("/v1/uploads", {
    method: "POST",
    body: JSON.stringify({
      filename: file.name || "upload.bin",
      type: "ephemeral",
    }),
  });

  const uploadForm = new FormData();
  for (const [key, value] of Object.entries(upload.fields)) {
    uploadForm.append(key, value);
  }
  uploadForm.append("file", file, file.name || "upload.bin");

  const response = await fetch(upload.uploadUrl, {
    method: "POST",
    body: uploadForm,
  });

  if (!response.ok) {
    const text = await response.text();
    throw httpError(response.status, `上传素材到 Runway 失败：${text || response.statusText}`);
  }

  return upload.runwayUri;
}

async function runwayFetch(endpoint, options) {
  const response = await fetch(`${RUNWAY_API_BASE}${endpoint}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${getRunwaySecret()}`,
      "Content-Type": "application/json",
      "X-Runway-Version": RUNWAY_API_VERSION,
      ...(options.headers || {}),
    },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw httpError(response.status, data.error || data.message || `Runway API 请求失败：${response.status}`);
  }
  return data;
}

async function readMultipartForm(req) {
  const request = new Request(`http://${req.headers.host}${req.url}`, {
    method: req.method,
    headers: req.headers,
    body: Readable.toWeb(req),
    duplex: "half",
  });
  return request.formData();
}

async function serveStatic(pathname, res) {
  const safePath = pathname === "/" ? "/index.html" : decodeURIComponent(pathname);
  const filePath = path.normalize(path.join(PUBLIC_DIR, safePath));
  if (!filePath.startsWith(PUBLIC_DIR)) {
    throw httpError(403, "Forbidden");
  }

  try {
    const content = await fs.readFile(filePath);
    res.writeHead(200, {
      "Content-Type": MIME_TYPES[path.extname(filePath)] || "application/octet-stream",
    });
    res.end(content);
  } catch {
    sendJson(res, 404, { error: "Not found" });
  }
}

function normalizeRatio(value) {
  const map = {
    "16:9": "1280:720",
    "9:16": "720:1280",
    "1:1": "960:960",
  };
  return map[value] || "720:1280";
}

function normalizeExpressionIntensity(motion) {
  return Math.max(1, Math.min(5, Math.round((motion / 100) * 5)));
}

function getRunwaySecret() {
  return process.env.RUNWAYML_API_SECRET || process.env.RUNWAY_API_KEY || "";
}

function ensureRunwaySecret() {
  if (!getRunwaySecret()) {
    throw httpError(500, "缺少 RUNWAYML_API_SECRET。请先在环境变量中配置 Runway API Key。");
  }
}

function setCors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
}

function sendJson(res, status, payload) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

function httpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}
