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

// const userAddons = {
//   mia: [
//     // {
//     //   id: "torrentio",
//     //   name: "Torrentio",
//     //   manifestUrl:
//     //     "https://torrentio.strem.fun/torbox=1b52e4c1-64cf-47bb-bd51-9924b18eb88f/manifest.json",
//     //   icon: "https://torrentio.strem.fun/images/logo_v1.png",
//     //   enabledResources: ["stream"],
//     //   config: {},
//     // },

//     {
//       id: "comet",
//       name: "Comet",
//       manifestUrl:
//         "https://comet.elfhosted.com/eyJtYXhSZXN1bHRzUGVyUmVzb2x1dGlvbiI6MCwibWF4U2l6ZSI6MCwiY2FjaGVkT25seSI6ZmFsc2UsInNvcnRDYWNoZWRVbmNhY2hlZFRvZ2V0aGVyIjpmYWxzZSwicmVtb3ZlVHJhc2giOnRydWUsInJlc3VsdEZvcm1hdCI6WyJhbGwiXSwiZGVicmlkU2VydmljZSI6InRvcmJveCIsImRlYnJpZEFwaUtleSI6IjFiNTJlNGMxLTY0Y2YtNDdiYi1iZDUxLTk5MjRiMThlYjg4ZiIsImRlYnJpZFN0cmVhbVByb3h5UGFzc3dvcmQiOiIiLCJsYW5ndWFnZXMiOnsiZXhjbHVkZSI6W10sInByZWZlcnJlZCI6WyJlbiJdfSwicmVzb2x1dGlvbnMiOnt9LCJvcHRpb25zIjp7InJlbW92ZV9yYW5rc191bmRlciI6LTEwMDAwMDAwMDAwLCJhbGxvd19lbmdsaXNoX2luX2xhbmd1YWdlcyI6ZmFsc2UsInJlbW92ZV91bmtub3duX2xhbmd1YWdlcyI6ZmFsc2V9fQ==/manifest.json",
//       icon: "https://i.imgur.com/jmVoVMu.jpeg",
//       enabledResources: ["stream"],
//       config: {},
//     },

//     {
//       id: "com.linvo.cinemeta",
//       name: "Cinemeta",
//       manifestUrl: "https://v3-cinemeta.strem.io/manifest.json",
//       enabledResources: ["catalog"],
//       config: {},
//     },
//   ],
// };

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

app.get("/hls/:segment", (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

  const id = crypto.createHash("md5").update(raw).digest("hex");

  const dir = path.join(streamsDir, id);

  const segment = req.query.segment; // e.g., "master10.ts"
  const start = parseInt(segment.replace("master", "")) * 4; // 4s segments



  const filePath = `${dir}/${segment}`;
  console.log(`Request for ${filePath}`);
  if (fs.existsSync(filePath)) {
    console.log(`${filePath} already exists.`)
    return res.json({ streamUrl: `/streams/${id}/${segment}` });
  }

  fs.mkdirSync(dir, { recursive: true });

  // Spawn FFmpeg to generate only this segment
  const ffmpeg = spawn("ffmpeg", [
    "-ss",
    start.toString(),
    "-i",
    raw,
    "-t",
    "4",
    "-c:v",
    "libx264",
    "-c:a",
    "aac",
    filePath,
  ]);

  ffmpeg.on("close", (code) => {
    // res.sendFile(filePath);
    res.json({ streamUrl: `/streams/${id}/${segment}` });
  });
});

// HLS transcoding endpoint
app.get("/transcode", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

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
    "-f",
    "hls",
    "-hls_playlist_type",
    "event",
    "-hls_list_size",
    "0",
    masterPlaylist,
  ];

  const probeargs = [
    "-select_streams", "v:0",
    "-show_entries",
    "stream=index,codec_name,codec_type,width,height",
    "-of", "json",
    raw
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
