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
                res.status(201).json({ error: "Failed to fetch access token" });
            }
            else {
                if (response.status == 200) {
                    const data = await response.json();
                    if (req.cookies.auth != undefined) {
                        var verify = Login.verifyToken(req.cookies.auth);
                        console.log(`Saving Trakt Login for: ${verify.email} data is: ${data}`);
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
    static async refreshToken(trakt_user) {
        const response = await fetch("https://api.trakt.tv/oauth/token", {
            method: "POST",
            headers: this._header,
            body: JSON.stringify({
                refresh_token: trakt_user.refresh_token,
                client_id: this.CLIENT_ID,
                client_secret: this.CLIENT_SECRET,
                redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                grant_type: 'refresh_token'
            }),
        });
        if (response.ok) {
            var json = await response.json();
            DB.syncTrakt(trakt_user.user_email, { access_token: json.access_token, refresh_token: json.refresh_token, expires_in: json.expires_in });
            console.log("Obtained new access token");
            return true;
        }
        else {
            console.log("Refresh token isn't valid" + response.status + " " + response.statusText);
            console.log(await response.text());
            return false;
        }
    }
    static async verifySession(user) {
        var trakt_user = DB.getTraktUser(user.email);
        if (trakt_user != undefined) {
            if (Date.now() > trakt_user?.expires_at) {
                console.log("Token expired");
                return await this.refreshToken(trakt_user);
            }
            return true;
        }
        return false;
    }
    static async startWatching(app) {
        app.post("/trakt/start_watching", async (req, res) => {
            if (!req.cookies.auth)
                return res.sendStatus(300);
            var verify = Login.verifyToken(req.cookies.auth);
            const accessToken = this.accessToken(req.cookies.auth);
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
            console.log(`AccessToken: ${accessToken}`);
            const response = await fetch(`https://api.trakt.tv/sync/watched/${type}?extended=full`, {
                headers: {
                    ...this._header,
                    Authorization: `Bearer ${accessToken}`,
                },
            });
            if (!response.ok)
                throw new Error("Failed to fetch watched: " + (await response.status));
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
    static async obtainShowProgress(app) {
        app.get("/trakt/show_progress/:traktId", async (req, res) => {
            if (!req.cookies.auth)
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
    "User-Agent": "BlssmPetal/1.0.0",
};
