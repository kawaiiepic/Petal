// server.js
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
const port = 3000;

// Simple in-memory storage (replace with DB later)
const userAddons = {
  mia: [
    {
      id: "torrentio",
      name: "Torrentio",
      manifestUrl:
        "https://torrentio.strem.fun/torbox=1b52e4c1-64cf-47bb-bd51-9924b18eb88f/manifest.json",
      icon: "https://torrentio.strem.fun/images/logo_v1.png",
      enabledResources: ["stream"],
      config: {},
    },

    {
      id: "comet",
      name: "Comet",
      manifestUrl:
        "https://comet.elfhosted.com/eyJtYXhSZXN1bHRzUGVyUmVzb2x1dGlvbiI6MCwibWF4U2l6ZSI6MCwiY2FjaGVkT25seSI6ZmFsc2UsInNvcnRDYWNoZWRVbmNhY2hlZFRvZ2V0aGVyIjpmYWxzZSwicmVtb3ZlVHJhc2giOnRydWUsInJlc3VsdEZvcm1hdCI6WyJhbGwiXSwiZGVicmlkU2VydmljZSI6InRvcmJveCIsImRlYnJpZEFwaUtleSI6IjFiNTJlNGMxLTY0Y2YtNDdiYi1iZDUxLTk5MjRiMThlYjg4ZiIsImRlYnJpZFN0cmVhbVByb3h5UGFzc3dvcmQiOiIiLCJsYW5ndWFnZXMiOnsiZXhjbHVkZSI6W10sInByZWZlcnJlZCI6WyJlbiJdfSwicmVzb2x1dGlvbnMiOnt9LCJvcHRpb25zIjp7InJlbW92ZV9yYW5rc191bmRlciI6LTEwMDAwMDAwMDAwLCJhbGxvd19lbmdsaXNoX2luX2xhbmd1YWdlcyI6ZmFsc2UsInJlbW92ZV91bmtub3duX2xhbmd1YWdlcyI6ZmFsc2V9fQ==/manifest.json",
      icon: "https://i.imgur.com/jmVoVMu.jpeg",
      enabledResources: ["stream"],
      config: {},
    },

    {
      id: "com.linvo.cinemeta",
      name: "Cinemeta",
      manifestUrl: "https://v3-cinemeta.strem.io/manifest.json",
      enabledResources: ["catalog"],
      config: {},
    },
  ],
};

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
    return res.status(400).json({ error: "Missing userId or addons" });
  }
  userAddons[userId] = addons;
  res.json({ success: true });
});

// Get addons for a user
app.get("/addons/:userId", (req, res) => {
  const { userId } = req.params;
  res.json({ addons: userAddons[userId] || [] });
});

import { spawn } from "child_process";
import fs from "fs";
import path from "path";

const streamsDir = "/tmp/petal-streams";
fs.mkdirSync(streamsDir, { recursive: true });

// limit concurrent ffmpeg processes so the server can't be overwhelmed
const MAX_TRANSCODES = 2;
let activeTranscodes = 0;

// track running ffmpeg processes so we can kill idle ones
const activeStreams = new Map();

// HLS transcoding endpoint
app.get("/transcode", (req, res) => {
  const raw = req.query.url;
  console.log("Transcode request:", raw);
  console.log("Current transcodes:", activeTranscodes);

  if (activeTranscodes >= MAX_TRANSCODES) {
    console.log("Too many transcodes currently running.");
    return res
      .status(429)
      .json({ error: "Server busy, too many active streams" });
  }

  if (!raw) return res.status(400).send("Missing url");

  activeTranscodes++;

  const url = raw;

  const id = Date.now().toString();
  const dir = path.join(streamsDir, id);
  fs.mkdirSync(dir, { recursive: true });

  const playlist = path.join(dir, "stream.m3u8");

  // Try low‑CPU path first: copy video, transcode audio
  const spawnFfmpeg = (mode = "copy") => {
    const args = [
      "-loglevel",
      "warning",
      "-i",
      url,
      "-map",
      "0:v:0",
      "-map",
      "0:a:0",
    ];

    if (mode === "copy") {
      args.push("-c:v", "copy");
    } else {
      console.log("Falling back to full video transcode...");
      args.push("-c:v", "libx264", "-preset", "veryfast", "-crf", "23");
    }

    args.push(
      "-c:a",
      "aac",
      "-ac",
      "2",
      "-b:a",
      "192k",
      "-threads",
      "2",
      "-fflags",
      "+genpts",
      "-max_muxing_queue_size",
      "1024",
      "-f",
      "hls",
      "-start_number",
      "0",
      "-hls_time",
      "2",
      "-hls_list_size",
      "6",
      "-hls_flags",
      "delete_segments+independent_segments",
      "-hls_playlist_type",
      "vod",
      "-hls_start_number_source",
      "epoch",
      playlist,
    );

    const proc = spawn("ffmpeg", args);

    proc.stderr.on("data", (data) => {
      console.log("ffmpeg:", data.toString());
    });

    proc.on("error", console.error);

    proc.on("exit", (code) => {
      activeTranscodes = Math.max(0, activeTranscodes - 1);

      if (code !== 0 && mode === "copy") {
        // Retry with full transcoding if copy fails
        spawnFfmpeg("transcode");
      }
    });

    return proc;
  };

  console.log("Starting ffmpeg for:", url);
  const ffmpeg = spawnFfmpeg("copy");

  // track process
  activeStreams.set(id, ffmpeg);

  const getduration = () =>
    new Promise((resolve) => {
      const probe = spawn("ffprobe", [
        "-v",
        "quiet",
        "-print_format",
        "json",
        "-show_format",
        url,
      ]);
      let out = "";
      probe.stdout.on("data", (d) => (out += d));
      probe.on("exit", () => {
        try {
          const duration = JSON.parse(out).format?.duration;
          resolve(duration ? parseFloat(duration) : null);
        } catch {
          resolve(null);
        }
      });
    });

  const check = setInterval(async () => {
    const files = fs.readdirSync(dir);
    const segmentExists = files.some((f) => f.endsWith(".ts"));

    if (segmentExists) {
      clearInterval(check);
      const duration = await getduration();
      res.json({
        streamUrl: `/streams/${id}/stream.m3u8`,
        duration, // seconds as float, e.g. 5423.4
      });
    }
  }, 200);

  // cleanup old streams
  setTimeout(() => {
    const proc = activeStreams.get(id);
    if (proc) {
      try {
        proc.kill("SIGKILL");
      } catch {}
      activeStreams.delete(id);
    }
    fs.rm(dir, { recursive: true, force: true }, () => {});
  }, 3600000);
});

app.use("/streams", express.static(streamsDir));

app.listen(port, () => {
  console.log(`Backend server running at http://localhost:${port}`);
});
