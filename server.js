import express from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { PrismaClient } from "@prisma/client";
import { computeRoundStatus, getRoundWindow } from "./lib/rounds.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const prisma = new PrismaClient();

const ROUND_CLOSE_HOUR_UTC = Number(process.env.ROUND_CLOSE_HOUR_UTC || 18);
let roundCache = { at: 0, round: null };

let APP_VERSION = "unknown";
try {
  const pkgRaw = fs.readFileSync(path.join(__dirname, "package.json"), "utf8");
  const pkg = JSON.parse(pkgRaw);
  APP_VERSION = pkg.version || APP_VERSION;
} catch (err) {
  console.warn("Unable to read package.json version", err);
}

let GIT_SHA = process.env.GIT_SHA || "unknown";
try {
  const headPath = path.join(__dirname, ".git", "HEAD");
  if (fs.existsSync(headPath)) {
    const head = fs.readFileSync(headPath, "utf8").trim();
    if (head.startsWith("ref:")) {
      const refPath = head.replace("ref:", "").trim();
      const refFile = path.join(__dirname, ".git", refPath);
      if (fs.existsSync(refFile)) {
        const ref = fs.readFileSync(refFile, "utf8").trim();
        if (ref) GIT_SHA = ref;
      }
    } else if (head) {
      GIT_SHA = head;
    }
  }
} catch (err) {
  console.warn("Unable to read git sha", err);
}

const STARTED_AT = new Date().toISOString();

const app = express();
app.use(express.json({ limit: "1mb" }));

const PORT = process.env.PORT || 3000;
const CREWMIND_API_BASE = process.env.CREWMIND_API_BASE || "https://data.crewmind.xyz";
const BASE_URL = process.env.BASE_URL || "https://crewdegen.com";
const AGENT_API_KEY = process.env.AGENT_API_KEY || "";

function requireAgentKey(req, res, next) {
  if (!AGENT_API_KEY) return next();
  const provided = req.headers["x-api-key"];
  const key = Array.isArray(provided) ? provided[0] : provided;
  if (!key || key !== AGENT_API_KEY) {
    return res.status(401).json({ error: "unauthorized" });
  }
  return next();
}

// --- helpers ---
async function proxyRequest(req, res, targetPath) {
  try {
    const url = new URL(CREWMIND_API_BASE + targetPath);
    // forward query params
    for (const [k, v] of Object.entries(req.query || {})) {
      url.searchParams.set(k, v);
    }

    const headers = {};
    if (req.headers.authorization) headers["authorization"] = req.headers.authorization;
    if (req.headers["content-type"]) headers["content-type"] = req.headers["content-type"];

    const fetchOpts = {
      method: req.method,
      headers,
    };

    if (req.method !== "GET" && req.method !== "HEAD") {
      fetchOpts.body = JSON.stringify(req.body ?? {});
      headers["content-type"] = "application/json";
    }

    const resp = await fetch(url.toString(), fetchOpts);
    const contentType = resp.headers.get("content-type") || "application/json";
    res.status(resp.status);
    res.setHeader("content-type", contentType);

    if (contentType.includes("application/json")) {
      const data = await resp.json();
      return res.send(data);
    }
    const text = await resp.text();
    return res.send(text);
  } catch (err) {
    return res.status(500).json({ error: "proxy_failed", details: String(err) });
  }
}

async function ensureRound(now = new Date()) {
  const status = computeRoundStatus(now, ROUND_CLOSE_HOUR_UTC);
  const { activeStart, activeEnd } = getRoundWindow(now, ROUND_CLOSE_HOUR_UTC);
  let round = await prisma.round.findFirst({ where: { startTime: activeStart } });
  if (!round) {
    round = await prisma.round.create({
      data: {
        startTime: activeStart,
        endTime: activeEnd,
        status,
      },
    });
  } else if (round.status !== status) {
    round = await prisma.round.update({ where: { id: round.id }, data: { status } });
  }
  return round;
}

async function getRoundCached() {
  const now = Date.now();
  if (roundCache.round && now - roundCache.at < 60000) return roundCache.round;
  const round = await ensureRound(new Date());
  roundCache = { at: now, round };
  return round;
}

function requireRoundStatus(allowed) {
  return async (req, res, next) => {
    try {
      const round = await getRoundCached();
      if (!allowed.includes(round.status)) {
        return res.status(403).json({ error: "round_inactive", status: round.status });
      }
      next();
    } catch (err) {
      return res.status(500).json({ error: "round_status_failed" });
    }
  };
}

