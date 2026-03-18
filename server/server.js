// server.js
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import Database from "better-sqlite3";
import crypto from "crypto";

const db = new Database("database.db");

setupDb();

const app = express();
const port = 3000;

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

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
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

    const response = await fetch(url);
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

  const id = crypto.createHash("md5").update(raw).digest("hex");

  const dir = path.join(streamsDir, id);

  if (fs.existsSync(dir)) {
    db.prepare(
      `
    UPDATE streams SET last_access = ?
    WHERE id = ?
    `,
    ).run(Date.now(), id);

    console.log("Stream already exists");
    res.json({ streamUrl: `/streams/${id}/master.m3u8` });
    return;
  }

  db.prepare(
    `
  INSERT OR REPLACE INTO streams
  (id, source_url, directory, created_at, last_access)
  VALUES (?, ?, ?, ?, ?)
  `,
  ).run(id, raw, dir, Date.now(), Date.now());

  fs.mkdirSync(dir, { recursive: true });
  const masterPlaylist = path.join(dir, "master.m3u8");

  const spawnFfmpeg = (mode = "copy") => {
    const args = [
      "-loglevel", "warning", "-i", raw];

    if (mode === "copy") {
      args.push("-c:v", "copy");
    } else {
      console.log("Falling back to full video transcode…");
      args.push("-c:v", "libx264", "-preset", "medium", "-crf", "23");
    }

    args.push("-c:a", "aac", "-b:a", "128k", "-tag:v", "hvc1", masterPlaylist);

    const proc = spawn("ffmpeg", args);
    proc.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
    proc.on("error", console.error);
    proc.on("exit", (code) => {
      if (code !== 0 && mode === "copy") spawnFfmpeg("transcode");
    });
    return proc;
  };

  const ffmpeg = spawnFfmpeg("copy");

  res.json({ streamUrl: `/streams/${id}/master.m3u8` });
});

app.use("/streams", express.static(streamsDir));

app.listen(port, () => {
  console.log(`Backend server running at 0.0.0.0:${port}`);
});
