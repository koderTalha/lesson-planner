# Lesson Planner Backend

Gemini-powered slide generation (no RAG).

## Run (local)

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
export AUTH_API_KEY="your-dev-key"
export JWT_SECRET="change-me-please-use-at-least-32-bytes-long-secret"
export GEMINI_API_KEY="your-gemini-key"
export GEMINI_MODEL="gemini-2.5-flash"
uvicorn app.main:app --reload --port 8000
```

- Health: `GET /health`
- Swagger: `GET /docs`
- Auth: `POST /api/v1/auth/token` with `{ "api_key": "..." }`
- List themes: `GET /api/v1/ppt/themes`
- Generate PPTX: `POST /api/v1/ppt/generate_ai` (Bearer token required)

### Generate body example

```json
{
  "subject": "Biology",
  "topic": "Introduction to Biology",
  "title": "Introduction to Biology",
  "subtitle": "Branches of biology",
  "slide_count": 10,
  "audience": "Grade 9 (high school)",
  "tone": "Clear, teacher-style, exam-focused",
  "theme": "classroom"
}
```

### Themes

Built-in themes: `brand` (Untitled Presentation — default), `classroom`, `ocean`, `forest`. Templates live in `assets/templates/`.

To update the default deck design, replace `assets/templates/untitled-presentation.pptx` with your PowerPoint file (keep **Title Slide** and **Title and Content** layouts).

To use a **custom PowerPoint theme**, design a `.pptx` in PowerPoint (Slide Master → colors/fonts), save it as `assets/templates/my-brand.pptx`, and pass `"theme": "my-brand"` (filename without extension). For best results, keep standard layouts named **Title Slide** and **Title and Content**.

## Deploy to GCP (Cloud Run)

See **[deploy/gcp/README.md](deploy/gcp/README.md)** for full steps.

Quick start:

```bash
export GCP_PROJECT_ID=your-project-id
export GEMINI_API_KEY=...
export AUTH_API_KEY=...
export JWT_SECRET=at-least-32-characters-long

cd product/server
chmod +x deploy/gcp/deploy.sh
./deploy/gcp/deploy.sh
```

Docker build context is `product/server` (includes `app/` and `assets/templates/`).

Copy the service URL into the Flutter app as `BACKEND_BASE_URL`.
