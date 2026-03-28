import express from "express";
import jwt from "jsonwebtoken";
import crypto from "crypto";

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

        if (email == undefined || password == undefined || registerToken == undefined)
          throw new Error("Missing Email or Password");

        // TODO: Check if email and password matches the database.

        if (registerToken == "token") {
          const uuid: string = crypto.randomUUID();
          var token = jwt.sign({ email: email, uuid: uuid }, this.SECRET_KEY);

          res.cookie("auth", token);

          res.status(200).json({ email: email, cookies: req.cookies });
          return;
        }

        throw new Error("Incorrect Login");
      } catch (_) {
        res.status(200).json({ ok: false });
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

          if (email == "mia" && password == "password") {
              var token = jwt.sign({ email: email }, this.SECRET_KEY);

              res.cookie("auth", token);

              res.status(200).json({ email: email, cookies: req.cookies });
              return;
          }

          throw new Error("Incorrect Login");

      } catch (_) {
        res.status(200).json({ ok: false });
      }
    });
    app.get("/login/verify", async (req, res) => {
        if (req.cookies.auth != undefined) {
            console.log(req.cookies.auth);
            var verify = this.verifyToken(req.cookies.auth);

            // TODO: Check if login is still valid.

            res.status(200).json({verify: verify});
      } else {
        res.status(300).json({ verified: false });
      }
    });
  }
}
