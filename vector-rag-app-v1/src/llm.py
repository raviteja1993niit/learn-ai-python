"""
llm.py — GitHub Models / GitHub Copilot API client (OpenAI-compatible).
Supports two endpoints:
  - GitHub Models:  https://models.inference.ai.azure.com  (free tier PAT)
  - GitHub Copilot: https://api.githubcopilot.com          (requires Copilot subscription)
Token can be provided manually, via GITHUB_TOKEN env var, or auto-detected from `gh auth token`.
"""
import json
import os
import shutil
import subprocess
import time

import httpx

# Prefer pwsh (PS 7, UTF-8 native) over powershell.exe (PS 5, CP1252 default)
_PS_CMD: str = "pwsh" if shutil.which("pwsh") else "powershell"

GITHUB_MODELS_ENDPOINT = "https://models.inference.ai.azure.com"
GITHUB_COPILOT_ENDPOINT = "https://api.githubcopilot.com"

MODELS_BY_PROVIDER = {
    "GitHub Models": [
        "gpt-4o",
        "gpt-4o-mini",
        "Meta-Llama-3.1-70B-Instruct",
        "Meta-Llama-3.1-8B-Instruct",
        "Phi-3.5-mini-instruct",
        "Phi-3-medium-instruct",
        "mistral-large",
        "mistral-small",
    ],
    "GitHub Copilot": [
        # ── OpenAI ────────────────────────────────────────────
        "gpt-4o-mini",        # fast & cheap
        "gpt-4.1",
        "gpt-5-mini",
        "gpt-5.2",
        "gpt-5.4-mini",
        "gpt-5.4",
        "gpt-5.5",
        "gpt-5.2-codex",
        "gpt-5.3-codex",
        # ── Anthropic Claude ──────────────────────────────────
        "claude-haiku-4.5",   # fastest Claude
        "claude-sonnet-4",
        "claude-sonnet-4.5",
        "claude-sonnet-4.6",
        "claude-opus-4.5",
        "claude-opus-4.6",
        "claude-opus-4.6-1m", # 1M context window
        "claude-opus-4.7",
        # ── xAI ──────────────────────────────────────────────
        "grok-code-fast-1",
    ],
}

# Legacy flat list (kept for backward compatibility)
AVAILABLE_MODELS = MODELS_BY_PROVIDER["GitHub Models"]

SYSTEM_PROMPT = """You are a helpful document assistant. Answer questions using the provided document pages.

Guidelines:
- Always answer based on the context pages provided. Cite page numbers when possible.
- If the full answer is present, give it clearly with page references.
- If only partial information is available, share what you found and describe what additional section would contain the rest.
- For technical specs (field definitions, tokens, codes): reproduce table rows, lengths, formats, and descriptions exactly as shown.
- If a term appears in a changelog or cross-reference but its definition isn't in the retrieved pages, say which section/token likely defines it (based on context clues) and what was found.
- Never refuse to answer if related content exists. Provide as much as you can from what's retrieved.
- Do not invent data not present in the document."""


def get_gh_cli_token() -> str:
    """Try to retrieve the GitHub token from the `gh` CLI (gh auth token)."""
    try:
        result = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True, text=True, timeout=5
        )
        token = result.stdout.strip()
        return token if result.returncode == 0 and token else ""
    except Exception:
        return ""


def resolve_token(github_token: str | None = None) -> str:
    """Resolve token from: argument → env var → gh CLI."""
    return (
        github_token
        or os.environ.get("GITHUB_TOKEN", "")
        or get_gh_cli_token()
    )


