import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
// import Database from "better-sqlite3";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import cookieParser from "cookie-parser";
import { spawn } from "child_process";
import fs from "fs";
import path from "path";

import { Trakt } from "./trakt.js";
import { DB } from "./db.js";

const streamsDir = "/tmp/petal-streams";
fs.mkdirSync(streamsDir, { recursive: true });

const app = express();
const port = 3000;

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST"],
  }),
);
app.use(bodyParser.json());
app.use(cookieParser());

DB.init();

Trakt.deviceCode(app);
Trakt.pollForAccessToken(app);
Trakt.verifySession(app);
Trakt.obtainUserProfile(app);
Trakt.obtainLastActivities(app);
Trakt.search(app);
Trakt.startWatching(app);
Trakt.obtainWatched(app);
Trakt.obtainShow(app);
Trakt.obtainMovie(app);
Trakt.obtainSeasons(app);
Trakt.obtainShowProgress(app);


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

    const url = decodeURIComponent(raw as string);

    // serve cached
    // if (imageCache.has(url)) {
    //   const cached = imageCache.get(url);
    //   res.set("Content-Type", cached.type);
    //   res.set("Cache-Control", "public, max-age=86400");
    //   return res.send(cached.buffer);
    // }

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
app.post("/addons/set", (req, res) => {
  console.log(req.body);
  const addons = req.body.addons;

  if (!addons) {
    return res.status(400).json({ error: "Missing data" });
  }

  console.log("Saving addon.");

   var username = (Trakt.verifyToken(req.cookies.token) as jwt.JwtPayload).username;

  console.log("Saving addons for user:", username);

  const insert = DB.db.prepare(`
    INSERT OR REPLACE INTO addons
    (id, username, name, manifest_url, icon, enabled_resources, forced, config)
    VALUES (?,?, ?, ?, ?, ?, ?, ?)
  `);

  const tx = DB.db.transaction(() => {
    for (const addon of addons) {
      insert.run(
        addon.id,
        username,
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
app.get("/addons/get", (req, res) => {
  var username = (Trakt.verifyToken(req.cookies.token) as jwt.JwtPayload)
    .username;
  console.log("Fetching addons for user:", username);
  const rows = DB.db
    .prepare(
      `
    SELECT * FROM addons WHERE username = ?
  `,
    )
    .all(username);

  const addons = rows.map((r: any) => ({
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
    icon: "",
    manifestUrl: "https://v3-cinemeta.strem.io/manifest.json",
    enabledResources: ["catalog"],
    forced: 1,
    config: {},
  });

  addons.push({
    id: "org.stremio.watchhub",
    name: "WatchHub",
    icon: "",
    manifestUrl: "https://watchhub.strem.io/manifest.json",
    enabledResources: ["stream"],
    forced: 1,
    config: {},
  });

  res.json({ addons });
});

app.get("/transcode", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

  console.log("transcoding");

  const id = crypto.createHash("md5").update(raw as string).digest("hex");

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

  DB.db.prepare(
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
  "-map",
  "0:v:0",
  "-map",
  "0:a?",
  "-c:v",
  "libx264",
  "-preset",
  "fast",
  "-profile:v",
  "baseline", // iOS Safari requires baseline or main
  "-level",
  "4.0", // widely compatible level
  "-crf",
  "23",
  "-c:a",
  "aac",
  "-vf",
  "scale=-2:1080,format=yuv420p",
  "-ar",
  "44100",
  "-ac",
  "2",
  "-b:a",
  "128k",
  "-movflags",
  "+faststart",
  "-f",
  "hls",
  "-hls_time",
  "6",
  "-hls_list_size",
  "0",
  "-hls_playlist_type",
  "event",
  "-hls_flags",
  "independent_segments+append_list",
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

  const proc = spawn("ffmpeg", args as string[]);
  proc.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
  proc.on("error", console.error);

  const firstSegment = path.join(dir, "segment_000.ts");
  await new Promise<void>((resolve) => {
    const check = () => {
      if (fs.existsSync(firstSegment)) return resolve();
      setTimeout(check, 200);
    };
    check();
  });

  res.json({ streamUrl: `/streams/${id}/master.m3u8` });
});

app.use(
  "/streams",
  express.static(streamsDir, {
    setHeaders: (res, path) => {
      if (path.endsWith(".m3u8")) {
        res.setHeader("Content-Type", "application/x-mpegURL");
      } else if (path.endsWith(".ts")) {
        res.setHeader("Content-Type", "video/MP2T");
      }
    },
  }),
);

app.listen(port, () => {
  console.log(`Backend server running at 0.0.0.0:${port}`);
});
