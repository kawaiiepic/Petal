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
app.get("/transcode", async (req, res) => {
  const raw = req.query.url;
  if (!raw) return res.status(400).send("Missing url");

  if (activeTranscodes >= MAX_TRANSCODES)
    return res
      .status(429)
      .json({ error: "Server busy, too many active streams" });

  activeTranscodes++;
  const id = Date.now().toString();
  const dir = path.join(streamsDir, id);
  fs.mkdirSync(dir, { recursive: true });

  // ── 1. Probe all streams ──────────────────────────────────────────────────
  const probe = () =>
    new Promise((resolve) => {
      const p = spawn("ffprobe", [
        "-v",
        "quiet",
        "-print_format",
        "json",
        "-show_streams",
        "-show_format",
        raw,
      ]);
      let out = "";
      p.stdout.on("data", (d) => (out += d));
      p.on("exit", () => {
        try {
          resolve(JSON.parse(out));
        } catch {
          resolve({ streams: [], format: {} });
        }
      });
    });

  const { streams, format } = await probe();
  const audioStreams = streams.filter((s) => s.codec_type === "audio");
  const subtitleStreams = streams.filter((s) => s.codec_type === "subtitle");
  const duration = format?.duration ? parseFloat(format.duration) : null;

  // ── 2. Extract ALL subtitle tracks as .vtt files (async, don't await) ────
  if (subtitleStreams.length) {
    const subArgs = ["-loglevel", "warning", "-i", raw];
    subtitleStreams.forEach((s, i) => {
      subArgs.push(
        "-map",
        `0:s:${s.index}`,
        "-c:s",
        "webvtt",
        path.join(dir, `sub_${i}.vtt`),
      );
    });
    spawn("ffmpeg", subArgs).on("error", console.error);
  }

  // ── 3. Build map + var_stream_map for video + all audio tracks ────────────
  //
  //  var_stream_map layout:
  //    stream 0   → video-only carrier that references the audio group
  //    stream 1…N → one entry per audio track
  //
  //  ffmpeg will auto-generate a master.m3u8 with EXT-X-MEDIA for each audio.

  const mapArgs = ["-map", "0:v:0"];
  audioStreams.forEach((s) => mapArgs.push("-map", `0:${s.index}`));

  // Audio-group entries  (stream indices start at 1 because 0 = video)
  const audioGroupEntries = audioStreams.map((s, i) => {
    const lang = s.tags?.language ?? `track${i}`;
    const name = s.tags?.title ?? lang;
    const def = i === 0 ? ",default:yes" : "";
    // stream index in var_stream_map is a:i (ffmpeg counts only mapped audio)
    return `a:${i},agroup:audio,language:${lang},name:${name}${def}`;
  });

  // Video stream references the audio group; if no audio just omit agroup
  const videoEntry = audioStreams.length ? "v:0,agroup:audio" : "v:0";

  const varStreamMap = [videoEntry, ...audioGroupEntries].join(" ");

  // ── 4. Spawn ffmpeg ───────────────────────────────────────────────────────
  const segmentPattern = path.join(dir, "stream_%v_%03d.ts");
  const playlistPattern = path.join(dir, "stream_%v.m3u8");
  const masterPlaylist = path.join(dir, "master.m3u8");

  const spawnFfmpeg = (mode = "copy") => {
    const args = ["-loglevel", "warning", "-i", raw, ...mapArgs];

    const videoStream = streams.find((s) => s.codec_type === "video");
    const isH264 = videoStream?.codec_name === "h264";

    if (mode === "copy") {
      args.push("-c:v", "copy");
      if (isH264) {
        args.push("-bsf:v", "h264_mp4toannexb");
      }
    } else {
      console.log("Falling back to full video transcode…");
      args.push("-c:v", "libx264", "-preset", "veryfast", "-crf", "23");
    }

    args.push(
      "-c:a",
      "aac",
      "-b:a",
      "192k", // re-encode so channel/format is safe
      "-threads",
      "2",
      "-fflags",
      "+genpts",
      "-max_muxing_queue_size",
      "1024",
      "-f",
      "hls",
      "-hls_time",
      "8",
      "-hls_list_size",
      "0",
      "-hls_flags",
      "independent_segments",
      "-hls_playlist_type",
      "event",
      "-hls_start_number_source",
      "epoch",
      "-hls_segment_filename",
      segmentPattern,
      "-var_stream_map",
      varStreamMap,
      "-master_pl_name",
      "master.m3u8",
      playlistPattern,
    );

    const proc = spawn("ffmpeg", args);
    proc.stderr.on("data", (d) => console.log("ffmpeg:", d.toString()));
    proc.on("error", console.error);
    proc.on("exit", (code) => {
      activeTranscodes = Math.max(0, activeTranscodes - 1);
      if (code !== 0 && mode === "copy") spawnFfmpeg("transcode");
    });
    return proc;
  };

  const ffmpeg = spawnFfmpeg("copy");
  activeStreams.set(id, ffmpeg);

  // ── 5. Wait for first segment, then respond ───────────────────────────────
  const check = setInterval(() => {
    if (fs.existsSync(masterPlaylist)) {
      clearInterval(check);

      // Append subtitle tracks to master playlist once ffmpeg writes it
      appendSubtitlesToMaster(masterPlaylist, subtitleStreams, id);

      res.json({
        streamUrl: `/streams/${id}/master.m3u8`,
        duration,
        audioTracks: audioStreams.map((s, i) => ({
          index: i,
          language: s.tags?.language ?? null,
          title: s.tags?.title ?? null,
        })),
        subtitleTracks: subtitleStreams.map((s, i) => ({
          index: i,
          language: s.tags?.language ?? null,
          title: s.tags?.title ?? null,
          url: `/streams/${id}/sub_${i}.vtt`,
        })),
      });
    }
  }, 200);

  // ── 6. Cleanup after 1 hour ───────────────────────────────────────────────
  setTimeout(() => {
    const proc = activeStreams.get(id);
    if (proc) {
      try {
        proc.kill("SIGTERM");
        setTimeout(() => proc.kill("SIGKILL"), 3000);
      } catch {}
      activeStreams.delete(id);
    }
    fs.rm(dir, { recursive: true, force: true }, () => {});
  }, 3_600_000);
});

