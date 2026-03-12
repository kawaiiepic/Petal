// server.js
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
const port = 3000;

function sanitize(str) {
  return String(str ?? "")
    .replace(/[^a-zA-Z0-9_-]/g, "_") // replace spaces and special chars
    .substring(0, 30); // optional limit
}

const userAddons = {
  mia: [
    // {
    //   id: "torrentio",
    //   name: "Torrentio",
    //   manifestUrl:
    //     "https://torrentio.strem.fun/torbox=1b52e4c1-64cf-47bb-bd51-9924b18eb88f/manifest.json",
    //   icon: "https://torrentio.strem.fun/images/logo_v1.png",
    //   enabledResources: ["stream"],
    //   config: {},
    // },

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

// HLS transcoding endpoint
app.get("/transcode", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

  const id = raw;

  const dir = path.join(streamsDir, id);

  if (fs.existsSync(dir)) {
    console.log("Stream already exists")
    res.json({ streamUrl: `/streams/${id}/master.m3u8` });
    return;
  }

  fs.mkdirSync(dir, { recursive: true });
  const segmentPattern = path.join(dir, "stream_%v_%03d.ts");
  const playlistPattern = path.join(dir, "stream_%v.m3u8");
  const masterPlaylist = path.join(dir, "master.m3u8");

  const spawnFfmpeg = (mode = "copy") => {
    const args = [
      "-loglevel",
      "warning",
      "-i",
      raw,
    ];

    if (mode === "copy") {
      args.push("-c:v", "copy");
    } else {
      console.log("Falling back to full video transcode…");
      args.push("-c:v", "libx264", "-preset", "medium", "-crf", "23");
    }

    args.push("-c:a", "aac", "-b:a", "128k", masterPlaylist);

    // args.push(
    //   "-c:a",
    //   "aac",
    //   // "-ar",
    //   // "48000",
    //   // "-ac",
    //   // "2",
    //   "-b:a",
    //   "192k", // re-encode so channel/format is safe
    //   // "-threads",
    //   // "2",
    //   // "-fflags",
    //   // "+genpts+discardcorrupt",
    //   // "-avoid_negative_ts",
    //   // "make_zero",
    //   // "-max_muxing_queue_size",
    //   // "1024",
    //   "-f",
    //   "hls",
    //   "-hls_time",
    //   "2",
    //   "-hls_list_size",
    //   "0",
    //   // "-flags",
    //   // "+low_delay",
    //   // "-max_delay",
    //   // "0",
    //   // "-hls_flags",
    //   // "independent_segments+append_list",
    //   "-hls_playlist_type",
    //   "vod",
    //   "-hls_start_number_source",
    //   "epoch",
    //   "-hls_segment_filename",
    //   segmentPattern,
    //   "-var_stream_map",
    //   varStreamMap,
    //   "-master_pl_name",
    //   "master.m3u8",
    //   playlistPattern,
    // );

    const proc = spawn("ffmpeg", args);
    proc.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
    proc.on("error", console.error);
    proc.on("exit", (code) => {
      if (code !== 0 && mode === "copy") spawnFfmpeg("transcode");
    });
    return proc;
  };

  const ffmpeg = spawnFfmpeg("copy");
  activeStreams.set(id, ffmpeg);

  res.json({ streamUrl: `/streams/${id}/master.m3u8` });
});

app.use("/streams", express.static(streamsDir));

app.listen(port, () => {
  console.log(`Backend server running at 0.0.0.0:${port}`);
});
