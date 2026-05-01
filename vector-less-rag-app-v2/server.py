"""
server.py — FastAPI server for VectorLess RAG app v2.
"""
from __future__ import annotations

import uuid
import os
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.requests import Request
import uvicorn

from src.llm import MODELS_BY_PROVIDER, get_gh_cli_token
from src.rag import RAGPipeline

app = FastAPI(title="VectorLess RAG App")

app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# ── Session store ─────────────────────────────────────────────────────────────
sessions: dict = {}
# Each entry: {"pipeline": RAGPipeline, "chat_history": []}


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse(request=request, name="index.html")


@app.get("/api/models")
async def get_models():
    return {"models": MODELS_BY_PROVIDER}


@app.get("/api/token")
async def get_token():
    token = get_gh_cli_token()
    return {"token": token}


@app.post("/api/upload")
async def upload(
    session_id: str = Form(...),
    file: UploadFile = File(...),
    model: str = Form(...),
    provider: str = Form(...),
    github_token: str = Form(...),
    top_k: int = Form(4),
):
    try:
        file_bytes = await file.read()
        pipeline = RAGPipeline(
            filename=file.filename,
            file_bytes=file_bytes,
            top_k=top_k,
            model=model,
            github_token=github_token,
            provider=provider,
        )
        sessions[session_id] = {
            "pipeline": pipeline,
            "chat_history": [],
        }
        stats = pipeline.stats
        return {
            "ok": True,
            "filename": file.filename,
            "stats": {
                "total_pages": stats.total_pages,
                "total_words": stats.total_words,
                "avg_words_per_page": stats.avg_words_per_page,
                "source_types": stats.source_types,
                "longest_page": stats.longest_page,
            },
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@app.post("/api/chat")
async def chat(body: dict):
    session_id = body.get("session_id")
    question = body.get("question", "").strip()

    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found. Please upload a document first.")
    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")

    session = sessions[session_id]
    pipeline: RAGPipeline = session["pipeline"]

    try:
        result = pipeline.ask(question)
        session["chat_history"].append({"role": "user", "content": question})
        session["chat_history"].append({"role": "assistant", "content": result.answer})

        sources = [
            {
                "page_num": p.page_num,
                "title": p.title,
                "score": s,
                "word_count": p.word_count,
                "source_type": p.source_type,
                "content_preview": p.content[:300],
            }
            for p, s in result.source_pages
        ]
        return {"answer": result.answer, "sources": sources}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat failed: {str(e)}")


@app.get("/api/pages")
async def get_pages(session_id: str, search: Optional[str] = None):
    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found.")

    pipeline: RAGPipeline = sessions[session_id]["pipeline"]
    stats = pipeline.stats

    if search and search.strip():
        results = pipeline.index.search(search.strip(), top_k=len(pipeline.pages))
        pages_out = [
            {
                "page_num": p.page_num,
                "title": p.title,
                "word_count": p.word_count,
                "source_type": p.source_type,
                "content": p.content,
                "score": s,
            }
            for p, s in results
        ]
    else:
        pages_out = [
            {
                "page_num": p.page_num,
                "title": p.title,
                "word_count": p.word_count,
                "source_type": p.source_type,
                "content": p.content,
                "score": 0.0,
            }
            for p in pipeline.pages
        ]

    return {
        "pages": pages_out,
        "stats": {
            "total_pages": stats.total_pages,
            "total_words": stats.total_words,
            "avg_words_per_page": stats.avg_words_per_page,
            "source_types": stats.source_types,
        },
    }


@app.get("/api/scores")
async def get_scores(session_id: str, query: str = ""):
    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found.")
    pipeline: RAGPipeline = sessions[session_id]["pipeline"]
    data = pipeline.index.score_chart_data(query)
    return {"scores": data}


@app.post("/api/reset")
async def reset(body: dict):
    session_id = body.get("session_id")
    if session_id and session_id in sessions:
        del sessions[session_id]
    return {"ok": True}


@app.post("/api/clear_chat")
async def clear_chat(body: dict):
    session_id = body.get("session_id")
    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found.")
    pipeline: RAGPipeline = sessions[session_id]["pipeline"]
    pipeline.clear_history()
    sessions[session_id]["chat_history"] = []
    return {"ok": True}


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
