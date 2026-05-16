# Deploy to Google Cloud Run

## Prerequisites

1. [Google Cloud account](https://cloud.google.com/) with billing enabled (free tier still applies).
2. [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and logged in:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. Create or pick a project:
   ```bash
   gcloud projects create YOUR_PROJECT_ID   # optional
   export GCP_PROJECT_ID=YOUR_PROJECT_ID
   ```

## One-command deploy

From your machine, export secrets (do **not** commit these):

```bash
export GCP_PROJECT_ID=your-gcp-project-id
export GCP_REGION=us-central1

export GEMINI_API_KEY=your-gemini-key
export AUTH_API_KEY=your-app-auth-key
export JWT_SECRET=your-long-secret-at-least-32-characters
export GEMINI_MODEL=gemini-2.5-flash
```

Run:

```bash
cd product/server
chmod +x deploy/gcp/deploy.sh
./deploy/gcp/deploy.sh
```

Copy the printed `BACKEND_BASE_URL` into the Flutter app (Settings or `.env`).

## Manual deploy (same steps)

```bash
cd product/server
export GCP_PROJECT_ID=your-project
export IMAGE=gcr.io/$GCP_PROJECT_ID/lesson-planner-api

gcloud builds submit --tag "$IMAGE" .

gcloud run deploy lesson-planner-api \
  --image "$IMAGE" \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --timeout 300 \
  --set-env-vars GEMINI_API_KEY=xxx,AUTH_API_KEY=xxx,JWT_SECRET=xxx,GEMINI_MODEL=gemini-2.5-flash
```

## Production secrets (recommended)

Store keys in [Secret Manager](https://cloud.google.com/secret-manager) and mount on Cloud Run instead of plain env vars in the deploy script.

## Flutter app

```env
BACKEND_BASE_URL=https://lesson-planner-api-xxxxx-uc.a.run.app
AUTH_API_KEY=same-value-as-server-AUTH_API_KEY
```

On a physical device, use the **HTTPS** Cloud Run URL (not `127.0.0.1`).

## Costs

Cloud Run free tier includes monthly requests and CPU time. Idle scale-to-zero costs nothing. Monitor in GCP Console → Billing.
