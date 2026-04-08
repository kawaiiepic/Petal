var _a;
import jwt from "jsonwebtoken";
import { DB } from "./db.js";
import { Login } from "./login.js";
export class Trakt {
    static deviceCode(app) {
        app.get("/trakt/device_code", async (req, res) => {
            const response = await fetch("https://api.trakt.tv/oauth/device/code", {
                method: "POST",
                headers: this._header,
                body: JSON.stringify({ client_id: this.CLIENT_ID }),
            });
            const data = await response.json();
            res.json(data);
        });
    }
    static async pollForAccessToken(app) {
        app.post("/trakt/check_auth", async (req, res) => {
            console.log("Polling for access token");
            const data = req.body;
            const response = await fetch("https://api.trakt.tv/oauth/device/token", {
                method: "POST",
                headers: this._header,
                body: JSON.stringify({
                    code: data.code,
                    client_id: this.CLIENT_ID,
                    client_secret: this.CLIENT_SECRET,
                }),
            });
            if (response.status == 400) {
                res.status(400).json({ error: "Failed to fetch access token" });
            }
            else {
                if (response.status == 200) {
                    const data = await response.json();
                    if (req.cookies.auth != undefined) {
                        var verify = Login.verifyToken(req.cookies.auth);
                        DB.syncTrakt(verify.email, data);
                        res.status(200).json({ status: "success" });
                    }
                    console.log("Access token received:", data);
                }
            }
        });
    }
    static async userProfile(accessToken) {
        const response = await fetch("https://api.trakt.tv/users/me?extended=full", {
            headers: {
                ...this._header,
                Authorization: `Bearer ${accessToken}`,
            },
        });
        if (response.ok) {
            const data = await response.json();
            return data;
        }
        else {
            throw new Error("Failed to fetch user profile");
        }
    }
    static verifyToken(token) {
        return jwt.verify(token, this.SECRET_KEY);
    }
    static accessToken(auth) {
        try {
            var verify = Login.verifyToken(auth);
            return DB.getTraktAccessToken(verify.email);
        }
        catch (err) {
            console.error(err);
        }
    }
    // static async cachedUserFetchWithLastActivity(
    //   key: string,
    //   username: string,
    //   ttlMs: number,
    //   accessToken: string,
    //   fetcher: () => Promise<any>,
    // ) {
    //   // Check last_activities timestamp
    //   const lastActivities = await this.cachedFetch(
    //     `last_activities`,
    //     1000 * 30, // 30 sec cache
    //     async () => {
    //       const response = await fetch(
    //         "https://api.trakt.tv/sync/last_activities",
    //         {
    //           headers: {
    //             ...this._header,
    //             Authorization: `Bearer ${accessToken}`,
    //           },
    //         },
    //       );
    //       if (!response.ok) throw new Error("Failed to fetch last_activities");
    //       return await response.json();
    //     },
    //     username,
    //   );
    //   // Construct a cache key with last_activity timestamp
    //   const lastWatched = lastActivities?.movies?.watched_at ?? 0;
    //   const lastKey = `${key}:${lastWatched}`;
    //   // Return cached value using combined key
    //   return this.cachedFetch(lastKey, ttlMs, fetcher, username);
    // }
    // static async cachedFetch(
    //   key: string,
    //   ttlMs: number,
    //   fetcher: () => Promise<any>,
    //   username?: string,
    // ) {
    //   const cached = DB.getCache(key, username);
    //   if (cached) return cached;
    //   if (this.pending.has(key + (username ?? ""))) {
    //     return this.pending.get(key + (username ?? ""));
    //   }
    //   const promise = (async () => {
    //     const fresh = await fetcher();
    //     DB.setCache(key, fresh, ttlMs, username);
    //     this.pending.delete(key + (username ?? ""));
    //     return fresh;
    //   })();
    //   this.pending.set(key + (username ?? ""), promise);
    //   return promise;
    // }
    static async verifySession(app) {
        app.get("/trakt/verify_session", async (req, res) => {
            if (req.cookies.token != undefined) {
                console.log(req.cookies.token);
                var verify = this.verifyToken(req.cookies.token);
                if (DB.getUser(verify.username) != undefined) {
                    res.status(200);
                    res.json({ verified: true });
                }
                else {
                    res.status(201).json({ verified: false });
                }
            }
            else {
                res.status(300).json({ verified: false });
            }
        });
    }
    // public static async obtainUserProfile(app: express.Express) {
    //   app.get("/trakt/user_profile", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     var verify = Login.verifyToken(req.cookies.auth) as jwt.JwtPayload;
    //     const accessToken = this.accessToken(req.cookies.auth) as string;
    //     const data = await this.cachedFetch(
    //       `user_profile`,
    //       1000 * 60 * 5, // 5 min
    //       async () => {
    //         return await this.userProfile(accessToken);
    //       },
    //       verify.email,
    //     );
    //     res.json(data);
    //   });
    // }
    // public static async obtainLastActivities(app: express.Express) {
    //   app.get("/trakt/last_activities", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     var verify = Login.verifyToken(req.cookies.auth) as jwt.JwtPayload;
    //     const accessToken = this.accessToken(req.cookies.auth) as string;
    //     const data = await this.cachedFetch(
    //       `last_activities`,
    //       1000 * 30, // 30 sec
    //       async () => {
    //         const response = await fetch(
    //           "https://api.trakt.tv/sync/last_activities",
    //           {
    //             headers: {
    //               ...this._header,
    //               Authorization: `Bearer ${accessToken}`,
    //             },
    //           },
    //         );
    //         if (!response.ok) throw new Error("Failed");
    //         return await response.json();
    //       },
    //       verify.email,
    //     );
    //     res.json(data);
    //   });
    // }
    // public static async search(app: express.Express) {
    //   app.get("/trakt/search/:id_type/:id/:type", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     const { id_type, id, type } = req.params;
    //     const accessToken = this.accessToken(req.cookies.token);
    //     const cacheKey = `search:${id_type}:${id}:${type}`;
    //     const data = await this.cachedFetch(
    //       `search:${id_type}:${id}:${type}`,
    //       1000 * 60 * 60 * 24,
    //       async () => {
    //         const response = await fetch(
    //           `https://api.trakt.tv/search/${id_type}/${id}?type=${type}`,
    //           {
    //             headers: {
    //               ...this._header,
    //               Authorization: `Bearer ${accessToken}`,
    //             },
    //           },
    //         );
    //         if (!response.ok) throw new Error("Fetch failed");
    //         return await response.json();
    //       },
    //     );
    //     res.json(data);
    //   });
    // }
    static async startWatching(app) {
        app.post("/trakt/start_watching", async (req, res) => {
            if (req.cookies.token != undefined) {
                const accessToken = this.accessToken(req.cookies.token);
                const response = await fetch("https://api.trakt.tv/scrobble/start", {
                    method: "POST",
                    headers: {
                        ...this._header,
                        Authorization: `Bearer ${accessToken}`,
                    },
                    body: JSON.stringify(req.body),
                });
                if (response.ok) {
                    res.json(await response.json());
                }
                else {
                    res.status(await response.status);
                }
            }
            else {
                res.status(300);
            }
        });
    }
    static async obtainWatched(app) {
        app.get("/trakt/sync_watched/:type", async (req, res) => {
            if (!req.cookies.auth)
                return res.sendStatus(300);
            // const username = this.getUsername(req.cookies.token);
            var verify = Login.verifyToken(req.cookies.auth);
            const accessToken = this.accessToken(req.cookies.auth);
            console.log(accessToken);
            const type = req.params.type;
            const response = await fetch(`https://api.trakt.tv/sync/watched/${type}?extended=full`, {
                headers: {
                    ...this._header,
                    Authorization: `Bearer ${accessToken}`,
                },
            });
            if (!response.ok)
                throw new Error("Failed to fetch watched: " + (await response.text()));
            res.json(await response.json());
            // return await response.json();
            // const data = await this.cachedUserFetchWithLastActivity(
            //   `watched:${type}`,
            //   verify.email,
            //   1000 * 60, // 1 min TTL
            //   accessToken as string,
            //   async () => {
            //     const response = await fetch(
            //       `https://api.trakt.tv/sync/watched/${type}?extended=full`,
            //       {
            //         headers: {
            //           ...this._header,
            //           Authorization: `Bearer ${accessToken}`,
            //         },
            //       },
            //     );
            //     if (!response.ok) throw new Error("Failed to fetch watched");
            //     return await response.json();
            //   },
            // );
            // res.json(data);
        });
    }
    // public static async obtainShow(app: express.Express) {
    //   app.get("/trakt/shows/:traktId", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     const accessToken = this.accessToken(req.cookies.token);
    //     const data = await this.cachedFetch(
    //       `show:${req.params.traktId}`,
    //       1000 * 60 * 60 * 24 * 7, // 7 days
    //       async () => {
    //         const response = await fetch(
    //           `https://api.trakt.tv/shows/${req.params.traktId}?extended=full`,
    //           {
    //             headers: {
    //               ...this._header,
    //               Authorization: `Bearer ${accessToken}`,
    //             },
    //           },
    //         );
    //         if (!response.ok) throw new Error("Failed");
    //         return await response.json();
    //       },
    //     );
    //     res.json(data);
    //   });
    // }
    // public static async obtainMovie(app: express.Express) {
    //   app.get("/trakt/movies/:traktId", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     const accessToken = this.accessToken(req.cookies.token);
    //     // Cache the movie data for 7 days
    //     const data = await this.cachedFetch(
    //       `movie:${req.params.traktId}`,
    //       1000 * 60 * 60 * 24 * 7, // 7 days
    //       async () => {
    //         const response = await fetch(
    //           `https://api.trakt.tv/movies/${req.params.traktId}?extended=full`,
    //           {
    //             headers: {
    //               ...this._header,
    //               Authorization: `Bearer ${accessToken}`,
    //             },
    //           },
    //         );
    //         if (!response.ok) throw new Error("Failed to fetch movie");
    //         return await response.json();
    //       },
    //     );
    //     res.json(data);
    //   });
    // }
    // public static async obtainSeasons(app: express.Express) {
    //   app.get("/trakt/seasons/:traktId", async (req, res) => {
    //     if (!req.cookies.token) return res.sendStatus(300);
    //     const accessToken = this.accessToken(req.cookies.token);
    //     const data = await this.cachedFetch(
    //       `seasons:${req.params.traktId}`,
    //       1000 * 60 * 60 * 24 * 7,
    //       async () => {
    //         const response = await fetch(
    //           `https://api.trakt.tv/shows/${req.params.traktId}/seasons?extended=episodes,full`,
    //           {
    //             headers: {
    //               ...this._header,
    //               Authorization: `Bearer ${accessToken}`,
    //             },
    //           },
    //         );
    //         if (!response.ok) throw new Error("Failed");
    //         return await response.json();
    //       },
    //     );
    //     res.json(data);
    //   });
    // }
    static async obtainShowProgress(app) {
        app.get("/trakt/show_progress/:traktId", async (req, res) => {
            if (!req.cookies.token)
                return res.sendStatus(300);
            var verify = Login.verifyToken(req.cookies.auth);
            const accessToken = this.accessToken(req.cookies.auth);
            const traktId = req.params.traktId;
            const response = await fetch(`https://api.trakt.tv/shows/${traktId}/progress/watched?last_activity=watched`, {
                headers: {
                    ...this._header,
                    Authorization: `Bearer ${accessToken}`,
                },
            });
            if (!response.ok)
                throw new Error("Failed to fetch progress");
            res.json(await response.json());
            // const data = await this.cachedUserFetchWithLastActivity(
            //   `progress:${traktId}`,
            //   verify.email,
            //   1000 * 30, // 30 sec TTL
            //   accessToken,
            //   async () => {
            //     const response = await fetch(
            //       `https://api.trakt.tv/shows/${traktId}/progress/watched?last_activity=watched`,
            //       {
            //         headers: {
            //           ...this._header,
            //           Authorization: `Bearer ${accessToken}`,
            //         },
            //       },
            //     );
            //     if (!response.ok) throw new Error("Failed to fetch progress");
            //     return await response.json();
            //   },
            // );
            // res.json(data);
        });
    }
}
_a = Trakt;
Trakt.CLIENT_ID = "0a4b47986a50894f19f24aad11101514993592db3c9a63e12e2d573504e1adbb";
Trakt.CLIENT_SECRET = "4640a2e220cc5e8a0eebf692389d28cd542b92e893850d0e737456835c85a4b5";
Trakt.SECRET_KEY = "your_secret_key_here";
Trakt._header = {
    "Content-Type": "application/json",
    "trakt-api-version": "2",
    "trakt-api-key": _a.CLIENT_ID,
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
};
Trakt.pending = new Map();
