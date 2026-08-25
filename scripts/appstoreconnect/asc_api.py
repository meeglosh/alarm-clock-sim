#!/usr/bin/env python3
"""Minimal App Store Connect API client using stdlib urllib + PyJWT/cryptography.
Credentials never get printed. See ../../HANDOFF.md for key IDs and resource IDs.

Usage: python3 asc_api.py GET|POST|PATCH|DELETE <path> ['<json-body>']
"""
import json
import os
import time
import urllib.request
import urllib.error

import jwt

KEY_ID = "QGMKYYB893"
ISSUER_ID = "b24f8676-542c-4f39-93de-7f011745a5f0"
KEY_PATH = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_QGMKYYB893.p8")
BASE = "https://api.appstoreconnect.apple.com"


def make_token():
    with open(KEY_PATH) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 19 * 60,
        "aud": "appstoreconnect-v1",
    }
    headers = {"kid": KEY_ID, "typ": "JWT"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def call(method, path, body=None):
    token = make_token()
    url = BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw.decode(errors="replace")


if __name__ == "__main__":
    import sys
    method, path = sys.argv[1], sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    status, resp = call(method, path, body)
    print("STATUS:", status)
    print(json.dumps(resp, indent=2))
