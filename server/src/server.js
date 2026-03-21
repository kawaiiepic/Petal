// server.js
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import Database from "better-sqlite3";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import cookieParser from "cookie-parser";

// var token = jwt.sign({ foo: "bar" }, "shhhhh");
var old_token = jwt.sign(
  { foo: "bar", iat: Math.floor(Date.now() / 1000) - 30 },
  "boop",
);

const db = new Database("database.db");

const CLIENT_ID =
  "0a4b47986a50894f19f24aad11101514993592db3c9a63e12e2d573504e1adbb";
const CLIENT_SECRET =
  "4640a2e220cc5e8a0eebf692389d28cd542b92e893850d0e737456835c85a4b5";
const _header = {
  "Content-Type": "application/json",
};

setupDb();

const app = express();
const port = 3000;

app.use(cors());
app.use(cookieParser());
app.use(bodyParser.json());

app.get("/trakt/deviceCode", async function (req, res) {
  const response = await fetch("https://api.trakt.tv/oauth/device/code", {
    method: "POST",
    headers: _header,
    body: JSON.stringify({ client_id: CLIENT_ID }),
  });

  if (response.status == 200) {
    console.log(response);

    res.json(await response.text());
  }
});

app.get("/", function (req, res) {
  // Cookies that have not been signed
  console.log("Cookies: ", req.cookies);

  // Cookies that have been signed
  console.log("Signed Cookies: ", req.signedCookies);

  res.cookie("name", "tobi");

  res.json({ test: "test" });
});

function setupDb() {
  // enable WAL mode (important for performance)
  db.pragma("journal_mode = WAL");
  db.pragma("synchronous = NORMAL");
  db.pragma("temp_store = MEMORY");

  // users
  db.prepare(
    `
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    created_at INTEGER
  )
  `,
  ).run();

  // user addons
  db.prepare(
    `
    CREATE TABLE IF NOT EXISTS addons (
      user_id TEXT,
      id TEXT,
      name TEXT,
      manifest_url TEXT,
      icon TEXT,
      enabled_resources TEXT,
      forced INTEGER,
      config TEXT,
      PRIMARY KEY (user_id, id),
      FOREIGN KEY(user_id) REFERENCES users(id)
    )
  `,
  ).run();

  // image cache
  db.prepare(
    `
  CREATE TABLE IF NOT EXISTS image_cache (
    url TEXT PRIMARY KEY,
    content_type TEXT,
    cached_at INTEGER
  )
  `,
  ).run();

  // stream sessions
  db.prepare(
    `
  CREATE TABLE IF NOT EXISTS streams (
    id TEXT PRIMARY KEY,
    source_url TEXT,
    directory TEXT,
    created_at INTEGER,
    last_access INTEGER
  )
  `,
  ).run();

  setInterval(
    () => {
      const cutoff = Date.now() - 1000 * 60 * 60 * 6; // 6 hours

      const old = db
        .prepare(
          `
      SELECT * FROM streams WHERE last_access < ?
    `,
        )
        .all(cutoff);

      for (const stream of old) {
        fs.rmSync(stream.directory, { recursive: true, force: true });

        db.prepare("DELETE FROM streams WHERE id = ?").run(stream.id);
      }
    },
    1000 * 60 * 60,
  );
}

// Trakt Specific

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/verify", (_, res) => {
  jwt.verify(old_token, "shhhhh", function (err, decoded) {
    if (err) {
      res.json({ error: "Expired" });
    }
    res.json({ result: decoded.foo });
    console.log(decoded.foo); // bar
  });
});

// simple in-memory cache
const imageCache = new Map();

// Image proxy with decoding + caching
app.get("/img", async (req, res) => {
  try {
    const raw = req.query.url;
    if (!raw) return res.status(400).send("Missing url");

    const url = decodeURIComponent(raw);

    // serve cached
    if (imageCache.has(url)) {
      const cached = imageCache.get(url);
      res.set("Content-Type", cached.type);
      res.set("Cache-Control", "public, max-age=86400");
      return res.send(cached.buffer);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000); // 20s

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        "User-Agent": "Mozilla/5.0",
      },
    });

    clearTimeout(timeout);
    if (!response.ok) return res.status(response.status).send("Upstream error");

    const buffer = Buffer.from(await response.arrayBuffer());
    const contentType = response.headers.get("content-type") || "image/jpeg";

    imageCache.set(url, { buffer, type: contentType });

    res.set("Content-Type", contentType);
    res.set("Cache-Control", "public, max-age=86400");

    res.send(buffer);
  } catch (err) {
    console.error("Image proxy error:", err);
    res.status(500).send("Proxy error");
  }
});

