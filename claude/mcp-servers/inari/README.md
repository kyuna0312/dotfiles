# Inari MCP — Local AI Layer for Claude Code

Routes tasks to local Ollama models. Claude Code stays the brain; Inari offloads coding and reasoning work to local hardware.

```
Claude Code (orchestrator)
  └── inari_ask           ← default entry point
        ├── Qwen3 8B      ← coding: write, fix, complete, test, format
        ├── Llama 4 Scout ← reasoning: explain, design, analyze, review
        └── [INARI:FALLBACK] → Claude handles it if both models fail
```

---

## Prerequisites

| Tool | Install |
|------|---------|
| [Ollama](https://ollama.com) | `sudo pacman -S ollama` |
| [uv](https://docs.astral.sh/uv/) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Python ≥ 3.10 | bundled with Manjaro / `sudo pacman -S python` |

---

## Install

### 1. Pull models

```sh
ollama pull qwen3:8b
ollama pull llama4:scout
```

Verify:

```sh
ollama list
```

### 2. Enable Ollama service

```sh
sudo systemctl enable --now ollama
```

Check it's running:

```sh
curl http://localhost:11434/api/tags
```

### 3. Install Python dependencies

From the server directory:

```sh
cd ~/dotfiles/claude/mcp-servers/inari
uv sync
```

This reads `pyproject.toml` and installs `mcp[cli]` into `.venv/`.

### 4. Register with Claude Code

Add to `~/.claude/settings.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "inari": {
      "command": "uv",
      "args": [
        "run",
        "--project", "/home/kyuna/dotfiles/claude/mcp-servers/inari",
        "python", "/home/kyuna/dotfiles/claude/mcp-servers/inari/server.py"
      ]
    }
  }
}
```

> If you use the dotfiles symlink setup, this is already done — `~/.claude/settings.json` → `~/dotfiles/claude/settings.json`.

### 5. Verify

Restart Claude Code, then run:

```sh
claude mcp list
```

`inari` should appear. Inside a session, call:

```
inari_models
```

You should see `qwen3:8b` and `llama4:scout` listed.

---

## Tools

| Tool | When to use |
|------|-------------|
| `inari_ask` | Default — auto-routes to best model |
| `inari_qwen` | Force Qwen3 8B for coding tasks |
| `inari_llama4` | Force Llama 4 Scout for reasoning |
| `inari_models` | List available local models |
| `inari_pull` | Pull a new model (e.g. `qwen2.5:14b`) |

### Routing logic

`inari_ask` scores keywords in your prompt:

- **Qwen signals:** `write fix complete implement generate format rename refactor test convert translate`
- **Llama signals:** `explain why design analyze compare review understand debug plan think reason describe summarize`
- Prompts > 400 chars get +1 Llama score (longer = more reasoning)
- Ties go to Qwen (faster)

### Fallback behavior

If a response starts with `[INARI:FALLBACK]`, Ollama is unreachable or the model isn't pulled. Claude Code handles the task itself — no retry needed.

---

## Routing reference (for CLAUDE.md)

```markdown
| Task type | Tool |
|-----------|------|
| Write / fix / complete / format / test / generate code | `inari_qwen` |
| Explain / design / analyze / debug / review / plan | `inari_llama4` |
| Unsure which model | `inari_ask` |
```

---

## Troubleshooting

**Ollama unreachable**
```sh
sudo systemctl start ollama
curl http://localhost:11434/api/tags   # should return JSON
```

**Model not found**
```sh
ollama pull qwen3:8b
ollama pull llama4:scout
```

**`uv` not found**
```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
# then restart shell or: source ~/.cargo/env
```

**MCP server not listed in Claude Code**
- Confirm the `inari` block is in `~/.claude/settings.json`
- Restart Claude Code (full quit, not just new session)
- Run `uv run --project ~/dotfiles/claude/mcp-servers/inari python server.py` manually to see errors

**Slow responses**
- Qwen3 8B needs ~8 GB VRAM or ~6 GB RAM for CPU inference
- Llama 4 Scout needs more — if slow, swap to `llama4:maverick` or a smaller model by editing `MODELS` in `server.py`

---

## Customization

Edit `server.py` to change models or routing keywords:

```python
# swap models
MODELS = {
    "qwen":   "qwen2.5:14b",      # bigger Qwen
    "llama4": "llama4:maverick",   # bigger Llama 4
}

# add routing keywords
_QWEN_SIGNALS.add("scaffold")
_LLAMA_SIGNALS.add("optimize")
```

Re-run `uv sync` if you add new dependencies.
