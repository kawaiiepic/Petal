import Database from "better-sqlite3";

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
      username TEXT PRIMARY KEY,
      access_token TEXT,
      expires_in INTEGER,
      refresh_token TEXT,
      created_at INTEGER
    )
    `,
      )
      .run();

    // user addons
    this.db
      .prepare(
        `
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
  }

  public static addUser(data: any) {
    console.log(data);
    this.db
      .prepare(
        `
    INSERT INTO users (username, access_token, expires_in, refresh_token, created_at)
    VALUES (?, ?, ?, ?, ?)
    `,
      )
      .run(
        data.username,
        data.access_token,
        data.expires_in,
        data.refresh_token,
        Date.now(),
      );
  }

  public static getUser(username: string) {
    return this.db
      .prepare(
        `
    SELECT * FROM users WHERE username = ?
    `,
      )
      .get(username);
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