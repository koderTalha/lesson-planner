import json

from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import Response

from app.api.auth_models import TokenRequest, TokenResponse
from app.api.models import HealthResponse
from app.api.slide_plan_models import SlidePlan, SlidePlanGenerateRequest
from app.auth import create_access_token, require_auth, verify_api_key
from app.services.gemini_service import generate_json
from app.services.pptx_builder import build_pptx_from_plan
from app.services.pptx_themes import list_themes
from app.services.slide_plan_coerce import coerce_raw_slide_plan

app = FastAPI(title="Lesson Planner Backend", version="0.2.0")


@app.get("/health", response_model=HealthResponse, tags=["system"])
def health() -> HealthResponse:
    return HealthResponse(ok=True)


@app.post(
    "/api/v1/auth/token",
    response_model=TokenResponse,
    tags=["auth"],
    summary="Exchange api_key for JWT",
)
def token(req: TokenRequest) -> TokenResponse:
    verify_api_key(req.api_key)
    return TokenResponse(access_token=create_access_token(sub="app"))


@app.get(
    "/api/v1/ppt/themes",
    tags=["ppt"],
    summary="List available PPTX themes",
    dependencies=[Depends(require_auth)],
)
def ppt_themes() -> dict:
    return {"themes": list_themes()}


def _plan_from_gemini(req: SlidePlanGenerateRequest) -> SlidePlan:
    system = (
        "You create professional classroom slide decks.\n"
        "Return ONLY one JSON object matching this schema:\n"
        "{ deck_title: string, deck_subtitle: string, slides: [ { title: string, "
        "bullets: [ { text: string, detail: string, citations: [] } ], speaker_notes: string } ] }\n"
        "Rules:\n"
        "- slides length MUST equal user.slide_count - 1 (title slide is separate).\n"
        "- Each slide: 3 to 4 bullet points. Never 1 or 2 only.\n"
        "- Each bullet has text (short label, 3-8 words) AND detail (one clear sentence explaining it, 10-22 words).\n"
        "- detail is required for every bullet; make it teaching-friendly, like the older descriptive slides.\n"
        "- Slide titles: max 8 words.\n"
        "- Use correct spelling and grammar.\n"
        "- Match audience and tone from user input.\n"
        "- Include an agenda-style flow: intro, core concepts, examples, summary.\n"
        "- speaker_notes: 1-3 sentences for the teacher (can be empty string).\n"
        "- citations must be an empty array [] for every bullet.\n"
    )
    user = json.dumps(
        {
            "user": {
                "subject": req.subject,
                "topic": req.topic,
                "title": req.title,
                "subtitle": req.subtitle,
                "slide_count": req.slide_count,
                "class_level": req.class_level,
                "audience": req.audience,
                "tone": req.tone,
            },
        },
        ensure_ascii=False,
    )
    raw = generate_json(system=system, user_text=user)
    coerced = coerce_raw_slide_plan(
        raw,
        slide_count=req.slide_count,
        fallback_title=req.title,
        fallback_subtitle=req.subtitle,
    )
    try:
        return SlidePlan.model_validate(coerced)
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"Invalid slide plan from model: {e!s}",
        ) from e


@app.post(
    "/api/v1/ppt/plan_ai",
    response_model=SlidePlan,
    tags=["ppt"],
    summary="Generate slide plan JSON (Gemini)",
    dependencies=[Depends(require_auth)],
)
def plan_ai(req: SlidePlanGenerateRequest) -> SlidePlan:
    return _plan_from_gemini(req)


@app.post(
    "/api/v1/ppt/generate_ai",
    tags=["ppt"],
    summary="Generate PPTX with Gemini AI",
    dependencies=[Depends(require_auth)],
    responses={
        200: {
            "content": {
                "application/vnd.openxmlformats-officedocument.presentationml.presentation": {
                    "schema": {"type": "string", "format": "binary"}
                }
            },
            "description": "PPTX file",
        }
    },
)
def generate_ai(req: SlidePlanGenerateRequest) -> Response:
    plan = _plan_from_gemini(req)
    data = build_pptx_from_plan(plan, theme=req.theme)
    safe = "".join(c for c in req.title.strip() if c.isalnum() or c in (" ", "-", "_"))
    name = (safe[:80].strip().replace(" ", "_") or "slides") + ".pptx"
    headers = {"Content-Disposition": f'attachment; filename="{name}"'}
    return Response(
        content=data,
        media_type="application/vnd.openxmlformats-officedocument.presentationml.presentation",
        headers=headers,
    )
