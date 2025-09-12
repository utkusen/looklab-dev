import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";

initializeApp();

// Prompt (from sample-gemini-project/prompt.txt). Kept server-side per requirements.
const SYSTEM_PROMPT = `You are an expert fashion stylist and photorealistic image renderer. Your job is to:

- Pick and combine the user-supplied garments into a cohesive outfit that fits the user’s body type and notes,

- Preserve the overall proportions and style guidance,

- Render the final image in the requested environment with correct lighting.

- Avoid adding items that were not provided unless strictly necessary to complete the look (e.g., invisible socks or basic underlayers),

- Keep the output clean and photorealistic.

##

Inputs (pass as multimodal attachments + text):

FACE_DESC: short textual description of the face/hair (e.g., "Blonde short hair").

BODY_DESC: short textual description of body and skin (e.g., "1.73 height, 90kg, olive skin").

TOPS[]: zero or more images of tops.

BOTTOMS[]: zero or more images of bottoms.

SHOES[]: zero or more images of shoes.

ACCESSORIES[]: zero or more images (belts, bags, jewelry, hats, scarves, glasses, etc.).

FULL_OUTFIT[]: full-body garment images (e.g., dresses, jumpsuits).

ENV_INFO: description of the photo environment (e.g., the café, street, mirror selfie). If the user provides a photo, you may use it directly; otherwise synthesize.

NOTES: Extra notes from the user

##

Task:

Select items from the provided garment images to build a single coherent outfit. If an essential category is missing, add only subtle basics (e.g., no-logo plain socks or a simple belt) that do not contradict the style.

Apply notes exactly (e.g., “make shirt tucked,” “roll sleeves once,” “add belt”).

Tailor for body type: choose proportions and drape that flatter the stated body_type (e.g., high-waist for longer legs, vertical lines to elongate, avoid awkward bunching).

Use FACE_DESC and BODY_DESC for general style cues only. Do not recreate a specific real person's identity.

Render environment according to ENV_INFO with realistic lighting, shadows, reflections, and camera perspective.

Photoreal finish: correct fabric physics (no melting or clipping), plausible wrinkles, accurate seams/buttons, consistent scale of patterns, no duplicate limbs/fingers, no floating accessories, and no watermarks. Keep brand logos only if visible in source images.

Output requirements:

Generate one photorealistic square image.

Composition: full body unless user notes wants it otherwise (e.g., tight mirror selfie).`;

type InlineImage = { data: string; mimeType?: string };
type BuildLookRequest = {
  FACE_DESC?: string;
  BODY_DESC?: string;
  ENV_INFO?: string;
  NOTES?: string;
  TOPS?: InlineImage[];
  BOTTOMS?: InlineImage[];
  SHOES?: InlineImage[];
  ACCESSORIES?: InlineImage[];
  FULL_OUTFIT?: InlineImage[];
};

function partFromImage(img: InlineImage) {
  const mime = img.mimeType && img.mimeType.startsWith("image/") ? img.mimeType : "image/png";
  return { inlineData: { data: img.data, mimeType: mime } } as const;
}

function pushArrayParts(parts: any[], label: string, arr?: InlineImage[]) {
  if (arr && Array.isArray(arr) && arr.length > 0) {
    parts.push({ text: `${label}[]:` });
    for (const it of arr) parts.push(partFromImage(it));
  }
}

function extractImageFromResponse(resp: any): { data: string; mimeType: string } | null {
  const parts = resp?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return null;
  for (const p of parts) {
    const inline = p?.inlineData;
    if (inline?.data) {
      return { data: inline.data, mimeType: inline.mimeType || "image/png" };
    }
  }
  return null;
}

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

export const buildLook = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  // Enforce authentication for callable function invocations
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required to call buildLook.");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    logger.error("Missing GEMINI_API_KEY env var");
    throw new Error("Server not configured");
  }

  const data = (request.data || {}) as BuildLookRequest;

  const parts: any[] = [];
  parts.push({ text: "Here are the user data:" });
  if (data.FACE_DESC) parts.push({ text: `FACE_DESC: ${data.FACE_DESC}` });
  if (data.BODY_DESC) parts.push({ text: `BODY_DESC: ${data.BODY_DESC}` });

  pushArrayParts(parts, "TOPS", data.TOPS);
  pushArrayParts(parts, "BOTTOMS", data.BOTTOMS);
  pushArrayParts(parts, "SHOES", data.SHOES);
  pushArrayParts(parts, "ACCESSORIES", data.ACCESSORIES);
  pushArrayParts(parts, "FULL_OUTFIT", data.FULL_OUTFIT);

  if (data.ENV_INFO) parts.push({ text: `ENV_INFO: ${data.ENV_INFO}` });
  if (data.NOTES) parts.push({ text: `NOTES: ${data.NOTES}` });

  // Log a concise summary for debugging (no base64 data)
  logger.info("buildLook input", {
    FACE_DESC: !!data.FACE_DESC,
    BODY_DESC: !!data.BODY_DESC,
    ENV_INFO: data.ENV_INFO ?? null,
    counts: {
      TOPS: data.TOPS?.length ?? 0,
      BOTTOMS: data.BOTTOMS?.length ?? 0,
      SHOES: data.SHOES?.length ?? 0,
      ACCESSORIES: data.ACCESSORIES?.length ?? 0,
      FULL_OUTFIT: data.FULL_OUTFIT?.length ?? 0,
    },
  });

  const payload = {
    systemInstruction: {
      role: "system",
      parts: [{ text: SYSTEM_PROMPT }],
    },
    contents: [
      {
        role: "user",
        parts,
      },
    ],
  };

  const model = "gemini-2.5-flash-image-preview";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const txt = await resp.text();
    logger.error("Gemini error", { status: resp.status, body: txt });
    throw new Error(`Gemini error: ${resp.status}`);
  }

  const json = await resp.json();
  const image = extractImageFromResponse(json);
  if (!image) throw new Error("No image in Gemini response");

  return { image };
});
