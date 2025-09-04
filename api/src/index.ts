import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { openaiRoutes } from "./openai/realtime-session";
import { summarizeConversationRoutes } from "./openai/summarize-conversation";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "http://localhost:8080",
      "http://127.0.0.1:3000",
      "http://10.0.0.188:3000",
    ],
    credentials: true,
  })
);
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api/openai", openaiRoutes);
app.use("/api/openai", summarizeConversationRoutes);

app.use(
  (
    err: any,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Error:", err);
    res.status(500).json({
      error: "Internal server error",
      message:
        process.env.NODE_ENV === "development"
          ? err.message
          : "Something went wrong",
    });
  }
);

app.use("*", (req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

app.listen(PORT, () => {
  console.log(`🚀 Wavelength API server running on port ${PORT}`);
  console.log(`📝 Health check: http://localhost:${PORT}/health`);
  console.log(
    `🔗 OpenAI Realtime: http://localhost:${PORT}/api/openai/realtime/session`
  );
});
