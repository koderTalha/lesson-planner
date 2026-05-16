from __future__ import annotations

import json
import os

import requests


def _api_key() -> str:
    return os.getenv("GEMINI_API_KEY", "").strip()


def _model() -> str:
    return os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip() or "gemini-2.5-flash"


def generate_json(system: str, user_text: str) -> dict:
    key = _api_key()
    if not key:
        raise RuntimeError("GEMINI_API_KEY is not set")
    model = _model()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    body = {
        "systemInstruction": {"parts": [{"text": system}]},
        "contents": [{"parts": [{"text": user_text}]}],
        "generationConfig": {"responseMimeType": "application/json"},
    }
    res = requests.post(
        url,
        params={"key": key},
        headers={"Content-Type": "application/json"},
        data=json.dumps(body),
        timeout=90,
    )
    if res.status_code < 200 or res.status_code >= 300:
        raise RuntimeError(f"Gemini failed ({res.status_code}): {res.text}")
    decoded = res.json()
    candidates = decoded.get("candidates") or []
    first = candidates[0] if candidates else {}
    content = first.get("content") or {}
    parts = content.get("parts") or []
    text = (parts[0] or {}).get("text") if parts else ""
    if not text or not str(text).strip():
        raise RuntimeError("Empty Gemini response")
    return json.loads(text)

