import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
// import Database from "better-sqlite3";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import cookieParser from "cookie-parser";
import { ChildProcess, spawn } from "child_process";
import fs from "fs";
import path from "path";

import { Trakt } from "./trakt.js";
import { DB } from "./db.js";
import { Login } from "./login.js";

const streamsDir = "/tmp/petal-streams";
fs.mkdirSync(streamsDir, { recursive: true });
const ffmpegProcs = new Map<string, ChildProcess>();

const app = express();
const port = 3000;

const accessToken =
  "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTA3MDBmYWY5ZDZmYzMwMWMxM2Y0MWUzMTIxZDU1YSIsIm5iZiI6MTU5OTIxMDQ4My41NTIsInN1YiI6IjVmNTIwM2YzYjIzNGI5MDAzNzE4YjMzNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.RHJTrJPzXmpf0GM6FB8gdipG46lSo-XFY3FQ_Ljjy2c";

const _header = {
  accept: "application/json",
  Authorization: `Bearer ${accessToken}`,
};

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
// Trakt.obtainUserProfile(app);
// Trakt.obtainLastActivities(app);
// Trakt.search(app);
Trakt.startWatching(app);
Trakt.obtainWatched(app);
// Trakt.obtainShow(app);
// Trakt.obtainMovie(app);
// Trakt.obtainSeasons(app);
Trakt.obtainShowProgress(app);

Login.verifyLogin(app);

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

async function fetchWithRetry(
  url: string,
  options: any,
  retries = 5,
  delay = 500,
): Promise<Response> {
  try {
    const res = await fetch(url, options);

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }

    return res;
  } catch (err) {
    if (retries === 0) throw err;

    console.log(`Retrying ${url}... (${retries} left)`);

    await new Promise((r) => setTimeout(r, delay));

    return fetchWithRetry(url, options, retries - 1, delay * 2); // exponential backoff
  }
}

app.get("/tmdb", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).json({ error: "Missing url" });

  const url = `https://api.themoviedb.org/3${decodeURIComponent(raw as string)}`;

  try {
    const response = await fetch(url, {
      headers: _header,
    });

    // const response = await fetch(url, {
    //   headers: _header,
    // });

    if (response.ok) {
      res.status(200).json(await response.json());
    } else {
      console.log("Failed to request TMDB API");
    }
  } catch (_) {
    res.status(300);
  }
});

// simple in-memory cache
const imageCache = new Map();

// Image proxy with decoding + caching
app.get("/img", async (req, res) => {
  try {
    const raw = req.query.url;
    console.log(`Trying to get $raw`);
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

app.get("/user/settings", (req, res) => {
  try {
    var accessToken = Trakt.accessToken(req.cookies.auth);
    res.json({ traktConnected: true });
  } catch (err) {
    console.error(err);
    res.json({ traktConnected: false });
  }
});

app.post("/user/settings", (req, res) => {});
// Save addons for a user
app.post("/addons/set", (req, res) => {
  console.log(req.body);
  const addons = req.body.addons;

  if (!addons) {
    return res.status(400).json({ error: "Missing data" });
  }

  console.log("Saving addon.");

  var email = (Login.verifyToken(req.cookies.auth) as jwt.JwtPayload).email;

  console.log("Saving addons for user:", email);

  const insert = DB.db.prepare(`
    INSERT OR REPLACE INTO addons
    (id, email, name, manifest_url, icon, enabled_resources, forced, config)
    VALUES (?,?, ?, ?, ?, ?, ?, ?)
  `);

  const tx = DB.db.transaction(() => {
    for (const addon of addons) {
      insert.run(
        addon.id,
        email,
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
  try {
    var email = (Trakt.verifyToken(req.cookies.auth) as jwt.JwtPayload).email;
    console.log("Fetching addons for user:", email);

    const rows = DB.db
      .prepare(
        `
      SELECT * FROM addons WHERE email = ?
    `,
      )
      .all(email);

    console.log(rows);

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
  } catch (_) {}
});

app.get("/transcode", async (req, res) => {
  const raw = req.query.url as string;
  if (!raw) return res.status(400).send("Missing url");

  console.log("Starting transcoding for", raw);

  const id = crypto.createHash("md5").update(raw).digest("hex");
  const dir = path.join(streamsDir, id);
  fs.mkdirSync(dir, { recursive: true });

  // 1️⃣ Probe the input for audio tracks
  const probeArgs = [
    "-i",
    raw,
    "-show_streams",
    "-select_streams",
    "a",
    "-of",
    "json",
  ];

  const probe = spawn("ffprobe", probeArgs);
  let probeData = "";

  probe.stdout.on("data", (d) => (probeData += d.toString()));
  await new Promise<void>((resolve, reject) => {
    probe.on("close", (code) =>
      code === 0 ? resolve() : reject("ffprobe failed"),
    );
  });

  const audioStreams = JSON.parse(probeData).streams as any[];
  if (!audioStreams?.length)
    return res.status(400).send("No audio streams found");

  console.log(`Found ${audioStreams.length} audio track(s)`);

  // 2️⃣ Generate HLS for each audio track
  const ffmpegArgs: string[] = [];

  // Video stream mapping
  ffmpegArgs.push("-i", raw);
  ffmpegArgs.push("-map", "0:v:0");
  ffmpegArgs.push(
    "-c:v",
    "libx264",
    "-preset",
    "fast",
    "-profile:v",
    "main",
    "-level",
    "4.0",
    "-crf",
    "23",
  );
  ffmpegArgs.push("-vf", "scale=-2:1080,format=yuv420p");

  // Map all audio tracks individually

  // 3️⃣ Run FFmpeg
  const ffmpeg = spawn("ffmpeg", ffmpegArgs);
  ffmpeg.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
  ffmpeg.on("error", console.error);

  // Wait until first segment of first audio track exists
  const firstSegment = path.join(dir, "audio_0", "segment_000.ts");
  await new Promise<void>((resolve) => {
    const check = () =>
      fs.existsSync(firstSegment) ? resolve() : setTimeout(check, 200);
    check();
  });

  ffmpeg.unref();

  // 4️⃣ Return JSON with all audio track URIs
  const audioTrackUris = audioStreams.map((track, i) => ({
    id: track.tags?.language || `audio_${i}`,
    uri: `/streams/${id}/audio_${i}/master.m3u8`,
  }));

  res.json({
    id,
    videoUri: `/streams/${id}/audio_0/master.m3u8`, // optional main video URI
    audioTracks: audioTrackUris,
  });
});

app.get("/transcode/:id", (req, res) => {
  const proc = ffmpegProcs.get(req.params.id);
  const running = proc ? proc.exitCode === null : false;
  res.json({ transcoding: running });
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
