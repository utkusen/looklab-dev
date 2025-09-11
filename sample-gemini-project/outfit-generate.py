api_key = "AIzaSyAzotjmunHu2BfErbc9X0NantRfxmZA9Gk"
model = "gemini-2.5-flash-image-preview"

import base64
import json
import os
import sys
from typing import Dict, List, Optional
import copy

import requests


def read_text_file(file_path: str) -> str:
    """Read and return the contents of a text file."""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()


def file_exists(file_path: str) -> bool:
    """Return True if file exists and is a file."""
    return os.path.isfile(file_path)


def encode_file_base64(file_path: str) -> str:
    """Return base64-encoded string of the given file."""
    with open(file_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def build_image_part(file_path: str) -> Dict[str, Dict[str, str]]:
    """Build an inlineData part for the Gemini API from a local image file."""
    # Infer mime type from extension; default to image/webp for provided assets
    ext = os.path.splitext(file_path)[1].lower()
    mime_map = {
        ".webp": "image/webp",
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
    }
    mime_type = mime_map.get(ext, "image/webp")
    return {
        "inlineData": {
            "data": encode_file_base64(file_path),
            "mimeType": mime_type,
        }
    }


def collect_inputs(base_dir: str) -> Dict[str, object]:
    """Collect and map available local images into the expected prompt structure."""
    paths = {
        # Arrays below
        "TOPS": [
            os.path.join(base_dir, "top.webp"),
            os.path.join(base_dir, "outwear.webp"),  # treat outerwear as an additional top layer if present
        ],
        "BOTTOMS": [os.path.join(base_dir, "bottom.webp")],
        "SHOES": [os.path.join(base_dir, "shoe.webp")],
        "ACCESSORIES": [os.path.join(base_dir, "accessories.webp")],
        # FULL_OUTFIT: none provided in this folder, keep as empty list
        "FULL_OUTFIT": [],
    }

    return paths


def build_parts_from_inputs(inputs: Dict[str, object]) -> List[Dict[str, object]]:
    """Turn the mapped inputs into a sequence of Gemini content parts with labels."""
    parts: List[Dict[str, object]] = []
    parts.append({
        "text": (
            "Here are the user data:"
        )
    })

    # Add a textual face description instead of uploading a face image
    parts.append({"text": "FACE_DESC: Blonde male"})

    # Add a textual body description instead of uploading a body image
    parts.append({"text": "BODY_DESC: 1.73 height, 120kg, black skin"})

    # No single body or face images are sent

    # Arrays
    array_keys = ["TOPS", "BOTTOMS", "SHOES", "ACCESSORIES", "FULL_OUTFIT"]
    for key in array_keys:
        paths: List[str] = [p for p in inputs.get(key, []) if isinstance(p, str) and file_exists(p)]  # type: ignore[arg-type]
        if not paths:
            continue
        parts.append({"text": f"{key}[]:"})
        for p in paths:
            parts.append(build_image_part(p))

    # Add environment info and notes per user request
    parts.append({"text": "ENV_INFO: Busy street"})
    parts.append({"text": "NOTES: none"})

    # Minimal additional guidance that avoids sensitive phrasing

    return parts


def find_generated_image_data(response_json: Dict[str, object]) -> Optional[Dict[str, str]]:
    """Extract inline image data (data + mimeType) from a generateContent response, if present."""
    candidates = response_json.get("candidates", [])
    if not isinstance(candidates, list) or not candidates:
        return None
    content = candidates[0].get("content", {})
    parts = content.get("parts", []) if isinstance(content, dict) else []
    if not isinstance(parts, list):
        return None
    for part in parts:
        if isinstance(part, dict) and "inlineData" in part:
            inline = part["inlineData"]
            if isinstance(inline, dict) and inline.get("data"):
                # Return both data and mimeType if available
                return {
                    "data": inline.get("data"),
                    "mimeType": inline.get("mimeType", "image/png"),
                }
    return None


def print_full_message(payload: Dict[str, object], save_to_path: Optional[str] = None) -> None:
    """Print the request payload with base64 data truncated, and optionally save it."""

    def _truncate_b64(s: str, max_chars: int = 64) -> str:
        if len(s) <= max_chars:
            return s
        return f"{s[:max_chars]}... (truncated, len={len(s)})"

    def _sanitize(obj: object) -> object:
        # Recursively copy and truncate inline base64 data
        if isinstance(obj, dict):
            new_d: Dict[str, object] = {}
            for k, v in obj.items():
                if k in ("inlineData", "inline_data") and isinstance(v, dict):
                    new_inline: Dict[str, object] = {}
                    for ik, iv in v.items():
                        if ik in ("data", "bytes") and isinstance(iv, str):
                            new_inline[ik] = _truncate_b64(iv)
                        else:
                            new_inline[ik] = _sanitize(iv)
                    new_d[k] = new_inline
                else:
                    new_d[k] = _sanitize(v)
            return new_d
        if isinstance(obj, list):
            return [_sanitize(i) for i in obj]
        return obj

    sanitized = _sanitize(copy.deepcopy(payload))

    print("=== Gemini Request Payload (truncated) ===")
    print(json.dumps(sanitized, ensure_ascii=False, indent=2))
    if save_to_path:
        try:
            with open(save_to_path, "w", encoding="utf-8") as f:
                json.dump(sanitized, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Failed to save request payload to {save_to_path}: {e}")


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))

    # Read the system prompt
    prompt_path = os.path.join(base_dir, "prompt.txt")
    if not file_exists(prompt_path):
        print("prompt.txt not found.")
        sys.exit(1)
    system_prompt = read_text_file(prompt_path)

    # Collect and encode inputs
    inputs = collect_inputs(base_dir)
    user_parts = build_parts_from_inputs(inputs)

    # Build request
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload: Dict[str, object] = {
        "systemInstruction": {
            "role": "system",
            "parts": [{"text": system_prompt}],
        },
        "contents": [
            {
                "role": "user",
                "parts": user_parts,
            }
        ],
    }

    # Print the full message being sent to the API and also save it locally
    print_full_message(payload, os.path.join(base_dir, "last_request_payload.json"))

    headers = {"Content-Type": "application/json"}

    try:
        resp = requests.post(url, headers=headers, data=json.dumps(payload), timeout=120)
    except Exception as e:
        print(f"Request failed: {e}")
        sys.exit(1)

    if resp.status_code != 200:
        print(f"Error {resp.status_code}: {resp.text}")
        sys.exit(1)

    resp_json = resp.json()
    image_part = find_generated_image_data(resp_json)
    if not image_part:
        print("No image found in response. Full response:\n" + json.dumps(resp_json, indent=2))
        sys.exit(1)

    # Save image
    image_data_b64 = image_part["data"]
    mime_type = image_part.get("mimeType", "image/png")
    ext = ".png" if mime_type == "image/png" else ".jpg"
    out_path = os.path.join(base_dir, f"generated_outfit{ext}")
    with open(out_path, "wb") as f:
        f.write(base64.b64decode(image_data_b64))

    print(f"Saved generated image to: {out_path}")


if __name__ == "__main__":
    main()
