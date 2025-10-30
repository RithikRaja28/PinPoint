#!/usr/bin/env python3
"""
orchestrate_automate.py
- Exchanges IBM API key for IAM token (cached & auto-refresh)
- Calls Orchestrate allskills endpoint for your instance
- Set env vars: IBM_API_KEY, ORCHESTRATE_INSTANCE_ID (or use CREDS JSON), ORCHESTRATE_BASE_URL (optional)
"""

import os, time, threading, requests, json, urllib.parse, socket

# ---------- CONFIG (prefer env vars) ----------
API_KEY = os.environ.get("IBM_API_KEY","v1pmmtgXLZAvG22sDW9sqZBqPlojj4VzAlRbk8oHk41l")  # required: your IBM API key (from IAM or service credentials)
INSTANCE_ID = os.environ.get("ORCHESTRATE_INSTANCE_ID", "0d536afc-582d-49bb-a1d2-44cbfed2f954")
BASE_URL = os.environ.get("ORCHESTRATE_BASE_URL", "https://api.jp-tok.watson-orchestrate.cloud.ibm.com")
DEBUG = os.environ.get("ORCH_DEBUG", "1") == "1"
# ------------------------------------------------

IAM_TOKEN_URL = "https://iam.cloud.ibm.com/identity/token"

_token_lock = threading.Lock()
_token_cache = {"access_token": None, "expires_at": 0}

def fetch_new_iam_token(api_key):
    if not api_key:
        raise ValueError("IBM_API_KEY not set")
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = {
        "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
        "apikey": api_key
    }
    # use basic auth bx:bx like curl examples
    r = requests.post(IAM_TOKEN_URL, headers=headers, data=data, auth=("bx", "bx"), timeout=10)
    r.raise_for_status()
    j = r.json()
    token = j["access_token"]
    expires_in = int(j.get("expires_in", 3600))
    expires_at = time.time() + expires_in
    if DEBUG:
        print(f"[DEBUG] fetched IAM token (expires_in={expires_in}s)")
    return token, expires_at

def get_iam_token(api_key, refresh_window_seconds=60):
    with _token_lock:
        if _token_cache["access_token"] and (_token_cache["expires_at"] - time.time() > refresh_window_seconds):
            return _token_cache["access_token"]
        token, expires_at = fetch_new_iam_token(api_key)
        _token_cache["access_token"] = token
        _token_cache["expires_at"] = expires_at
        return token

def test_network(hostname):
    try:
        socket.getaddrinfo(hostname, 443)
    except Exception as e:
        raise RuntimeError(f"DNS resolution failed for {hostname}: {e}")
    try:
        s = socket.create_connection((hostname, 443), timeout=5)
        s.close()
    except Exception as e:
        raise RuntimeError(f"TCP connect to {hostname}:443 failed: {e}")

def call_allskills(base_url, api_key, instance_id):
    parsed = urllib.parse.urlparse(base_url)
    if not parsed.hostname:
        raise ValueError("Invalid ORCHESTRATE_BASE_URL")
    # quick network test so errors are clear
    test_network(parsed.hostname)

    token = get_iam_token(api_key)
    url = f"{base_url.rstrip('/')}/instances/{instance_id}/v1/orchestrate/digital-employees/allskills"
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    resp = requests.get(url, headers=headers, timeout=20)
    if resp.status_code == 401:
        # force refresh and retry once
        token = get_iam_token(api_key, refresh_window_seconds=0)
        headers["Authorization"] = f"Bearer {token}"
        resp = requests.get(url, headers=headers, timeout=20)
    resp.raise_for_status()
    return resp.json()

def main():
    if not API_KEY:
        print("ERROR: set IBM_API_KEY environment variable with a valid API key.")
        return
    try:
        result = call_allskills(BASE_URL, API_KEY, INSTANCE_ID)
        print(json.dumps(result, indent=2))
    except requests.HTTPError as e:
        print("HTTP error:", e.response.status_code, e.response.text)
    except Exception as ex:
        print("Error:", ex)

if __name__ == "__main__":
    main()
