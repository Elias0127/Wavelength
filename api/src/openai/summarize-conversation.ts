import express from "express";
import OpenAI from "openai";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

const router = express.Router();

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

interface ConversationSummarizationRequest {
  conversation: string;
  instructions: string;
}

interface ConversationSummary {
  title: string;
  content: string;
  emotionalState: string;
  tags: string[];
  overallMood: string;
}

router.post("/summarize-conversation", async (req, res) => {
  try {
    const { conversation, instructions }: ConversationSummarizationRequest =
      req.body;

    if (!conversation || !instructions) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: instructions,
        },
        {
          role: "user",
          content: conversation,
        },
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });

    const response = completion.choices[0]?.message?.content;

    if (!response) {
      throw new Error("No response from OpenAI");
    }

    // Parse the response to extract structured data
    const summary = parseConversationSummary(response);

    res.json(summary);
  } catch (error) {
    console.error("Error summarizing conversation:", error);
    res.status(500).json({
      error: "Failed to summarize conversation",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

function parseConversationSummary(response: string): ConversationSummary {
  // Try to parse as JSON first
  try {
    const parsed = JSON.parse(response);
    return {
      title: parsed.title || "Conversation Reflection",
      content: parsed.content || response,
      emotionalState: parsed.emotionalState || "Reflective",
      tags: parsed.tags || ["conversation", "reflection"],
      overallMood: parsed.overallMood || "Thoughtful",
    };
  } catch {
    // If not JSON, try to extract structured information from text
    const lines = response.split("\n").filter((line) => line.trim());

    let title = "Conversation Reflection";
    let content = response;
    let emotionalState = "Reflective";
    let tags = ["conversation", "reflection"];
    let overallMood = "Thoughtful";

    // Look for title patterns
    const titleMatch = response.match(/(?:title|Title):\s*(.+)/i);
    if (titleMatch) {
      title = titleMatch[1].trim();
    }

    // Look for emotional state patterns
    const emotionMatch = response.match(
      /(?:emotional state|mood|feeling):\s*(.+)/i
    );
    if (emotionMatch) {
      emotionalState = emotionMatch[1].trim();
    }

    // Look for mood patterns
    const moodMatch = response.match(/(?:overall mood|mood|feeling):\s*(.+)/i);
    if (moodMatch) {
      overallMood = moodMatch[1].trim();
    }

    // Extract tags from common emotional words
    const emotionalWords = [
      "anxious",
      "calm",
      "happy",
      "sad",
      "grateful",
      "worried",
      "hopeful",
      "overwhelmed",
      "peaceful",
      "stressed",
      "content",
      "reflective",
      "thoughtful",
      "insightful",
      "emotional",
    ];

    const foundTags = emotionalWords.filter((word) =>
      response.toLowerCase().includes(word)
    );

    if (foundTags.length > 0) {
      tags = [...new Set([...tags, ...foundTags])];
    }

    return {
      title,
      content,
      emotionalState,
      tags,
      overallMood,
    };
  }
}

export { router as summarizeConversationRoutes };
