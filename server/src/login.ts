import express from "express";
import jwt from "jsonwebtoken";
import crypto, { randomUUID } from "crypto";
import { DB, User } from "./db.js";
import bcrypt from "bcrypt";

export abstract class Login {
  static SECRET_KEY = "your_secret_key_here";

  public static verifyToken(token: string) {
    return jwt.verify(token, this.SECRET_KEY);
  }

  public static async verifyLogin(app: express.Express) {
    app.post("/login/register", async (req, res) => {
      console.log(req.body);
      try {
        var email = req.body.email;
        var password = req.body.password;
        var registerToken = req.body.token;

        if (
          email == undefined ||
          password == undefined ||
          registerToken == undefined
        )
          throw new Error("Missing Email, Password, or Register Token");

        // TODO: Check if email and password matches the database.

        if (registerToken == "token") {
          console.log("Token accepted");

          const user = DB.db
            .prepare(`SELECT * FROM users WHERE email = ?`)
            .get(email) as User | undefined;

          if (user != undefined) {
            res.status(200).json({ status: "already-exist" });
            return;
          }
          const uuid: string = crypto.randomUUID();

          DB.addUser({ email: email, password: password, key: uuid });

          var token = jwt.sign({ email: email, uuid: uuid }, this.SECRET_KEY);

          res.cookie("auth", token);

          res.status(200).json({ status: "success" });
          return;
        }

        throw new Error("Incorrect Login");
      } catch (_) {
        res.status(201).json({ ok: false });
      }
    });
    app.post("/login/signin", async (req, res) => {
      console.log(req.body);
      try {
        var email = req.body.email;
        var password = req.body.password;

        if (email == undefined || password == undefined)
          throw new Error("Missing Email or Password");

        // TODO: Check if email and password matches the database.

        const user = DB.db
          .prepare(`SELECT * FROM users WHERE email = ?`)
          .get(email) as User | undefined;

        if (!user) {
          res.status(200).json({ ok: false });
          return;
        }

        const match = await bcrypt.compare(password, user.password);

        if (match) {
          var uuid = user.key;
          var token = jwt.sign({ email: email, key: uuid }, this.SECRET_KEY);

          res.cookie("auth", token);

          res.status(200).json({ status: "success", token: token });
          return;
        }

        throw new Error("Incorrect Login");
      } catch (_) {
        res.status(200).json({ status: "failed" });
      }
    });
    app.get("/login/verify", async (req, res) => {
      if (req.cookies.auth != undefined && req.cookies.key != undefined) {
        console.log(req.cookies.auth);
        var verify = this.verifyToken(req.cookies.auth) as jwt.JwtPayload;

        const user = DB.db
          .prepare(`SELECT * FROM users WHERE email = ?`)
          .get(verify.email) as User | undefined;

        if (user != undefined && verify.key == user.key) {
          console.log("User verified");
          res.status(200).json({ status: "success" });
          return;
        }

        console.log("User NOT verified");

       res.status(200).json({ status: "fail" });
      } else {
        res.status(200).json({ status: "fail" });
      }
    });
  }
}
