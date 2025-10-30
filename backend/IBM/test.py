#!/usr/bin/env python3
# pip install requests

import os
import sys
import time
import json,re
import threading
import requests
from typing import Optional
CODE_FENCE_RE = re.compile(r"^```(?:html\s*)?\n?|```$", flags=re.MULTILINE)


"""
{
  "type": "object",
  "required": ["shop_name","campaign_title","offer","tone","colors","language"],
  "properties": {
    "shop_name": {"type":"string","minLength":1},
    "campaign_title": {"type":"string","minLength":1},
    "offer": {"type":"string","minLength":1},
    "tone": {"type":"string","enum":["playful","luxury","professional","friendly","energetic","calm","romantic","minimal"]},
    "colors": {
      "type":"object",
      "properties": {
        "primary": {"type":"string"},
        "accent": {"type":"string"},
        "bg": {"type":"string"}
      },
      "required":["primary","accent","bg"]
    },
    "logo_url": {"type":"string","format":"uri"},
    "product_images": {
      "type":"array",
      "items":{"type":"string","format":"uri"},
      "maxItems":4
    },
    "language": {"type":"string","minLength":2}
  }
}
    
"""
# === Configuration: set these via environment or edit here ===
# Recommended: export IBM_API_KEY, HOSTNAME, TENANT_ID in your environment.
IBM_API_KEY = os.environ.get("IBM_API_KEY","v1pmmtgXLZAvG22sDW9sqZBqPlojj4VzAlRbk8oHk41l")  # required
HOSTNAME = os.environ.get("HOSTNAME", "api.jp-tok.watson-orchestrate.cloud.ibm.com")  # e.g. "us-south.orchestrate.cloud.ibm.com"
TENANT_ID = os.environ.get("TENANT_ID", "0d536afc-582d-49bb-a1d2-44cbfed2f954")  # e.g. "abcd1234"
AGENT_ID = os.environ.get("AGENT_ID", "88e7c48e-6d25-4e6c-894e-3093b862360f")


# Streaming path and URL
STREAM_PATH = f"/instances/{TENANT_ID}/v1/orchestrate/runs/stream"
URL = f"https://{HOSTNAME}{STREAM_PATH}"

# Query params (adjust if needed)
PARAMS = {"stream_timeout": 60000, "multiple_content": "false"}

# === IAM token config & cache ===
IAM_TOKEN_URL = "https://iam.cloud.ibm.com/identity/token"
DEBUG = True
REFRESH_BEFORE_EXP_SECONDS = 60

_token_lock = threading.Lock()
_token_cache = {}  # cache_key -> {"access_token": ..., "expires_at": ...}
_session = requests.Session()

class StreamExtractor:
    """
    General-purpose streaming assembler for Orchestrate-like SSE JSON lines.
    Usage:
      se = StreamExtractor()
      for raw in resp.iter_lines(decode_unicode=True):
          se.feed_raw_line(raw)
      text = se.get_text()            # assembled text (deltas + final)
      msg_obj = se.get_message_obj()  # the final 'message' object, if any
    """

    def __init__(self):
        self._chunks = []           # streaming delta text pieces (in order)
        self._final_chunks = []     # final message.created text parts
        self._message_obj = None
        self._last_json = None

    def feed_raw_line(self, raw_line: str) -> None:
        """
        Feed one raw line from resp.iter_lines(decode_unicode=True).
        Handles SSE-style "data: ..." lines and JSON decode errors gracefully.
        """
        if not raw_line:
            return
        line = raw_line.strip()
        if line.startswith("data:"):
            line = line[len("data:"):].strip()
        if not line or line in ("[DONE]", "done"):
            return

        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            # Non-JSON content — ignore or you can log it
            return

        self._last_json = obj
        evt = obj.get("event")
        data = obj.get("data", {})

        # accumulate streaming deltas
        if evt == "message.delta":
            delta = data.get("delta", {})
            for c in delta.get("content", []):
                # handle both text and code-like response types
                if c.get("response_type") in ("text", "message", "output"):
                    t = c.get("text") or ""
                    if t:
                        self._chunks.append(t)

        # capture final created message (authoritative)
        if evt == "message.created":
            message = data.get("message", {})
            self._message_obj = message
            # collect any text pieces in final message content
            for c in message.get("content", []):
                if c.get("response_type") in ("text", "message", "output"):
                    t = c.get("text") or ""
                    if t:
                        self._final_chunks.append(t)

    def get_text(self) -> str:
        """
        Return assembled textual output: deltas followed by final content (if any).
        """
        # prefer final chunks because they're authoritative, but include deltas as fallback
        if self._final_chunks:
            # Some streams include both delta + final; concatenating both is safe.
            return "".join(self._chunks + self._final_chunks).strip()
        return "".join(self._chunks).strip()

    def get_message_obj(self):
        """Return the final 'message' object if present (message.created)."""
        return self._message_obj

    def clear(self):
        """Reset internal buffers for next run."""
        self._chunks = []
        self._final_chunks = []
        self._message_obj = None
        self._last_json = None


