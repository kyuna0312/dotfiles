---
name: Inari Routing
description: Use when any coding or reasoning task can be offloaded to local AI models via Ollama. Routes writing, fixing, formatting, and test generation to Qwen3 8B; routes explaining, designing, analyzing, debugging, and reviewing to Llama 4 Scout. Use inari_ask when unsure which model fits.
version: 0.1.0
---

# Inari — Local AI Routing

Inari exposes local Llama 4 and Qwen3 models via Ollama. Claude Code is the brain and orchestrator.

## Routing Rules

| Task type | Tool |
|-----------|------|
| Write / fix / complete / format / test / generate code | `inari_qwen` |
| Explain / design / analyze / debug / review / plan | `inari_llama4` |
| Unsure which model | `inari_ask` (auto-routes) |

**Default:** use `inari_ask` — it classifies and routes automatically.

## Tools

- **`inari_ask(task)`** — Default entry point. Auto-routes based on keyword scoring.
- **`inari_qwen(prompt, system?)`** — Direct Qwen3 8B. Fast coding tasks.
- **`inari_llama4(prompt, system?)`** — Direct Llama 4 Scout. Reasoning tasks.
- **`inari_models()`** — List available local models.
- **`inari_pull(model)`** — Pull a new Ollama model.

## Fallback Behavior

If any inari tool returns a response starting with `[INARI:FALLBACK]`:
- Do **not** call inari again
- Handle the task yourself using your own knowledge
- Mention to the user that local models were unavailable

## Response Prefix

Inari responses are prefixed with the model used:
- `[inari/qwen]` — Qwen3 8B answered
- `[inari/llama4]` — Llama 4 Scout answered
- `[inari/qwen:retry]` or `[inari/llama4:retry]` — fallback model used
- `[INARI:FALLBACK]` — both models unavailable, Claude should handle it

## Prerequisites

Ollama must be running:
```sh
sudo systemctl start ollama
```

Models must be pulled:
```sh
ollama pull qwen3:8b
ollama pull llama4:scout
```
