import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import cookieParser from "cookie-parser";
import { Trakt } from "./trakt.js";
import { DB } from "./db.js";
const app = express();
const port = 3000;
app.use(cors());
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
        if (!raw)
            return res.status(400).send("Missing url");
        const url = decodeURIComponent(raw);
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
        if (!response.ok)
            return res.status(response.status).send("Upstream error");
        const buffer = Buffer.from(await response.arrayBuffer());
        const contentType = response.headers.get("content-type") || "image/jpeg";
        imageCache.set(url, { buffer, type: contentType });
        res.set("Content-Type", contentType);
        res.set("Cache-Control", "public, max-age=86400");
        res.send(buffer);
    }
    catch (err) {
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
    var username = Trakt.verifyToken(req.cookies.token).username;
    console.log("Saving addons for user:", username);
    const insert = DB.db.prepare(`
    INSERT OR REPLACE INTO addons
    (id, username, name, manifest_url, icon, enabled_resources, forced, config)
    VALUES (?,?, ?, ?, ?, ?, ?, ?)
  `);
    const tx = DB.db.transaction(() => {
        for (const addon of addons) {
            insert.run(addon.id, username, addon.name, addon.manifestUrl, addon.icon || "", JSON.stringify(addon.enabledResources || []), addon.forced, JSON.stringify(addon.config || {}));
        }
    });
    tx();
    res.json({ success: true });
});
// Get addons for a user
app.get("/addons/get", (req, res) => {
    var username = Trakt.verifyToken(req.cookies.token)
        .username;
    console.log("Fetching addons for user:", username);
    const rows = DB.db
        .prepare(`
    SELECT * FROM addons WHERE username = ?
  `)
        .all(username);
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
app.listen(port, () => {
    console.log(`Backend server running at 0.0.0.0:${port}`);
});
