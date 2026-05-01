"""
llm.py — Custom LangChain-compatible ChatModel for GitHub Copilot API.

Uses PowerShell (WinHTTP) on Windows for reliability behind corporate
SSL-inspection proxies, with httpx fallback on other platforms.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import time
from typing import Any, List, Optional

from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from pydantic import Field

# Prefer pwsh (PS 7, UTF-8 native) over powershell.exe (PS 5, CP1252 default)
_PS_CMD: str = "pwsh" if shutil.which("pwsh") else "powershell"

COPILOT_ENDPOINT = "https://api.githubcopilot.com"

COPILOT_MODELS = [
    # ── OpenAI ────────────────────────────
    "gpt-4o-mini",
    "gpt-4.1",
    "gpt-5-mini",
    "gpt-5.2",
    "gpt-5.4-mini",
    "gpt-5.4",
    "gpt-5.5",
    "gpt-5.2-codex",
    "gpt-5.3-codex",
    # ── Anthropic Claude ──────────────────
    "claude-haiku-4.5",
    "claude-sonnet-4",
    "claude-sonnet-4.5",
    "claude-sonnet-4.6",
    "claude-opus-4.5",
    "claude-opus-4.6",
    "claude-opus-4.6-1m",
    "claude-opus-4.7",
    # ── xAI ──────────────────────────────
    "grok-code-fast-1",
]

DEFAULT_MODEL = "claude-haiku-4.5"


def get_gh_token() -> str:
    """Resolve GitHub token: env var → gh CLI."""
    if token := os.environ.get("GITHUB_TOKEN", ""):
        return token
    try:
        result = subprocess.run(
            ["gh", "auth", "token"], capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except Exception:
        return ""


class CopilotChatModel(BaseChatModel):
    """
    LangChain BaseChatModel backed by GitHub Copilot API.
    On Windows: uses PowerShell / WinHTTP (reliable behind corporate proxy).
    On other platforms: uses httpx with retry logic.
    """

    model_name: str = Field(default=DEFAULT_MODEL, alias="model")
    temperature: float = 0.2
    max_retries: int = 5

    model_config = {"populate_by_name": True}

    @property
    def _llm_type(self) -> str:
        return "github_copilot"

    @property
    def _identifying_params(self) -> dict:
        return {"model": self.model_name, "temperature": self.temperature}

    # ── Message conversion ────────────────────────────────────────────────────

    def _to_api_messages(self, messages: List[BaseMessage]) -> List[dict]:
        role_map = {
            HumanMessage: "user",
            AIMessage:    "assistant",
            SystemMessage: "system",
        }
        result = []
        for msg in messages:
            role = role_map.get(type(msg), "user")
            content = msg.content if isinstance(msg.content, str) else str(msg.content)
            result.append({"role": role, "content": content})
        return result

    # ── Core generate ─────────────────────────────────────────────────────────

    def _generate(
        self,
        messages: List[BaseMessage],
        stop: Optional[List[str]] = None,
        run_manager: Any = None,
        **kwargs: Any,
    ) -> ChatResult:
        token = get_gh_token()
        if not token:
            raise ValueError("GitHub token not found. Run: gh auth login")

        api_messages = self._to_api_messages(messages)
        content = (
            self._call_powershell(token, api_messages)
            if os.name == "nt"
            else self._call_httpx(token, api_messages)
        )
        return ChatResult(generations=[ChatGeneration(message=AIMessage(content=content))])

    # ── PowerShell backend (Windows / WinHTTP) ────────────────────────────────

    def _call_powershell(self, token: str, messages: List[dict]) -> str:
        body = json.dumps({
            "model":       self.model_name,
            "messages":    messages,
            "temperature": self.temperature,
        })

        # Write body to temp file — avoids all single-quote escaping issues
        # when AI responses contain apostrophes that break PS string literals.
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        tmp.write(body)
        tmp.close()
        # PowerShell uses backtick as escape, not backslash — raw Windows path is fine
        tmp_path = tmp.name

        ps_script = f"""
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$headers = @{{
    "Authorization" = "Bearer {token}"
    "Content-Type"  = "application/json; charset=utf-8"
    "Accept"        = "application/json"
}}
$body = Get-Content -Path "{tmp_path}" -Raw -Encoding UTF8
$r = Invoke-RestMethod `
    -Uri    "https://api.githubcopilot.com/chat/completions" `
    -Method POST `
    -Headers $headers `
    -Body   $body
$r.choices[0].message.content
"""
        import random
        last_err: str = ""
        try:
            for attempt in range(1, self.max_retries + 1):
                result = subprocess.run(
                    [_PS_CMD, "-NoProfile", "-Command", ps_script],
                    capture_output=True, text=True, timeout=90,
                    encoding="utf-8", errors="replace",
                )
                if result.returncode == 0 and result.stdout.strip():
                    return result.stdout.strip()
                last_err = result.stderr.strip()
                if attempt < self.max_retries:
                    # Exponential backoff + jitter to avoid proxy rate-limiting
                    delay = (2 ** attempt) + random.uniform(0, 1.5)
                    time.sleep(delay)
        finally:
            try:
                os.unlink(tmp.name)
            except OSError:
                pass
        raise RuntimeError(f"Copilot API failed after {self.max_retries} attempts: {last_err[:300]}")

    # ── httpx backend (non-Windows) ───────────────────────────────────────────

    def _call_httpx(self, token: str, messages: List[dict]) -> str:
        import httpx

        ssl_verify = os.environ.get("SSL_VERIFY", "true").lower() != "false"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type":  "application/json",
            "Accept":        "application/json",
        }
        body = json.dumps({
            "model":       self.model_name,
            "messages":    messages,
            "temperature": self.temperature,
        })
        url = f"{COPILOT_ENDPOINT}/chat/completions"
        last_exc: Exception | None = None

        for attempt in range(1, self.max_retries + 1):
            try:
                with httpx.Client(verify=ssl_verify, timeout=90.0) as client:
                    r = client.post(url, headers=headers, content=body)
                if r.status_code == 200:
                    return r.json()["choices"][0]["message"]["content"].strip()
                if r.status_code in (403, 429, 503) and attempt < self.max_retries:
                    time.sleep(1.5 * attempt)
                    continue
                r.raise_for_status()
            except Exception as e:
                last_exc = e
                if attempt < self.max_retries:
                    time.sleep(1.5 * attempt)

        raise RuntimeError(f"Copilot API failed after {self.max_retries} attempts: {last_exc}")
