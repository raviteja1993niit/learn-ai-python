"""
llm.py — GitHub Copilot API client.

Uses PowerShell WinHTTP on Windows (reliable behind corporate SSL proxies),
httpx on other platforms. Token auto-detected from `gh auth token` CLI or
GITHUB_TOKEN env var.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import time
from typing import Any

# Prefer pwsh (PS 7, UTF-8 native) over powershell.exe (PS 5, CP1252 default)
_PS_CMD: str = "pwsh" if shutil.which("pwsh") else "powershell"

COPILOT_ENDPOINT  = "https://api.githubcopilot.com/chat/completions"
COPILOT_MODELS_EP = "https://api.githubcopilot.com/models"

# Static fallback — used only when the /models API call fails
_FALLBACK_MODELS: list[str] = [
    "gpt-4o-mini",
    "gpt-4.1",
    "gpt-5-mini",
    "gpt-5.2",
    "gpt-5.2-codex",
    "gpt-5.3-codex",
    "gpt-5.4-mini",
    "gpt-5.4",
    "gpt-5.5",
    "claude-haiku-4.5",
    "claude-sonnet-4",
    "claude-sonnet-4.5",
    "claude-sonnet-4.6",
    "claude-opus-4.5",
    "claude-opus-4.6",
    "claude-opus-4.7",
    "grok-code-fast-1",
]

# Cached after first successful fetch
COPILOT_MODELS: list[str] = []

DEFAULT_MODEL = "gpt-5-mini"

# Prefixes that identify non-chat (embedding) models — excluded from dropdown
_EMBEDDING_PREFIXES = ("text-embedding-", "text-ada-")
# Suffixes that mark internal / restricted models — excluded from dropdown
_INTERNAL_SUFFIXES  = ("-1m",)


def get_available_models(token: str = "") -> list[str]:
    """
    Fetch the live model list from the GitHub Copilot /models endpoint.

    Filters out embedding models and internal-only variants.
    Results are cached in the module-level COPILOT_MODELS list.
    Falls back to _FALLBACK_MODELS on any error.

    Args:
        token: GitHub token (resolved automatically if blank).

    Returns:
        Sorted list of chat-capable model IDs.
    """
    global COPILOT_MODELS
    if COPILOT_MODELS:
        return COPILOT_MODELS

    resolved_token = token or get_gh_token()
    if not resolved_token:
        COPILOT_MODELS = list(_FALLBACK_MODELS)
        return COPILOT_MODELS

    try:
        if os.name == "nt":
            COPILOT_MODELS = _fetch_models_powershell(resolved_token)
        else:
            COPILOT_MODELS = _fetch_models_httpx(resolved_token)
    except Exception:
        COPILOT_MODELS = list(_FALLBACK_MODELS)

    return COPILOT_MODELS


def _is_chat_model(model_id: str) -> bool:
    """Return True if this model ID is a chat-capable (non-embedding, non-internal) model."""
    mid = model_id.lower()
    if any(mid.startswith(p) for p in _EMBEDDING_PREFIXES):
        return False
    if any(mid.endswith(s) for s in _INTERNAL_SUFFIXES):
        return False
    return True


def _fetch_models_powershell(token: str) -> list[str]:
    ps_script = f"""
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$r = Invoke-RestMethod `
    -Uri     "{COPILOT_MODELS_EP}" `
    -Method  GET `
    -Headers @{{ "Authorization" = "Bearer {token}"; "Accept" = "application/json" }}
$r.data | ConvertTo-Json -Depth 5
"""
    result = subprocess.run(
        [_PS_CMD, "-NoProfile", "-Command", ps_script],
        capture_output=True, text=True, timeout=20,
        encoding="utf-8", errors="replace",
    )
    if result.returncode != 0 or not result.stdout.strip():
        return list(_FALLBACK_MODELS)
    try:
        data = json.loads(result.stdout.strip())
        if isinstance(data, dict):  # single item edge case
            data = [data]
        return _sort_models(_dedupe_by_version(data))
    except Exception:
        return list(_FALLBACK_MODELS)


def _fetch_models_httpx(token: str) -> list[str]:
    import httpx
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    with httpx.Client(timeout=20.0) as client:
        r = client.get(COPILOT_MODELS_EP, headers=headers)
    if r.status_code != 200:
        return list(_FALLBACK_MODELS)
    data = r.json().get("data", [])
    return _sort_models(_dedupe_by_version(data)) or list(_FALLBACK_MODELS)


def _dedupe_by_version(model_objects: list[dict]) -> list[str]:
    """
    Given raw model objects from /models API, return a deduplicated list of IDs.

    When multiple model IDs share the same version string (i.e., they're aliases
    of the same underlying model), keep only the shortest / cleanest ID.
    Embedding and internal models are excluded.
    """
    from collections import defaultdict
    version_to_ids: dict[str, list[str]] = defaultdict(list)
    for obj in model_objects:
        mid = obj.get("id", "")
        ver = obj.get("version", mid)  # fall back to id if no version field
        if _is_chat_model(mid):
            version_to_ids[ver].append(mid)

    result: list[str] = []
    for ver, ids in version_to_ids.items():
        # Among aliases, prefer the shortest (clean alias over dated/versioned variant)
        best = min(ids, key=lambda x: (len(x), x))
        result.append(best)
    return result


def _sort_models(models: list[str]) -> list[str]:
    """Sort models: fast/mini first, then gpt, claude, grok order, then alphabetically."""
    def sort_key(m: str) -> tuple:
        is_fast   = 0 if any(x in m for x in ("mini", "haiku", "fast", "3.5")) else 1
        is_claude = 1 if m.startswith("claude") else 0
        is_grok   = 1 if m.startswith("grok") else 0
        return (is_fast, is_claude, is_grok, m)
    return sorted(models, key=sort_key)


def get_gh_token() -> str:
    """Resolve GitHub token: GITHUB_TOKEN env var → gh CLI."""
    if token := os.environ.get("GITHUB_TOKEN", ""):
        return token
    try:
        result = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True, text=True, timeout=5,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except Exception:
        return ""


def chat(
    messages: list[dict[str, str]],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.3,
    max_retries: int = 3,
    on_wait: "callable[[str], None] | None" = None,
) -> str:
    """
    Send a chat completion request to GitHub Copilot API.

    Args:
        messages:    List of {"role": "system"|"user"|"assistant", "content": str}
        model:       Copilot model name
        temperature: Sampling temperature
        max_retries: Number of retry attempts on transient errors (403 / 5xx)
        on_wait:     Optional callback(msg) called during rate-limit pauses so the
                     caller can surface countdown messages in the UI.

    Returns:
        The assistant's response text.

    Raises:
        ValueError: If no GitHub token is found.
        RuntimeError: If all retries fail.
    """
    token = get_gh_token()
    if not token:
        raise ValueError(
            "No GitHub token found. Run `gh auth login` in your terminal."
        )

    if os.name == "nt":
        return _call_powershell(token, messages, model, temperature, max_retries, on_wait)
    return _call_httpx(token, messages, model, temperature, max_retries, on_wait)


_RATE_LIMIT_WAIT = 65   # seconds to wait between 403 retries


def _rate_limit_sleep(seconds: int, attempt: int, max_retries: int,
                      on_wait: "callable[[str], None] | None") -> None:
    """Sleep for `seconds` while emitting countdown messages every 10s via on_wait."""
    for remaining in range(seconds, 0, -10):
        if on_wait:
            on_wait(
                f"  ⏳ Rate limited (403) — retry {attempt}/{max_retries - 1} in {remaining}s…"
            )
        time.sleep(min(10, remaining))


# ── PowerShell / WinHTTP backend ──────────────────────────────────────────────

def _call_powershell(
    token: str,
    messages: list[dict],
    model: str,
    temperature: float,
    max_retries: int,
    on_wait: "callable[[str], None] | None" = None,
) -> str:
    body = json.dumps({"model": model, "messages": messages, "temperature": temperature})

    # Write to temp file — avoids apostrophe escaping in PS string literals
    tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False, encoding="utf-8")
    tmp.write(body)
    tmp.close()

    # Wrap in try/catch so we can capture the HTTP status code from PS
    ps_script = f"""
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$headers = @{{
    "Authorization" = "Bearer {token}"
    "Content-Type"  = "application/json; charset=utf-8"
    "Accept"        = "application/json"
}}
$body = Get-Content -Path "{tmp.name}" -Raw -Encoding UTF8
try {{
    $r = Invoke-RestMethod `
        -Uri    "{COPILOT_ENDPOINT}" `
        -Method POST `
        -Headers $headers `
        -Body    $body
    $r.choices[0].message.content
}} catch {{
    $sc = $_.Exception.Response.StatusCode.value__
    if ($sc) {{
        Write-Error "HTTP_STATUS:$sc $($_.Exception.Message)"
    }} else {{
        Write-Error $_.Exception.Message
    }}
    exit 1
}}
"""
    import random

    last_err = ""
    try:
        for attempt in range(1, max_retries + 1):
            try:
                result = subprocess.run(
                    [_PS_CMD, "-NoProfile", "-Command", ps_script],
                    capture_output=True, text=True, timeout=300,
                    encoding="utf-8", errors="replace",
                )
            except subprocess.TimeoutExpired:
                last_err = "subprocess timed out after 300s"
                if attempt < max_retries:
                    if on_wait:
                        on_wait(f"  ⏳ API call timed out — retry {attempt}/{max_retries - 1}…")
                    time.sleep(10)
                    continue
                raise RuntimeError(
                    "Copilot API timed out after 300s. "
                    "The response is taking too long — try a smaller model or wait and retry."
                )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
            last_err = result.stderr.strip()
            # 413 = payload too large — never retryable
            if "HTTP_STATUS:413" in last_err:
                raise RuntimeError(
                    "Copilot API rejected the request (413 Payload Too Large). "
                    "The prompt is too long for this model's context window."
                )
            # 403 = rate limited or access issue — wait and retry
            if "HTTP_STATUS:403" in last_err:
                if attempt < max_retries:
                    _rate_limit_sleep(_RATE_LIMIT_WAIT, attempt, max_retries, on_wait)
                    continue
                raise RuntimeError(
                    "Copilot API returned 403 Forbidden after retries. "
                    "You may have hit a rate limit. Wait a minute and try again. "
                    f"Detail: {last_err[:300]}"
                )
            if attempt < max_retries:
                delay = (2 ** attempt) + random.uniform(0, 1.5)
                time.sleep(delay)
    finally:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass

    raise RuntimeError(f"Copilot API failed after {max_retries} attempts: {last_err[:400]}")


# ── httpx backend (non-Windows) ───────────────────────────────────────────────

def _call_httpx(
    token: str,
    messages: list[dict],
    model: str,
    temperature: float,
    max_retries: int,
    on_wait: "callable[[str], None] | None" = None,
) -> str:
    import httpx  # optional non-Windows dependency

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type":  "application/json",
        "Accept":        "application/json",
    }
    body = json.dumps({"model": model, "messages": messages, "temperature": temperature})
    ssl_verify = os.environ.get("SSL_VERIFY", "true").lower() != "false"
    last_exc: Any = None

    for attempt in range(1, max_retries + 1):
        try:
            with httpx.Client(verify=ssl_verify, timeout=120.0) as client:
                r = client.post(COPILOT_ENDPOINT, headers=headers, content=body)
            if r.status_code == 200:
                return r.json()["choices"][0]["message"]["content"].strip()
            # 413 = payload too large — never retryable
            if r.status_code == 413:
                raise RuntimeError(
                    "Copilot API rejected the request (413 Payload Too Large). "
                    "The prompt is too long for this model's context window."
                )
            # 403 = rate limited or access issue — wait and retry
            if r.status_code == 403:
                if attempt < max_retries:
                    _rate_limit_sleep(_RATE_LIMIT_WAIT, attempt, max_retries, on_wait)
                    continue
                raise RuntimeError(
                    "Copilot API returned 403 Forbidden after retries. "
                    "You may have hit a rate limit. Wait a minute and try again."
                )
            if r.status_code in (429, 503) and attempt < max_retries:
                time.sleep(1.5 * attempt)
                continue
            r.raise_for_status()
        except Exception as exc:
            last_exc = exc
            if attempt < max_retries:
                time.sleep(1.5 * attempt)

    raise RuntimeError(f"Copilot API failed after {max_retries} attempts: {last_exc}")
