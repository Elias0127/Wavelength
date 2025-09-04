import express from "express";

const router = express.Router();

interface HumeTokenResponse {
  token: string;
  config: {
    sampleRate: number;
    chunkMs: number;
  };
}

/**
 * POST /api/hume/token
 * Purpose: Provide a client with a non-permanent token to connect to Hume's realtime WS
 */
router.post("/token", async (req, res) => {
  try {
    const humeApiKey = process.env.HUME_API_KEY;
    if (!humeApiKey) {
      return res.status(500).json({
        error: "Hume API key not configured",
        message: "Please set HUME_API_KEY in environment variables",
      });
    }

    console.log("🎭 Providing Hume token for realtime connection...");

    const result: HumeTokenResponse = {
      token: humeApiKey,
      config: {
        sampleRate: 16000, // 16kHz mono PCM
        chunkMs: 1500, // 1.5 second chunks for prosody analysis
      },
    };

    console.log("✅ Hume token provided successfully");

    res.json(result);
  } catch (error: any) {
    console.error("❌ Hume token provision failed:", error.message);

    res.status(500).json({
      error: "Failed to provide Hume token",
      message: error.message || "Internal server error",
    });
  }
});

/**
 * GET /api/hume/config
 * Purpose: Get Hume configuration details for client setup
 */
router.get("/config", (req, res) => {
  const config = {
    sampleRate: 16000,
    chunkMs: 1500,
    websocketUrl: "wss://api.hume.ai/v0/evi/chat",
    supportedFeatures: ["prosody", "expression_measurement"],
    updateFrequency: 4, 
  };

  res.json(config);
});

export { router as humeRoutes };
