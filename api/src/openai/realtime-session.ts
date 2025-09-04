import express from "express";
import axios from "axios";

const router = express.Router();

interface OpenAISessionRequest {
  model: string;
  voice: string;
  instructions: string;
}

interface OpenAISessionResponse {
  token: string;
  sessionId: string;
}

/**
 * POST /api/openai/realtime/session
 * Purpose: Mint a temporary client token for gpt-realtime
 */
router.post("/realtime/session", async (req, res) => {
  try {
    const {
      model = "gpt-realtime",
      voice = "verse",
      instructions,
    }: OpenAISessionRequest = req.body;

    // Validate required environment variables
    const openaiApiKey = process.env.OPENAI_API_KEY;
    if (!openaiApiKey) {
      return res.status(500).json({
        error: "OpenAI API key not configured",
        message: "Please set OPENAI_API_KEY in environment variables",
      });
    }

    // Prepare request body for OpenAI
    const openaiRequestBody = {
      model,
      voice,
      instructions:
        instructions ||
        "You are a warm, trauma-informed counselor. Use OARS. Brief turns, gentle tone.",
    };

    console.log("🔗 Creating OpenAI Realtime session...");

    // Call OpenAI Realtime API
    const response = await axios.post(
      "https://api.openai.com/v1/realtime/sessions",
      openaiRequestBody,
      {
        headers: {
          Authorization: `Bearer ${openaiApiKey}`,
          "Content-Type": "application/json",
        },
        timeout: 10000, // 10 second timeout
      }
    );

    const sessionData = response.data;

    // Extract token and sessionId from OpenAI response
    const result: OpenAISessionResponse = {
      token: sessionData.client_secret?.value || sessionData.token,
      sessionId: sessionData.id || sessionData.session_id,
    };

    console.log(`✅ OpenAI Realtime session created: ${result.sessionId}`);

    res.json(result);
  } catch (error: any) {
    console.error("❌ OpenAI Realtime session creation failed:", error.message);

    if (error.response) {
      const status = error.response.status;
      const errorData = error.response.data;

      console.error(`OpenAI API Error ${status}:`, errorData);

      return res.status(status).json({
        error: "OpenAI API error",
        message:
          errorData.error?.message ||
          errorData.message ||
          "Unknown OpenAI error",
        details: errorData,
      });
    }

    res.status(500).json({
      error: "Failed to create OpenAI session",
      message: error.message || "Network error or timeout",
    });
  }
});

export { router as openaiRoutes };
