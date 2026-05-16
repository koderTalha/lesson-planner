#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${GCP_REGION:-us-central1}"
SERVICE="${GCP_SERVICE_NAME:-lesson-planner-api}"
IMAGE="${GCP_IMAGE:-gcr.io/${PROJECT_ID}/${SERVICE}}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "Set GCP_PROJECT_ID (e.g. export GCP_PROJECT_ID=my-project-123)"
  exit 1
fi

for v in GEMINI_API_KEY AUTH_API_KEY JWT_SECRET; do
  if [[ -z "${!v:-}" ]]; then
    echo "Missing env var: $v"
    echo "Export it before running this script."
    exit 1
  fi
done

if [[ ${#JWT_SECRET} -lt 32 ]]; then
  echo "JWT_SECRET must be at least 32 characters."
  exit 1
fi

echo "Project: $PROJECT_ID  Region: $REGION  Service: $SERVICE"

gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

gcloud builds submit --tag "$IMAGE" .

gcloud run deploy "$SERVICE" \
  --image "$IMAGE" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 300 \
  --min-instances 0 \
  --max-instances 3 \
  --set-env-vars "GEMINI_MODEL=${GEMINI_MODEL:-gemini-2.5-flash}" \
  --set-env-vars "GEMINI_API_KEY=${GEMINI_API_KEY}" \
  --set-env-vars "AUTH_API_KEY=${AUTH_API_KEY}" \
  --set-env-vars "JWT_SECRET=${JWT_SECRET}"

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format 'value(status.url)')"
echo ""
echo "Deployed: $URL"
echo "Health:   $URL/health"
echo ""
echo "Flutter .env:"
echo "BACKEND_BASE_URL=$URL"
echo "AUTH_API_KEY=<same as AUTH_API_KEY above>"