// ── Append EXT-X-MEDIA subtitle entries to the master playlist ─────────────
function appendSubtitlesToMaster(masterPath, subtitleStreams, id) {
  if (!subtitleStreams.length) return;

  // Poll until ffmpeg has written the master playlist
  const attempt = (tries = 0) => {
    if (tries > 50) return;
    if (!fs.existsSync(masterPath)) {
      return setTimeout(() => attempt(tries + 1), 200);
    }

    const subtitleLines = subtitleStreams
      .map((s, i) => {
        const lang = s.tags?.language ?? `sub${i}`;
        const name = s.tags?.title ?? lang;
        const def = i === 0 ? "YES" : "NO";
        return (
          `#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",` +
          `NAME="${name}",LANGUAGE="${lang}",DEFAULT=${def},AUTOSELECT=YES` +
          `FORCED=NO,URI="sub_${i}.vtt"`
        );
      })
      .join("\n");

    let master = fs.readFileSync(masterPath, "utf8");

    // Inject subtitle entries before the first #EXT-X-STREAM-INF line
    master = master.replace(/(#EXT-X-STREAM-INF)/, `${subtitleLines}\n$1`);

    // Add SUBTITLES="subs" to every EXT-X-STREAM-INF line
    master = master.replace(/(#EXT-X-STREAM-INF:[^\n]+)/g, (line) =>
      line.includes("SUBTITLES") ? line : `${line},SUBTITLES="subs"`,
    );

    fs.writeFileSync(masterPath, master);
  };

  attempt();
}

app.use("/streams", express.static(streamsDir));

app.listen(port, () => {
  console.log(`Backend server running at http://localhost:${port}`);
});
