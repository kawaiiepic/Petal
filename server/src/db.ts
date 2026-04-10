import Database from "better-sqlite3";
import fs from "fs";
import bcrypt from "bcrypt";
import { UUID } from "crypto";

export abstract class DB {
  static db = new Database("test.db");

  public static init() {
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("synchronous = NORMAL");
    this.db.pragma("temp_store = MEMORY");

    this.db
      .prepare(
        `
    CREATE TABLE IF NOT EXISTS users (
      email TEXT PRIMARY KEY,
      password TEXT,
      key TEXT,
      created_at INTEGER
    )
    `,
      )
      .run();

    this.db
      .prepare(
        `
      CREATE TABLE IF NOT EXISTS trakt_accounts (
  user_email TEXT,
  access_token TEXT,
  refresh_token TEXT,
  expires_at INTEGER,
  created_at INTEGER,
  PRIMARY KEY(user_email),
  FOREIGN KEY(user_email) REFERENCES users(email)
);
      `,
      )
      .run();

    // user addons
    this.db
      .prepare(
        `
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
  `,
      )
      .run();

    // image cache
    this.db
      .prepare(
        `
  CREATE TABLE IF NOT EXISTS image_cache (
    url TEXT PRIMARY KEY,
    content_type TEXT,
    cached_at INTEGER
  )
  `,
      )
      .run();

    this.db
      .prepare(
        `
  CREATE TABLE IF NOT EXISTS api_cache (
  key TEXT,
  username TEXT,
  value TEXT,
  expires_at INTEGER,
  PRIMARY KEY (key, username)
)
`,
      )
      .run();

    // stream sessions
    this.db
      .prepare(
        `
  CREATE TABLE IF NOT EXISTS streams (
    id TEXT PRIMARY KEY,
    source_url TEXT,
    directory TEXT,
    created_at INTEGER,
    last_access INTEGER
  )
  `,
      )
      .run();

    setInterval(
      () => {
        const cutoff = Date.now() - 1000 * 60 * 60 * 6; // 6 hours

        const old: StreamRecord[] = this.db
          .prepare(`SELECT * FROM streams WHERE last_access < ?`)
          .all(cutoff) as StreamRecord[];

        for (const stream of old) {
          fs.rmSync(stream.directory, { recursive: true, force: true });
          this.db.prepare("DELETE FROM streams WHERE id = ?").run(stream.id);
        }
      },
      1000 * 60 * 60,
    ); // run every hour
  }

  public static async addUser(data: any) {
    console.log(data);

    const hashedPassword = await bcrypt.hash(data.password, 10);

    this.db
      .prepare(
        `
    INSERT INTO users (email, password, key, created_at)
    VALUES (?, ?, ?, ?)
    `,
      )
      .run(data.email, hashedPassword, data.key, Date.now());
  }

  public static syncTrakt(userEmail: string, trakt: any) {
    this.db
      .prepare(
        `
    INSERT INTO trakt_accounts (
      user_email,
      access_token,
      refresh_token,
      expires_at,
      created_at
    )
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_email) DO UPDATE SET
      access_token = excluded.access_token,
      refresh_token = excluded.refresh_token,
      expires_at = excluded.expires_at
  `,
      )
      .run(
        userEmail,
        trakt.access_token,
        trakt.refresh_token,
        Date.now() + trakt.expires_in,
        Date.now(),
      );
  }

  public static getTraktAccessToken(userEmail: string): string | null {
    const row = this.db
      .prepare(
        `
      SELECT access_token
      FROM trakt_accounts
      WHERE user_email = ?
    `,
      )
      .get(userEmail) as TraktAccount;

    return row?.access_token ?? null;
  }

  public static getUser(email: string) {
    return this.db
      .prepare(
        `
    SELECT * FROM users WHERE email = ?
    `,
      )
      .get(email);
  }

  public static updateUser(username: string, data: any) {
    this.db
      .prepare(
        `
    UPDATE users SET access_token = ?, expires_in = ?, refresh_token = ?, updated_at = ?
    WHERE username = ?
    `,
      )
      .run(
        data.access_token,
        data.expires_in,
        data.refresh_token,
        Date.now(),
        username,
      );
  }

  public static getCache(key: string, username?: string) {
    const row = this.db
      .prepare(`SELECT * FROM api_cache WHERE key = ? AND username IS ?`)
      .get(key, username ?? null) as any;

    if (!row) return null;

    if (Date.now() > row.expires_at) {
      this.db
        .prepare(`DELETE FROM api_cache WHERE key = ? AND username IS ?`)
        .run(key, username ?? null);
      return null;
    }

    return JSON.parse(row.value);
  }

  public static setCache(
    key: string,
    value: any,
    ttlMs: number,
    username?: string,
  ) {
    const expiresAt = Date.now() + ttlMs;

    this.db
      .prepare(
        `
    INSERT OR REPLACE INTO api_cache (key, username, value, expires_at)
    VALUES (?, ?, ?, ?)
  `,
      )
      .run(key, username ?? null, JSON.stringify(value), expiresAt);
  }
}

interface StreamRecord {
  id: string;
  source_url: string;
  directory: string;
  created_at: number;
  last_access: number;
}

export type User = {
  email: string;
  password: string;
  key: UUID;
  created_at: number;
};

export type TraktAccount = {
  access_token: string;
};
