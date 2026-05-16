from __future__ import annotations

import os
import time
from typing import Any

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer


_bearer = HTTPBearer(auto_error=False)


def _secret() -> str:
    return os.getenv("JWT_SECRET", "").strip()

def _validated_secret() -> str:
    s = _secret()
    if not s:
        raise RuntimeError("JWT_SECRET is not set")
    if len(s.encode("utf-8")) < 32:
        raise RuntimeError("JWT_SECRET must be at least 32 bytes")
    return s


def _issuer() -> str:
    return os.getenv("JWT_ISSUER", "lesson-planner").strip() or "lesson-planner"


def _api_key() -> str:
    return os.getenv("AUTH_API_KEY", "").strip()


def create_access_token(sub: str, ttl_seconds: int = 60 * 60) -> str:
    secret = _validated_secret()
    now = int(time.time())
    payload: dict[str, Any] = {
        "iss": _issuer(),
        "sub": sub,
        "iat": now,
        "exp": now + ttl_seconds,
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def require_auth(
    creds: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict[str, Any]:
    if creds is None or not creds.credentials:
        raise HTTPException(status_code=401, detail="Missing bearer token")
    try:
        secret = _validated_secret()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    try:
        return jwt.decode(
            creds.credentials,
            secret,
            algorithms=["HS256"],
            issuer=_issuer(),
            options={"require": ["exp", "iat", "iss", "sub"]},
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


def verify_api_key(api_key: str) -> None:
    expected = _api_key()
    if not expected:
        raise HTTPException(status_code=500, detail="AUTH_API_KEY not configured")
    if api_key.strip() != expected:
        raise HTTPException(status_code=401, detail="Invalid api_key")