// Save addons for a user
app.post("/addons", (req, res) => {
  const { userId, addons } = req.body;

  if (!userId || !addons) {
    return res.status(400).json({ error: "Missing data" });
  }

  console.log("Saving addons for user:", userId);

  db.prepare(
    `
    INSERT OR IGNORE INTO users (id, created_at)
    VALUES (?, ?)
  `,
  ).run(userId, Date.now());

  const insert = db.prepare(`
    INSERT OR REPLACE INTO addons
    (id, user_id, name, manifest_url, icon, enabled_resources, forced, config)
    VALUES (?,?, ?, ?, ?, ?, ?, ?)
  `);

  const tx = db.transaction(() => {
    for (const addon of addons) {
      insert.run(
        addon.id,
        userId,
        addon.name,
        addon.manifestUrl,
        addon.icon || "",

        JSON.stringify(addon.enabledResources || []),
        addon.forced,
        JSON.stringify(addon.config || {}),
      );
    }
  });

  tx();

  res.json({ success: true });
});

// Get addons for a user
app.get("/addons/:userId", (req, res) => {
  console.log("Fetching addons for user:", req.params.userId);
  const rows = db
    .prepare(
      `
    SELECT * FROM addons WHERE user_id = ?
  `,
    )
    .all(req.params.userId);

  const addons = rows.map((r) => ({
    id: r.id,
    name: r.name,
    manifestUrl: r.manifest_url,
    icon: r.icon,
    enabledResources: JSON.parse(r.enabled_resources),
    forced: 0,
    config: JSON.parse(r.config),
  }));

  addons.push({
    id: "com.linvo.cinemeta",
    name: "Cinemeta",
    manifestUrl: "https://v3-cinemeta.strem.io/manifest.json",
    enabledResources: ["catalog"],
    forced: 1,
    config: {},
  });

  addons.push({
    id: "org.stremio.watchhub",
    name: "WatchHub",
    manifestUrl: "https://watchhub.strem.io/manifest.json",
    enabledResources: ["stream"],
    forced: 1,
    config: {},
  });

  res.json({ addons });
});

import { spawn } from "child_process";
import fs from "fs";
import path from "path";

const streamsDir = "/tmp/petal-streams";
fs.mkdirSync(streamsDir, { recursive: true });

// HLS transcoding endpoint
app.get("/transcode", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

  console.log("transcoding");

  const id = crypto.createHash("md5").update(raw).digest("hex");

  const dir = path.join(streamsDir, id);

  // if (fs.existsSync(dir)) {
  //   db.prepare(
  //     `
  //   UPDATE streams SET last_access = ?
  //   WHERE id = ?
  //   `,
  //   ).run(Date.now(), id);

  //   console.log("Stream already exists");
  //   res.json({ streamUrl: `/streams/${id}/master.m3u8` });
  //   return;
  // }

  db.prepare(
    `
  INSERT OR REPLACE INTO streams
  (id, source_url, directory, created_at, last_access)
  VALUES (?, ?, ?, ?, ?)
  `,
  ).run(id, raw, dir, Date.now(), Date.now());

  // if (fs.existsSync(dir)) {
  //   fs.rmSync(dir, { recursive: true });
  // }

  fs.mkdirSync(dir, { recursive: true });

  const masterPlaylist = path.join(dir, "master.m3u8");

  const args = [
    "-i",
    raw,
    "-c:v",
    "copy",
    "-c:a",
    "aac", // only transcode audio
    "-b:a",
    "128k",

    "-f",
    "hls",
    "-hls_time",
    "6",
    "-hls_list_size",
    "0",
    "-hls_playlist_type",
    "event",
    "-hls_segment_filename",
    path.join(dir, "segment_%03d.ts"),

    masterPlaylist,
  ];

  const probeargs = [
    "-select_streams",
    "v:0",
    "-show_entries",
    "stream=index,codec_name,codec_type,width,height",
    "-of",
    "json",
    raw,
  ];

  console.log(masterPlaylist);

  // const ffprobe = spawn("ffprobe", probeargs);
  // ffprobe.stderr.on("data", (d) => console.log("ffprobe:", d.toString()));
  // ffprobe.on("error", console.error);

  const proc = spawn("ffmpeg", args);
  proc.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
  proc.on("error", console.error);

  await new Promise((resolve, reject) => {
    const check = () => {
      if (fs.existsSync(masterPlaylist)) return resolve();

      setTimeout(check, 200);
    };

    check();
  });
  res.json({ streamUrl: `/streams/${id}/master.m3u8` });
});

app.use("/streams", express.static(streamsDir));

app.listen(port, () => {
  console.log(`Backend server running at 0.0.0.0:${port}`);
});
