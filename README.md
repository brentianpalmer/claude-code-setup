# Claude Code Project Setup

Shelly Palmer's project scaffolding toolkit for AI-assisted development.
Works with Claude Code, OpenAI Codex, GitHub Copilot, Gemini, and any other
AI coding assistant.

## What's Included

| File | Description |
|------|-------------|
| `setup-claude-project.sh` | Shell script that creates a complete AI-assisted project structure |
| `index.html` | Programmer's Guide with full documentation |

## Quick Start

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/s220284/claude-code-setup/main/setup-claude-project.sh

# Make it executable
chmod +x setup-claude-project.sh

# Run it in your project directory
./setup-claude-project.sh
```

## What the Script Creates

```
your-project/
├── CLAUDE.md                  # AI instructions — auto-loaded by Claude Code
├── PROJECT_STATE.md           # System status (shared memory layer)
├── SESSION_LOG.md             # Work history (shared memory layer)
├── CONTINUATION_GUIDE.md      # Resume guide (shared memory layer)
├── .claude/
│   ├── settings.json          # Permissions, hooks, MCP config
│   ├── settings.local.json    # Personal overrides (git-ignored)
│   ├── rules/
│   │   ├── code-style.md      # Code conventions (path-scoped)
│   │   └── testing.md         # Testing standards (path-scoped)
│   ├── hooks/                 # Automation scripts
│   └── skills/
│       ├── commit/            # Conventional commit workflow
│       └── handoff/           # Model handoff workflow ← new in v4.1
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions template
├── src/
├── tests/
├── docs/
└── scripts/
```

## Key Features

- **Hooks**: PostToolUse hook auto-fixes shell script line endings; Notification hook sends macOS alerts when Claude needs attention
- **Modular Rules**: `.claude/rules/` directory with path-specific `paths:` frontmatter for scoped conventions
- **Model-Agnostic Memory**: Works with Claude Code's auto-memory *and* provides a universal four-file fallback for any other model
- **Explicit Handoff**: `/handoff` skill lets Claude Code snapshot full project state for seamless handoff to any other AI tool
- **Language-Agnostic**: No framework or language assumptions — works with any tech stack
- **Slim CLAUDE.md**: Under 100 lines of focused, project-specific guidance

## Model Compatibility

This setup works with any AI coding assistant:

| Model | Memory Mechanism | Session Files Used? |
|-------|-----------------|---------------------|
| Claude Code | Auto-memory (built-in) | No — not needed during normal operation |
| Claude Code → handoff | Auto-memory + `/handoff` skill | Yes — populated once at handoff |
| OpenAI Codex | Session files | Yes — reads and updates every session |
| GitHub Copilot | Session files | Yes — reads and updates every session |
| Gemini, Cursor, etc. | Session files | Yes — reads and updates every session |

Claude Code's auto-memory is outside the context window, so it costs no tokens.
Non-Claude models read `PROJECT_STATE.md`, `SESSION_LOG.md`, and
`CONTINUATION_GUIDE.md` as their persistent memory layer.

## Switching AI Models

When you're working in Claude Code and want to switch to another model:

```
# In Claude Code, say:
"commit for model handoff"
# or:
/handoff
```

Claude Code will:
1. Write a full session summary to `SESSION_LOG.md`
2. Update `PROJECT_STATE.md` with current system status
3. Refresh `CONTINUATION_GUIDE.md` with current startup workflows
4. Create a labeled git commit

The next model opens the project, reads the three state files, and picks up
exactly where Claude Code left off.

## Version 4.1 Improvements

v4.1 adds model-agnostic portability on top of the v4.0 architecture:

- **Model-agnostic continuity**: Three-state model — Claude Code normal, Claude Code handoff, any other model
- **Restored session files**: `SESSION_LOG.md` and `CONTINUATION_GUIDE.md` back in scaffold as the cross-model memory layer
- **`/handoff` skill**: Explicit, intentional handoff commit that populates all state files when switching models
- **Updated CLAUDE.md template**: Conditional instructions for Claude Code vs. other models — each model reads only what applies to it
- **Zero token overhead for Claude Code**: Auto-memory unchanged; session files only touched at explicit handoff

### Previous version (v4.0)
- Hooks system with PostToolUse and Notification scaffolding
- Modular rules with `paths:` YAML frontmatter
- Auto-memory replacing session logs (Claude Code only)
- Language-agnostic patterns
- Slimmed CLAUDE.md (~80 lines)
- Settings schema reference and pre-configured permissions

## Programmer's Guide

Full documentation: **https://s220284.github.io/claude-code-setup**

The guide covers the complete script walkthrough, hooks system, modular rules,
each generated file explained, global plugins and skills reference, and
model handoff workflow.

## Requirements

- macOS or Linux (WSL works on Windows)
- Bash shell
- Claude Code CLI installed (for Claude Code features)

## Customization

After running the script, customize these files for your project:

1. **CLAUDE.md** — add project-specific tech stack and rules
2. **.claude/rules/** — edit code-style.md and testing.md for your language
3. **.claude/settings.json** — add MCP servers, adjust permissions and hooks
4. **.github/workflows/ci.yml** — add your language-specific setup and test commands

## License

MIT License — Use freely, attribution appreciated.

## Author

**Shelly Palmer** — shellypalmer.com

---

*Version 4.1 — February 2026*
