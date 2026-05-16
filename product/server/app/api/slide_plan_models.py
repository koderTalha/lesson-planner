from pydantic import BaseModel, Field


class SlidePlanGenerateRequest(BaseModel):
    subject: str = Field(default="", max_length=120)
    topic: str = Field(default="", max_length=200)
    title: str = Field(..., min_length=1, max_length=160)
    subtitle: str | None = Field(default=None, max_length=200)
    slide_count: int = Field(default=8, ge=3, le=30)
    class_level: str | None = Field(default=None, max_length=80)
    audience: str | None = Field(default=None, max_length=120)
    tone: str | None = Field(default=None, max_length=120)
    theme: str = Field(default="brand", max_length=32)


class SlideCitation(BaseModel):
    book_id: str
    page_start: int
    page_end: int


class SlideBullet(BaseModel):
    text: str = Field(..., min_length=1, max_length=55)
    detail: str | None = Field(default=None, max_length=130)
    citations: list[SlideCitation] = Field(default_factory=list, max_length=5)


class SlidePlanSlide(BaseModel):
    title: str = Field(..., min_length=1, max_length=64)
    bullets: list[SlideBullet] = Field(..., min_length=2, max_length=4)
    speaker_notes: str = Field(default="", max_length=1200)


class SlidePlan(BaseModel):
    deck_title: str = Field(..., min_length=1, max_length=160)
    deck_subtitle: str = Field(default="", max_length=200)
    slides: list[SlidePlanSlide] = Field(..., min_length=1, max_length=30)
