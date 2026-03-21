import Database from "better-sqlite3";
import fs from "fs";
export class DB {
    static init() {
        this.db.pragma("journal_mode = WAL");
        this.db.pragma("synchronous = NORMAL");
        this.db.pragma("temp_store = MEMORY");
        this.db
            .prepare(`
    CREATE TABLE IF NOT EXISTS users (
      username TEXT PRIMARY KEY,
      access_token TEXT,
      expires_in INTEGER,
      refresh_token TEXT,
      created_at INTEGER
    )
    `)
            .run();
        // user addons
        this.db
            .prepare(`
    CREATE TABLE IF NOT EXISTS addons (
      username TEXT,
      id TEXT,
      name TEXT,
      manifest_url TEXT,
      icon TEXT,
      enabled_resources TEXT,
      forced INTEGER,
      config TEXT,
      PRIMARY KEY (username, id),
      FOREIGN KEY(username) REFERENCES users(username)
    )
  `)
            .run();
        // image cache
        this.db
            .prepare(`
  CREATE TABLE IF NOT EXISTS image_cache (
    url TEXT PRIMARY KEY,
    content_type TEXT,
    cached_at INTEGER
  )
  `)
            .run();
        this.db
            .prepare(`
  CREATE TABLE IF NOT EXISTS api_cache (
  key TEXT,
  username TEXT,
  value TEXT,
  expires_at INTEGER,
  PRIMARY KEY (key, username)
)
`)
            .run();
        // stream sessions
        this.db
            .prepare(`
  CREATE TABLE IF NOT EXISTS streams (
    id TEXT PRIMARY KEY,
    source_url TEXT,
    directory TEXT,
    created_at INTEGER,
    last_access INTEGER
  )
  `)
            .run();
        setInterval(() => {
            const cutoff = Date.now() - 1000 * 60 * 60 * 6; // 6 hours
            const old = this.db
                .prepare(`SELECT * FROM streams WHERE last_access < ?`)
                .all(cutoff);
            for (const stream of old) {
                fs.rmSync(stream.directory, { recursive: true, force: true });
                this.db.prepare("DELETE FROM streams WHERE id = ?").run(stream.id);
            }
        }, 1000 * 60 * 60); // run every hour
    }
    static addUser(data) {
        console.log(data);
        this.db
            .prepare(`
    INSERT INTO users (username, access_token, expires_in, refresh_token, created_at)
    VALUES (?, ?, ?, ?, ?)
    `)
            .run(data.username, data.access_token, data.expires_in, data.refresh_token, Date.now());
    }
    static getUser(username) {
        return this.db
            .prepare(`
    SELECT * FROM users WHERE username = ?
    `)
            .get(username);
    }
    static updateUser(username, data) {
        this.db
            .prepare(`
    UPDATE users SET access_token = ?, expires_in = ?, refresh_token = ?, updated_at = ?
    WHERE username = ?
    `)
            .run(data.access_token, data.expires_in, data.refresh_token, Date.now(), username);
    }
    static getCache(key, username) {
        const row = this.db
            .prepare(`SELECT * FROM api_cache WHERE key = ? AND username IS ?`)
            .get(key, username ?? null);
        if (!row)
            return null;
        if (Date.now() > row.expires_at) {
            this.db
                .prepare(`DELETE FROM api_cache WHERE key = ? AND username IS ?`)
                .run(key, username ?? null);
            return null;
        }
        return JSON.parse(row.value);
    }
    static setCache(key, value, ttlMs, username) {
        const expiresAt = Date.now() + ttlMs;
        this.db
            .prepare(`
    INSERT OR REPLACE INTO api_cache (key, username, value, expires_at)
    VALUES (?, ?, ?, ?)
  `)
            .run(key, username ?? null, JSON.stringify(value), expiresAt);
    }
}
DB.db = new Database("test.db");
