#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="$ROOT/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env in project root. Add GEMINI_API_KEY=… (and optional GEMINI_MODEL=…)"
  exit 1
fi

GEMINI_API_KEY=""
GEMINI_MODEL=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$line" ]] && continue
  key="${line%%=*}"
  val="${line#*=}"
  key="${key%"${key##*[![:space:]]}"}"
  if [[ "$key" == "GEMINI_API_KEY" ]]; then
    GEMINI_API_KEY="$val"
  elif [[ "$key" == "GEMINI_MODEL" ]]; then
    GEMINI_MODEL="$val"
  fi
done < "$ENV_FILE"

if [[ -z "$GEMINI_API_KEY" ]]; then
  echo "GEMINI_API_KEY is not set in .env"
  exit 1
fi

DEFINES=(--dart-define="GEMINI_API_KEY=$GEMINI_API_KEY")
if [[ -n "$GEMINI_MODEL" ]]; then
  DEFINES+=(--dart-define="GEMINI_MODEL=$GEMINI_MODEL")
fi

exec flutter build apk --release "${DEFINES[@]}"