def _chat_completions_powershell(
    token: str,
    model: str,
    messages: list[dict],
    provider: str = "GitHub Models",
    temperature: float = 0.2,
) -> str:
    """
    Call the API via PowerShell (Invoke-RestMethod / WinHTTP) on Windows.
    WinHTTP uses the Windows system certificate store and is more reliable
    behind corporate SSL-inspection proxies than Python's httpx.
    Body is written to a temp file to avoid single-quote escaping issues
    when AI responses contain apostrophes.
    """
    import tempfile

    base_url = (
        GITHUB_COPILOT_ENDPOINT if provider == "GitHub Copilot"
        else GITHUB_MODELS_ENDPOINT
    )
    url = f"{base_url}/chat/completions"

    body = json.dumps({
        "model": model,
        "messages": messages,
        "temperature": temperature,
    })

    tmp = tempfile.NamedTemporaryFile(
        mode="w", suffix=".json", delete=False, encoding="utf-8"
    )
    tmp.write(body)
    tmp.close()
    tmp_path = tmp.name  # backslashes are fine in PS double-quoted strings

    ps_script = f"""
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$headers = @{{
    "Authorization" = "Bearer {token}"
    "Content-Type"  = "application/json; charset=utf-8"
    "Accept"        = "application/json"
}}
$body = Get-Content -Path "{tmp_path}" -Raw -Encoding UTF8
$r = Invoke-RestMethod -Uri "{url}" -Method POST -Headers $headers -Body $body
$r.choices[0].message.content
"""
    try:
        result = subprocess.run(
            [_PS_CMD, "-NoProfile", "-Command", ps_script],
            capture_output=True, text=True, timeout=60,
            encoding="utf-8", errors="replace",
        )
    finally:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass

    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()
    raise RuntimeError(f"PowerShell API call failed: {result.stderr.strip()[:300]}")


def _chat_completions(
    token: str,
    model: str,
    messages: list[dict],
    provider: str = "GitHub Models",
    temperature: float = 0.2,
    max_retries: int = 5,
    retry_delay: float = 1.5,
) -> str:
    """
    Call the chat completions endpoint with retry logic.
    On Windows, prefers PowerShell (WinHTTP) for better corporate-proxy reliability.
    Falls back to httpx on non-Windows or if PowerShell is unavailable.
    """
    use_powershell = os.name == "nt"  # Windows only

    if use_powershell:
        import random
        last_exc: Exception | None = None
        for attempt in range(1, max_retries + 1):
            try:
                return _chat_completions_powershell(token, model, messages, provider, temperature)
            except Exception as e:
                last_exc = e
                if attempt < max_retries:
                    delay = (2 ** attempt) + random.uniform(0, 1.5)
                    time.sleep(delay)
        raise RuntimeError(
            f"API failed after {max_retries} attempts (PowerShell). Last: {last_exc}"
        )

    # Non-Windows: use httpx with fresh client per attempt
    base_url = (
        GITHUB_COPILOT_ENDPOINT if provider == "GitHub Copilot"
        else GITHUB_MODELS_ENDPOINT
    )
    url = f"{base_url}/chat/completions"
    ssl_verify = os.environ.get("SSL_VERIFY", "true").lower() != "false"

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if provider == "GitHub Copilot":
        headers.update({
            "Editor-Version": "vscode/1.95.0",
            "Editor-Plugin-Version": "copilot/1.155.0",
            "Openai-Intent": "conversation-panel",
        })

    body = json.dumps({"model": model, "messages": messages, "temperature": temperature})
    last_exc = None
    for attempt in range(1, max_retries + 1):
        try:
            with httpx.Client(verify=ssl_verify, timeout=60.0) as client:
                response = client.post(url, headers=headers, content=body)
            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"].strip()
            if response.status_code in (403, 429, 503) and attempt < max_retries:
                time.sleep(retry_delay * attempt)
                continue
            response.raise_for_status()
        except (httpx.HTTPStatusError, httpx.RequestError) as e:
            last_exc = e
            if attempt < max_retries:
                time.sleep(retry_delay * attempt)

    raise RuntimeError(f"API failed after {max_retries} attempts. Last: {last_exc}")


def generate_answer(
    question: str,
    context: str,
    model: str = "claude-haiku-4.5",
    github_token: str | None = None,
    provider: str = "GitHub Copilot",
    chat_history: list[dict] | None = None,
) -> str:
    """
    Send question + retrieved page context to the LLM and return the answer.
    chat_history is a list of prior {role, content} dicts for multi-turn support.
    """
    token = resolve_token(github_token)
    if not token:
        raise ValueError(
            "GitHub token not provided. Run `gh auth login` or set GITHUB_TOKEN."
        )

    if not context.strip():
        return "No relevant content found in the document to answer your question."

    user_message = (
        f"Use the following document pages to answer the question.\n\n"
        f"Document Context:\n{context}\n\n"
        f"Question: {question}\n\nAnswer:"
    )

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]

    # Inject prior conversation turns (last 6 turns max to stay within context)
    if chat_history:
        messages.extend(chat_history[-6:])

    messages.append({"role": "user", "content": user_message})
    return _chat_completions(token, model, messages, provider=provider)
