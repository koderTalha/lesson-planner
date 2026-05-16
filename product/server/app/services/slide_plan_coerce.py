from __future__ import annotations


def _clip(text: str, limit: int) -> str:
    t = (text or "").strip()
    if len(t) <= limit:
        return t
    cut = t[: limit - 1].rsplit(" ", 1)[0].strip()
    return (cut or t[: limit - 1]).rstrip(".,;:") + "…"


def _norm_citation(c: object) -> dict | None:
    if not isinstance(c, dict):
        return None
    bid = c.get("book_id")
    ps = c.get("page_start")
    pe = c.get("page_end")
    if bid is None or ps is None or pe is None:
        return None
    try:
        return {
            "book_id": str(bid),
            "page_start": int(ps),
            "page_end": int(pe),
        }
    except (TypeError, ValueError):
        return None


def _norm_bullet(b: object) -> dict | None:
    if not isinstance(b, dict):
        return None
    text = (b.get("text") or "").strip()
    if not text:
        return None
    detail = b.get("detail")
    detail_s = str(detail).strip() if detail is not None else ""
    if not detail_s and ": " in text:
        head, tail = text.split(": ", 1)
        text, detail_s = head.strip(), tail.strip()
    text = _clip(text, 55)
    detail_out = _clip(detail_s, 130) if detail_s else None
    cites = b.get("citations") or []
    out_c = []
    if isinstance(cites, list):
        for x in cites:
            nc = _norm_citation(x)
            if nc:
                out_c.append(nc)
            if len(out_c) >= 5:
                break
    out: dict = {"text": text, "citations": out_c}
    if detail_out:
        out["detail"] = detail_out
    return out


def coerce_raw_slide_plan(
    raw: object,
    *,
    slide_count: int,
    fallback_title: str,
    fallback_subtitle: str | None,
) -> dict:
    if not isinstance(raw, dict):
        raw = {}
    expected = max(1, slide_count - 1)
    deck_title = (raw.get("deck_title") or fallback_title or "Lesson").strip()[:160]
    deck_sub = (raw.get("deck_subtitle") or (fallback_subtitle or "")).strip()[:200]
    slides_in = raw.get("slides")
    if not isinstance(slides_in, list):
        slides_in = []
    slides_out: list[dict] = []
    for i in range(expected):
        s = slides_in[i] if i < len(slides_in) and isinstance(slides_in[i], dict) else {}
        title = (s.get("title") or f"Slide {i + 1}").strip()[:64]
        bullets_in = s.get("bullets")
        if not isinstance(bullets_in, list):
            bullets_in = []
        bullets: list[dict] = []
        for b in bullets_in:
            nb = _norm_bullet(b)
            if nb:
                bullets.append(nb)
        base_cites = bullets[0]["citations"] if bullets else []
        while len(bullets) < 2:
            bullets.append(
                {
                    "text": "Key idea",
                    "detail": "Relate this point to the main definitions on the previous slides.",
                    "citations": list(base_cites[:1]) if base_cites else [],
                }
            )
        while len(bullets) < 3:
            bullets.append(
                {
                    "text": "Check for understanding",
                    "detail": "Ask students to explain one example in their own words.",
                    "citations": list(base_cites[:1]) if base_cites else [],
                }
            )
        bullets = bullets[:4]
        notes = s.get("speaker_notes")
        if notes is None:
            notes = ""
        notes = str(notes).strip()[:1200]
        slides_out.append(
            {
                "title": title,
                "bullets": bullets,
                "speaker_notes": notes,
            }
        )
    return {
        "deck_title": deck_title,
        "deck_subtitle": deck_sub,
        "slides": slides_out,
    }
