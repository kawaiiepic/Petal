import Database from "better-sqlite3";
import fs from "fs";
import bcrypt from "bcrypt";
export class DB {
    static init() {
        this.db.pragma("journal_mode = WAL");
        this.db.pragma("synchronous = NORMAL");
        this.db.pragma("temp_store = MEMORY");
        this.db
            .prepare(`
    CREATE TABLE IF NOT EXISTS users (
      email TEXT PRIMARY KEY,
      password TEXT,
      key TEXT,
      created_at INTEGER
    )
    `)
            .run();
        this.db
            .prepare(`
      CREATE TABLE IF NOT EXISTS trakt_accounts (
  user_email TEXT,
  access_token TEXT,
  refresh_token TEXT,
  username TEXT,
  expires_at INTEGER,
  created_at INTEGER,
  PRIMARY KEY(user_email),
  FOREIGN KEY(user_email) REFERENCES users(email)
);
      `)
            .run();
        // user addons
        this.db
            .prepare(`
    CREATE TABLE IF NOT EXISTS addons (
      id TEXT,
      email TEXT,
      name TEXT,
      manifest_url TEXT,
      icon TEXT,
      enabled_resources TEXT,
      forced INTEGER,
      config TEXT,
      PRIMARY KEY (email, id),
      FOREIGN KEY(email) REFERENCES users(email)
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
    static async addUser(data) {
        console.log(data);
        const hashedPassword = await bcrypt.hash(data.password, 10);
        this.db
            .prepare(`
    INSERT INTO users (email, password, key, created_at)
    VALUES (?, ?, ?, ?)
    `)
            .run(data.email, hashedPassword, data.key, Date.now());
    }
    static syncTrakt(userEmail, trakt) {
        this.db
            .prepare(`
    INSERT INTO trakt_accounts (
      user_email,
      access_token,
      refresh_token,
      username,
      expires_at,
      created_at
    )
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_email) DO UPDATE SET
      access_token = excluded.access_token,
      refresh_token = excluded.refresh_token,
      username = excluded.username,
      expires_at = excluded.expires_at
  `)
            .run(userEmail, trakt.access_token, trakt.refresh_token, trakt.username, trakt.expires_at, Date.now());
    }
    static getTraktAccessToken(userEmail) {
        const row = this.db
            .prepare(`
      SELECT access_token
      FROM trakt_accounts
      WHERE user_email = ?
    `)
            .get(userEmail);
        return row?.access_token ?? null;
    }
    static getUser(email) {
        return this.db
            .prepare(`
    SELECT * FROM users WHERE email = ?
    `)
            .get(email);
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