// cron-like updater
setInterval(() => {
  ensureRound(new Date()).catch(() => null);
}, 5 * 60 * 1000);

// --- public endpoints ---
app.get("/api/health", async (req, res) => {
  let roundStatus = "unknown";
  try {
    const round = await getRoundCached();
    roundStatus = round?.status || "unknown";
  } catch {}
  res.json({
    ok: true,
    version: APP_VERSION,
    gitSha: GIT_SHA,
    uptimeSec: Math.round(process.uptime()),
    startedAt: STARTED_AT,
    now: new Date().toISOString(),
    crewmindBase: CREWMIND_API_BASE,
    roundStatus,
  });
});

// CrewMind public data proxies
app.get("/api/rounds/status", async (req, res) => {
  try {
    const round = await getRoundCached();
    res.json({
      status: round.status,
      startTime: round.startTime,
      endTime: round.endTime,
      roundId: round.id,
    });
  } catch (err) {
    res.status(500).json({ error: "round_status_failed" });
  }
});

app.get("/api/shuttles/prices", (req, res) => proxyRequest(req, res, "/api/shuttles/prices"));
app.get("/api/shuttles/summaries", (req, res) => proxyRequest(req, res, "/api/shuttles/summaries"));
app.get("/api/shuttles/price-history", (req, res) => proxyRequest(req, res, "/api/shuttles/price-history"));
app.get("/api/shuttles/all", (req, res) => proxyRequest(req, res, "/api/shuttles/all"));
app.get("/api/shuttles/:id/snapshot", (req, res) => proxyRequest(req, res, `/api/shuttles/${req.params.id}/snapshot`));
app.get("/api/shuttles/:id/history", (req, res) => proxyRequest(req, res, `/api/shuttles/${req.params.id}/history`));
app.get("/api/shuttles/:id/decisions", (req, res) => proxyRequest(req, res, `/api/shuttles/${req.params.id}/decisions`));

// Auth + setup proxies (require wallet signature from client)
app.get("/api/auth/check", (req, res) => proxyRequest(req, res, "/api/auth/check"));
app.get("/api/auth/nonce", (req, res) => proxyRequest(req, res, "/api/auth/nonce"));
app.post("/api/auth/register", (req, res) => proxyRequest(req, res, "/api/auth/register"));
app.post("/api/auth/login", (req, res) => proxyRequest(req, res, "/api/auth/login"));
app.get("/api/auth/me", (req, res) => proxyRequest(req, res, "/api/auth/me"));

app.get("/api/shuttles/check-balance", (req, res) => proxyRequest(req, res, "/api/shuttles/check-balance"));
app.get("/api/shuttles/check-setup", (req, res) => proxyRequest(req, res, "/api/shuttles/check-setup"));
app.get("/api/shuttles/drift-accounts", (req, res) => proxyRequest(req, res, "/api/shuttles/drift-accounts"));
app.post("/api/shuttles/build-setup-tx", requireAgentKey, (req, res) => proxyRequest(req, res, "/api/shuttles/build-setup-tx"));
app.post("/api/shuttles/send-setup-tx", requireAgentKey, (req, res) => proxyRequest(req, res, "/api/shuttles/send-setup-tx"));
app.post(
  "/api/shuttles/create",
  requireAgentKey,
  requireRoundStatus(["registration", "active"]),
  (req, res) => proxyRequest(req, res, "/api/shuttles/create")
);
app.post(
  "/api/shuttles/:id/decision",
  requireAgentKey,
  requireRoundStatus(["active"]),
  (req, res) => proxyRequest(req, res, `/api/shuttles/${req.params.id}/decision`)
);
app.post("/api/shuttles/:id/toggle", requireAgentKey, (req, res) => proxyRequest(req, res, `/api/shuttles/${req.params.id}/toggle`));

// Skill file for agents
const SKILL_PATH = path.join(__dirname, "public", "skill.md");
app.get(["/skill.md", "/skill"], (req, res) => {
  res.setHeader("content-type", "text/markdown; charset=utf-8");
  try {
    const md = fs.readFileSync(SKILL_PATH, "utf8");
    res.send(md);
  } catch (err) {
    res.status(500).send("skill.md not found");
  }
});

// static UI
app.use(express.static(path.join(__dirname, "public")));

// SPA fallback
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, () => {
  console.log(`CrewDegen Arena listening on :${PORT}`);
});