def extract_html_from_text(text: str, strict: bool = True) -> Optional[str]:
    """
    Given assembled text, return cleaned HTML string or None.
    - Removes leading/trailing triple-backtick fences.
    - If strict=True, only return if text appears to start with a full HTML document.
    - If strict=False, try to locate first '<!doctype' or '<html' and return substring from there.
    """
    if not text:
        return None

    # Remove common markdown code fences around the content
    cleaned = CODE_FENCE_RE.sub("", text).strip()

    # If the model returned JSON such as {"html":"<...>"} try to parse it
    # (safe-guard: don't crash on invalid JSON)
    try:
        maybe_json = json.loads(cleaned)
        if isinstance(maybe_json, dict):
            # accept keys like 'html' or 'content'
            for k in ("html", "content", "body"):
                if k in maybe_json and isinstance(maybe_json[k], str):
                    candidate = maybe_json[k].strip()
                    # remove code fences inside json string
                    candidate = CODE_FENCE_RE.sub("", candidate).strip()
                    cleaned = candidate
                    break
    except Exception:
        # not JSON — ignore
        pass

    lower = cleaned.lstrip().lower()
    if lower.startswith("<!doctype") or lower.startswith("<html"):
        return cleaned

    if strict:
        # not a full HTML doc
        return None

    # non-strict: try to find first occurrence of an HTML doc start
    idx_doctype = lower.find("<!doctype")
    idx_html = lower.find("<html")
    idxs = [i for i in (idx_doctype, idx_html) if i >= 0]
    if not idxs:
        return None
    start = min(idxs)
    return cleaned[start:].strip()


def fetch_new_iam_token(api_key, timeout=10):
    """
    Fetch a new IAM token from IBM for the given API key.
    Returns (access_token, expires_at_unix_seconds).
    """
    if not api_key:
        raise ValueError("IBM_API_KEY not set")

    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = {
        "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
        "apikey": api_key,
    }
    # IBM examples use basic auth "bx:bx"
    resp = _session.post(IAM_TOKEN_URL, headers=headers, data=data, auth=("bx", "bx"), timeout=timeout)
    resp.raise_for_status()
    j = resp.json()
    token = j["access_token"]
    expires_in = int(j.get("expires_in", 3600))
    expires_at = time.time() + expires_in
    if DEBUG:
        print(f"[DEBUG] fetched IAM token (expires_in={expires_in}s, expires_at={expires_at})")
    return token, expires_at


def get_iam_token(api_key=None, cache_key="default", refresh_before=REFRESH_BEFORE_EXP_SECONDS):
    """
    Return a valid IAM token for use in Authorization headers.
    Thread-safe and caches tokens until near expiry.
    """
    if api_key is None:
        api_key = IBM_API_KEY or os.environ.get("IBM_API_KEY")
    if not api_key:
        raise ValueError("IBM_API key is required (set IBM_API_KEY env var or pass explicitly)")

    now = time.time()

    # Fast path: return cached token if still valid
    with _token_lock:
        entry = _token_cache.get(cache_key)
        if entry:
            token = entry.get("access_token")
            expires_at = entry.get("expires_at", 0)
            if token and (expires_at - now) > refresh_before:
                if DEBUG:
                    print(f"[DEBUG] using cached token, expires_in={int(expires_at - now)}s")
                return token

    # Need new token. Acquire lock and double-check to avoid stampede.
    with _token_lock:
        entry = _token_cache.get(cache_key)
        if entry:
            token = entry.get("access_token")
            expires_at = entry.get("expires_at", 0)
            if token and (expires_at - time.time()) > refresh_before:
                if DEBUG:
                    print(f"[DEBUG] another thread refreshed token; using cached token")
                return token

        # fetch new one and cache
        token, expires_at = fetch_new_iam_token(api_key)
        _token_cache[cache_key] = {"access_token": token, "expires_at": expires_at}
        return token


