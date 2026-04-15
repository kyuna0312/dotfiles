#!/usr/bin/env python3
"""
Inari MCP — local AI assistant layer for Claude Code.

Routing strategy:
  Claude Code (brain/orchestrator)
    └── inari_ask        ← default entry point, auto-routes
          ├── Qwen3 8B   ← fast coding: write, fix, complete, format, test
          ├── Llama4     ← reasoning: explain, design, analyze, debug, review
          └── [INARI:FALLBACK] → Claude handles it directly if both fail
"""

import json
import subprocess
import urllib.error
import urllib.request
from mcp.server.fastmcp import FastMCP

# ── config ────────────────────────────────────────────────────────────────────

OLLAMA_BASE = "http://localhost:11434"

MODELS = {
    "qwen":   "qwen3:8b",
    "llama4": "llama4:scout",
}

FALLBACK = "[INARI:FALLBACK]"

# Keywords that signal which model to use
_QWEN_SIGNALS  = {"write", "fix", "complete", "implement", "generate", "snippet",
                  "function", "format", "rename", "refactor", "test", "convert", "translate"}
_LLAMA_SIGNALS = {"explain", "why", "design", "architecture", "analyze", "analyse",
                  "compare", "review", "understand", "debug", "plan", "think", "reason",
                  "describe", "summarize", "what is", "how does"}

# ── ollama client ─────────────────────────────────────────────────────────────

class OllamaError(Exception):
    pass


class OllamaClient:
    def get(self, path: str) -> dict:
        try:
            with urllib.request.urlopen(f"{OLLAMA_BASE}{path}", timeout=10) as resp:
                return json.loads(resp.read())
        except urllib.error.URLError as e:
            raise OllamaError(f"Ollama unreachable: {e}\nRun: sudo systemctl start ollama")

    def post(self, path: str, body: dict) -> dict:
        data = json.dumps(body).encode()
        req = urllib.request.Request(
            f"{OLLAMA_BASE}{path}",
            data=data,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 404:
                raise OllamaError(f"Model not found. Run: ollama pull <model>")
            raise OllamaError(f"HTTP {e.code}: {e.reason}")
        except urllib.error.URLError as e:
            raise OllamaError(f"Ollama unreachable: {e}\nRun: sudo systemctl start ollama")

    def list_models(self) -> list[str]:
        data = self.get("/api/tags")
        return [m["name"] for m in data.get("models", [])]

    def chat(self, model: str, prompt: str, system: str = "") -> str:
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        result = self.post("/api/chat", {"model": model, "messages": messages, "stream": False})
        return result["message"]["content"]


_client = OllamaClient()

# ── routing ───────────────────────────────────────────────────────────────────

def _route(task: str) -> str:
    """Classify task → 'qwen' (fast coding) or 'llama4' (reasoning)."""
    lower = task.lower()
    qwen_score  = sum(1 for w in _QWEN_SIGNALS  if w in lower)
    llama_score = sum(1 for w in _LLAMA_SIGNALS if w in lower)
    # Long prompts lean toward reasoning
    if len(task) > 400:
        llama_score += 1
    return "llama4" if llama_score > qwen_score else "qwen"

# ── mcp tools ─────────────────────────────────────────────────────────────────

mcp = FastMCP("inari")


@mcp.tool()
def inari_ask(task: str) -> str:
    """DEFAULT entry point — auto-routes to the best local model.

    Routing:
      - Fast coding tasks (write/fix/complete/test/format) → Qwen3 8B
      - Reasoning tasks (explain/design/analyze/debug/review) → Llama 4 Scout
      - If primary model fails → retries with the other model
      - If both fail → returns [INARI:FALLBACK], meaning Claude should handle it

    IMPORTANT: If the response starts with [INARI:FALLBACK], handle the task
    yourself using your own knowledge — do not call inari tools again.

    Args:
        task: The task or question to route to a local model.
    """
    primary = _route(task)
    secondary = "llama4" if primary == "qwen" else "qwen"

    try:
        result = _client.chat(MODELS[primary], task)
        return f"[inari/{primary}]\n{result}"
    except OllamaError:
        pass

    try:
        result = _client.chat(MODELS[secondary], task)
        return f"[inari/{secondary}:retry]\n{result}"
    except OllamaError as e:
        return f"{FALLBACK} Both local models unavailable: {e}\nHandle this task yourself."


@mcp.tool()
def inari_qwen(prompt: str, system: str = "") -> str:
    """Ask Qwen3 8B directly (local). Use for fast coding tasks:
    writing functions, fixing bugs, completing code, formatting, generating tests.
    If this returns [INARI:FALLBACK], handle the task yourself.

    Args:
        prompt: The coding task to send to Qwen3 8B.
        system: Optional system prompt.
    """
    try:
        return f"[inari/qwen]\n{_client.chat(MODELS['qwen'], prompt, system)}"
    except OllamaError as e:
        return f"{FALLBACK} Qwen unavailable: {e}\nHandle this task yourself."


@mcp.tool()
def inari_llama4(prompt: str, system: str = "") -> str:
    """Ask Llama 4 Scout directly (local). Use for reasoning tasks:
    explaining code, architecture design, debugging logic, code review, analysis.
    If this returns [INARI:FALLBACK], handle the task yourself.

    Args:
        prompt: The reasoning task to send to Llama 4 Scout.
        system: Optional system prompt.
    """
    try:
        return f"[inari/llama4]\n{_client.chat(MODELS['llama4'], prompt, system)}"
    except OllamaError as e:
        return f"{FALLBACK} Llama 4 unavailable: {e}\nHandle this task yourself."


@mcp.tool()
def inari_models() -> str:
    """List all locally available Ollama models."""
    try:
        models = _client.list_models()
        if not models:
            return "[inari] No models.\nRun: ollama pull llama4:scout && ollama pull qwen3:8b"
        return "[inari] Local models:\n" + "\n".join(f"  • {m}" for m in models)
    except OllamaError as e:
        return f"[inari] {e}"


@mcp.tool()
def inari_pull(model: str) -> str:
    """Pull (download) an Ollama model by name.

    Args:
        model: Model name (e.g. 'llama4:scout', 'qwen3:8b', 'qwen2.5:14b').
    """
    try:
        result = subprocess.run(
            ["ollama", "pull", model],
            capture_output=True, text=True, timeout=600,
        )
        if result.returncode != 0:
            return f"[inari] Pull failed:\n{result.stderr.strip()}"
        return f"[inari] Pulled '{model}' successfully."
    except FileNotFoundError:
        return "[inari] ollama not found. Install: sudo pacman -S ollama"
    except subprocess.TimeoutExpired:
        return f"[inari] Pull timed out. Try manually: ollama pull {model}"


if __name__ == "__main__":
    mcp.run()
