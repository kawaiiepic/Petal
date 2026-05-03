import express from "express";
import jwt from "jsonwebtoken";
import { DB, TraktAccount, User } from "./db.js";
import { Login } from "./login.js";

export abstract class Trakt {
  static CLIENT_ID =
    "0a4b47986a50894f19f24aad11101514993592db3c9a63e12e2d573504e1adbb";
  static CLIENT_SECRET =
    "4640a2e220cc5e8a0eebf692389d28cd542b92e893850d0e737456835c85a4b5";
  static SECRET_KEY = "your_secret_key_here";
  static _header = {
    "Content-Type": "application/json",
    "trakt-api-version": "2",
    "trakt-api-key": this.CLIENT_ID,
    "User-Agent": "BlssmPetal/1.0.0",
  };

  public static deviceCode(app: express.Express) {
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

  public static async pollForAccessToken(app: express.Express) {
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
      } else {
        if (response.status == 200) {
          const data = await response.json();

          if (req.cookies.auth != undefined) {
            var verify = Login.verifyToken(req.cookies.auth) as jwt.JwtPayload;
            console.log(
              `Saving Trakt Login for: ${verify.email} data is: ${data}`,
            );

            DB.syncTrakt(verify.email, data);

            res.status(200).json({ status: "success" });
          }
          console.log("Access token received:", data);
        }
      }
    });
  }

  public static async userProfile(accessToken: string) {
    const response = await fetch(
      "https://api.trakt.tv/users/me?extended=full",
      {
        headers: {
          ...this._header,
          Authorization: `Bearer ${accessToken}`,
        },
      },
    );

    if (response.ok) {
      const data = await response.json();
      return data;
    } else {
      throw new Error("Failed to fetch user profile");
    }
  }

  public static verifyToken(token: string) {
    return jwt.verify(token, this.SECRET_KEY);
  }

  public static accessToken(auth: string) {
    try {
      var verify = Login.verifyToken(auth) as jwt.JwtPayload;
      return DB.getTraktAccessToken(verify.email);
    } catch (err) {
      console.error(err);
    }
  }

  public static async refreshToken(trakt_user: TraktAccount) {
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
    } else {
      console.log("Refresh token isn't valid" + response.status + " " + response.statusText);
      console.log(response.headers);
    }
  }

  public static async verifySession(user: User) {
    var trakt_user = DB.getTraktUser(user.email);

    if (trakt_user != undefined) {
      if (Date.now() > trakt_user?.expires_at) {
        console.log("Token expired");
        this.refreshToken(trakt_user);
      }
    }
  }

  public static async startWatching(app: express.Express) {
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
        } else {
          res.status(await response.status);
        }
      } else {
        res.status(300);
      }
    });
  }

  public static async obtainWatched(app: express.Express) {
    app.get("/trakt/sync_watched/:type", async (req, res) => {
      if (!req.cookies.auth) return res.sendStatus(300);

      // const username = this.getUsername(req.cookies.token);
      var verify = Login.verifyToken(req.cookies.auth) as jwt.JwtPayload;
      const accessToken = this.accessToken(req.cookies.auth);

      console.log(accessToken);
      const type = req.params.type;

      console.log(`AccessToken: ${accessToken}`);

      const response = await fetch(
        `https://api.trakt.tv/sync/watched/${type}?extended=full`,
        {
          headers: {
            ...this._header,
            Authorization: `Bearer ${accessToken}`,
          },
        },
      );

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


  public static async obtainShowProgress(app: express.Express) {
    app.get("/trakt/show_progress/:traktId", async (req, res) => {
      if (!req.cookies.auth) return res.sendStatus(300);

      var verify = Login.verifyToken(req.cookies.auth) as jwt.JwtPayload;
      const accessToken = this.accessToken(req.cookies.auth) as string;
      const traktId = req.params.traktId;

      const response = await fetch(
        `https://api.trakt.tv/shows/${traktId}/progress/watched?last_activity=watched`,
        {
          headers: {
            ...this._header,
            Authorization: `Bearer ${accessToken}`,
          },
        },
      );

      if (!response.ok) throw new Error("Failed to fetch progress");

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