def stream_to_orchestrate(url, agent_id, api_key=None, payload=None, params=None, verify=True, timeout=(10, None)):
    """
    Make the streaming request to the Orchestrate API, automatically handling IAM token creation/refresh.
    This function performs the streaming and prints each event line as JSON or RAW.
    """
    if payload is None:
        raise ValueError("payload is required")

    token = get_iam_token(api_key=api_key)
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    # Use streaming request
    # We pass params (query string), stream=True, and a reasonable timeout tuple.
    if params is None:
        params = PARAMS

    try:
        with _session.post(url, headers=headers, json=payload, params=params, stream=True, timeout=timeout, verify=verify) as resp:
            # If status is not 200, raise with details.
            if resp.status_code != 200:
                # Print response text for debugging and raise
                text = resp.text
                print("HTTP error:", resp.status_code, text)
                resp.raise_for_status()

            print("Streaming started...")

            # inside stream_to_orchestrate, after resp is open:
            extractor = StreamExtractor()

            for raw in resp.iter_lines(decode_unicode=True):
                if not raw:
                    continue
                extractor.feed_raw_line(raw)

            # after streaming completes (or when you see message.created), get text:
            assembled_text = extractor.get_text()

            # Try HTML strict extraction first; if None, try relaxed
            html = extract_html_from_text(assembled_text, strict=True)
            if html is None:
                html = extract_html_from_text(assembled_text, strict=False)

            if html:
                with open("poster.html", "w", encoding="utf-8") as f:
                    f.write(html)
                print("Saved HTML to poster.html")
            else:
                # fallback: save assembled plain text for debugging
                with open("assistant_output.txt", "w", encoding="utf-8") as f:
                    f.write(assembled_text)
                print("No HTML found — saved assembled text to assistant_output.txt")

            
    except requests.exceptions.RequestException as e:
        # network / HTTP errors land here
        print("Request error during streaming:", e)
        raise


def build_payload(agent_id, user_text):
    """
    Build the payload expected by your Orchestrate endpoint.
    Adjust fields as your API expects.
    """
    return {
        "message": {
            "role": "user",
            "content": [
                {"response_type": "text", "text": user_text}
            ]
        },
        "agent_id": agent_id,
    }


def main():
    # Basic validation
    if IBM_API_KEY is None:
        print("ERROR: IBM_API_KEY environment variable not set. Export it and re-run.")
        sys.exit(2)
    if "<your-tenant-id>" in TENANT_ID or TENANT_ID == "":
        print("WARNING: TENANT_ID looks like a placeholder. Set TENANT_ID env var or edit the script.")
    if HOSTNAME == "api.example.com":
        print("WARNING: HOSTNAME is the default placeholder. Set HOSTNAME env var to your Orchestrate hostname if needed.")

    user_text ="You are a poster HTML generator. Produce a single complete HTML snippet (no commentary) for a responsive poster using the following JSON input. Output only the HTML code (start with <!doctype html>). Input: { \"shop_name\": \"Luna & Bloom\", \"campaign_title\": \"Winter Radiance Sale\", \"offer\": \"Up to 40% off skincare essentials\", \"logo_url\": \"https://...jpg\", \"language\": \"en\", \"alignment\": \"center\", \"dimensions\": { \"height_px\": 600 } }"

    payload = build_payload(AGENT_ID, user_text)

    try:
        stream_to_orchestrate(URL, AGENT_ID, api_key=IBM_API_KEY, payload=payload, params=PARAMS, verify=True)
    except Exception as e:
        print("Error during streaming:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
