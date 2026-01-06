// server.js
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
const port = 3000;

// Simple in-memory storage (replace with DB later)
const userAddons = {
  mia: [
    {
      id: "torrentio",
      name: "Torrentio",
      manifestUrl:
        "https://torrentio.strem.fun/torbox=1b52e4c1-64cf-47bb-bd51-9924b18eb88f/manifest.json",
      icon: "https://torrentio.strem.fun/images/logo_v1.png",
      enabledResources: ["stream"],
      config: {},
    },

    {
      id: "comet",
      name: "Comet",
      manifestUrl:
        "https://comet.elfhosted.com/eyJtYXhSZXN1bHRzUGVyUmVzb2x1dGlvbiI6MCwibWF4U2l6ZSI6MCwiY2FjaGVkT25seSI6ZmFsc2UsInNvcnRDYWNoZWRVbmNhY2hlZFRvZ2V0aGVyIjpmYWxzZSwicmVtb3ZlVHJhc2giOnRydWUsInJlc3VsdEZvcm1hdCI6WyJhbGwiXSwiZGVicmlkU2VydmljZSI6InRvcmJveCIsImRlYnJpZEFwaUtleSI6IjFiNTJlNGMxLTY0Y2YtNDdiYi1iZDUxLTk5MjRiMThlYjg4ZiIsImRlYnJpZFN0cmVhbVByb3h5UGFzc3dvcmQiOiIiLCJsYW5ndWFnZXMiOnsiZXhjbHVkZSI6W10sInByZWZlcnJlZCI6WyJlbiJdfSwicmVzb2x1dGlvbnMiOnt9LCJvcHRpb25zIjp7InJlbW92ZV9yYW5rc191bmRlciI6LTEwMDAwMDAwMDAwLCJhbGxvd19lbmdsaXNoX2luX2xhbmd1YWdlcyI6ZmFsc2UsInJlbW92ZV91bmtub3duX2xhbmd1YWdlcyI6ZmFsc2V9fQ==/manifest.json",
      icon: "https://i.imgur.com/jmVoVMu.jpeg",
      enabledResources: ["stream"],
      config: {},
    },

    {
      id: "com.linvo.cinemeta",
      name: "Cinemeta",
      manifestUrl: "https://v3-cinemeta.strem.io/manifest.json",
      enabledResources: ["catalog"],
      config: {},
    },

    {
      id: "another-addon",
      name: "Example Addon",
      manifestUrl: "https://example.com/manifest.json",
      enabled: false,
      config: {},
    },
  ],
};

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Save addons for a user
app.post("/addons", (req, res) => {
  const { userId, addons } = req.body;
  if (!userId || !addons) {
    return res.status(400).json({ error: "Missing userId or addons" });
  }
  userAddons[userId] = addons;
  res.json({ success: true });
});

// Get addons for a user
app.get("/addons/:userId", (req, res) => {
  const { userId } = req.params;
  res.json({ addons: userAddons[userId] || [] });
});

app.listen(port, () => {
  console.log(`Backend server running at http://localhost:${port}`);
});
