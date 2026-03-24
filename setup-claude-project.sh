#!/bin/bash

#
# Claude Code Project Setup Script v4.1.1
# Creates CLAUDE.md and supporting files for new projects
#
# Usage: ./setup-claude-project.sh [project_name] [project_description]
#
# Example:
#   ./setup-claude-project.sh MyApp "A web application for task management"
#   ./setup-claude-project.sh  # Interactive mode
#
# Version: 4.1.1
# Updated: March 2026
# Changes from 4.1:
#   - Context-aware statusline hook (adapted from GSD)
#   - Context monitor hook with agent-facing warnings
#   - Cross-platform sed (no more macOS-only sed -i '')
# Changes from 4.0 (PR #1 on s220284/claude-code-setup):
#   - Model-agnostic session continuity (three-state architecture)
#   - /handoff skill for explicit session handoff
#   - Restored SESSION_LOG.md and CONTINUATION_GUIDE.md as cross-model fallback
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cross-platform sed in-place (fixes macOS vs Linux incompatibility)
sed_inplace() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} Claude Code Project Setup v4.1.1${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get project name
if [ -n "$1" ]; then
    PROJECT_NAME="$1"
else
    echo -e "${YELLOW}Enter project name:${NC}"
    read -r PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name is required${NC}"
    exit 1
fi

# Get project description
if [ -n "$2" ]; then
    PROJECT_DESC="$2"
else
    echo -e "${YELLOW}Enter project description (one line):${NC}"
    read -r PROJECT_DESC
fi

if [ -z "$PROJECT_DESC" ]; then
    PROJECT_DESC="A Claude Code managed project"
fi

# Get current date
CURRENT_DATE=$(date +"%Y-%m-%d")

# Determine project directory
if [ -d "$PROJECT_NAME" ]; then
    PROJECT_DIR="$PROJECT_NAME"
    echo -e "${YELLOW}Directory '$PROJECT_NAME' exists. Setting up Claude Code files inside it.${NC}"
else
    echo -e "${YELLOW}Create new directory '$PROJECT_NAME'? (y/n):${NC}"
    read -r CREATE_DIR
    if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
        mkdir -p "$PROJECT_NAME"
        PROJECT_DIR="$PROJECT_NAME"
        echo -e "${GREEN}Created directory: $PROJECT_NAME${NC}"
    else
        PROJECT_DIR="."
        echo -e "${YELLOW}Setting up in current directory${NC}"
    fi
fi

cd "$PROJECT_DIR"

echo ""
echo -e "${BLUE}Creating Claude Code project files...${NC}"
echo ""

# ============================================================================
# Create CLAUDE.md - Main Session Reference (~80-100 lines)
# ============================================================================

cat > CLAUDE.md << 'CLAUDE_EOF'
# CLAUDE.md

**Project:** PROJECT_DESC_PLACEHOLDER

---

## CRITICAL: Cloud-First Development

This application runs in cloud environments (AWS/GCP/Azure).

**Never hardcode local paths:**
```
# WRONG
path = "/Users/username/projects/myapp"

# CORRECT
path = env_var("APP_ROOT", "/app") # Use your language's equivalent
```

**Before writing code, verify:**
1. Paths work in containers (use relative paths or env vars)
2. Credentials come from environment variables
3. No local filesystem dependencies

---

## Engineering Requirements (Three Pillars)

Every production code change MUST include:

1. **Tests** — Run your test suite, aim for >80% coverage, test success AND failure paths
2. **Documentation** — Docstrings/comments for public APIs
3. **Git Commits** — Conventional format with Co-Authored-By footer

No exceptions. No shortcuts.

---

## Modular Documentation

Detailed conventions live in `.claude/rules/` and are loaded automatically:

- `@import .claude/rules/code-style.md` — coding conventions (path-filtered to `src/**`)
- `@import .claude/rules/testing.md` — testing standards (path-filtered to `tests/**`)

Add more rules files as your project grows. Use `paths:` frontmatter to scope rules to specific directories.

> **Tip:** Run `/init` to let Claude analyze your codebase and generate additional project-specific instructions.

---

## Session Continuity Protocol

### State 1: Claude Code (normal)
Auto-memory handles context automatically. Session files stay untouched. Zero token overhead.

### State 2: Claude Code (handoff)
Run `/handoff` to populate all state files in one commit before switching contexts or models.

### State 3: Other models (Copilot, Gemini, Cursor)
Read state files at startup, update them after each session.

| File | Purpose | Update When |
|------|---------|-------------|
| `PROJECT_STATE.md` | System status snapshot | After feature completion |
| `SESSION_LOG.md` | Decisions, context, progress | At handoff (`/handoff`) |
| `CONTINUATION_GUIDE.md` | Next-session bootstrap | At handoff (`/handoff`) |

---

## Project Structure

```
PROJECT_NAME_PLACEHOLDER/
├── CLAUDE.md              # This file (auto-loaded)
├── CLAUDE.local.md        # Personal overrides (gitignored)
├── PROJECT_STATE.md       # System status
├── SESSION_LOG.md         # Session context (handoff only)
├── CONTINUATION_GUIDE.md  # Resume guide (handoff only)
├── src/                   # Source code
├── tests/                 # Test files
├── docs/                  # Documentation
├── scripts/               # Utility scripts
└── .claude/
    ├── settings.json      # Shared configuration & hooks
    ├── settings.local.json # Personal overrides (gitignored)
    ├── hooks/             # Custom hooks
    │   ├── statusline.js  # Context-aware status bar
    │   └── context-monitor.js # Agent context warnings
    ├── rules/             # Modular rule files
    │   ├── code-style.md  # Coding conventions
    │   └── testing.md     # Testing standards
    └── skills/            # Custom skills
        ├── commit/        # Commit workflow skill
        └── handoff/       # Session handoff skill
```

---

## Available Skills & Plugins

### Local Skills (`.claude/skills/`)

- `/commit` — Git commit workflow with conventional format
- `/handoff` — Populate session state files for model switch or context transfer

### Global Plugins

| Plugin | Skills/Agents | Purpose |
|--------|---------------|---------|
| `commit-commands` | `/commit`, `/commit-push-pr`, `/clean_gone` | Git workflow automation |
| `feature-dev` | `/feature-dev` | Guided feature development |
| `pr-review-toolkit` | `/review-pr` + code-reviewer, silent-failure-hunter, type-design-analyzer | Comprehensive PR review |
| `frontend-design` | `/frontend-design` | Production-grade UI development |

> **Agent Teams** (experimental): For background multi-agent workflows, see Claude Code's agent teams feature — the successor to loop-based plugins.

---

*Last updated: DATE_PLACEHOLDER*
CLAUDE_EOF

# Replace placeholders (cross-platform)
sed_inplace "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" CLAUDE.md
sed_inplace "s/PROJECT_DESC_PLACEHOLDER/$PROJECT_DESC/g" CLAUDE.md
sed_inplace "s/DATE_PLACEHOLDER/$CURRENT_DATE/g" CLAUDE.md

echo -e "${GREEN}✓ Created CLAUDE.md${NC}"

# ============================================================================
# Create PROJECT_STATE.md
# ============================================================================

cat > PROJECT_STATE.md << EOF
# $PROJECT_NAME - Project State

**Last Updated:** $CURRENT_DATE

---

## System Status

| Component | Status | Notes |
|-----------|--------|-------|
| Core functionality | Not Started | - |
| Tests | Not Started | - |
| Documentation | In Progress | CLAUDE.md created |
| Cloud Deployment | Not Configured | - |

---

## Current Production State

- **Version:** 0.0.0
- **Environment:** Local development
- **URL:** N/A

---

## Critical Files

| File | Purpose | Do Not Break |
|------|---------|--------------|
| CLAUDE.md | Session reference | Yes |
| .claude/settings.json | Configuration & hooks | Yes |

---

## Recent Changes

- $CURRENT_DATE: Project initialized with Claude Code setup v4.1.1

---

## Known Issues

None yet.

---

## Next Milestone

Define initial project scope and requirements.
EOF

echo -e "${GREEN}✓ Created PROJECT_STATE.md${NC}"

# ============================================================================
# Create SESSION_LOG.md (populated at handoff, empty by default)
# ============================================================================

cat > SESSION_LOG.md << EOF
# $PROJECT_NAME - Session Log

> This file is populated by the \`/handoff\` skill when switching contexts or models.
> Claude Code's auto-memory handles normal session continuity — this file is a cross-model fallback.

---

*No sessions logged yet.*
EOF

echo -e "${GREEN}✓ Created SESSION_LOG.md${NC}"

# ============================================================================
# Create CONTINUATION_GUIDE.md (populated at handoff, empty by default)
# ============================================================================

cat > CONTINUATION_GUIDE.md << EOF
# $PROJECT_NAME - Continuation Guide

> This file is populated by the \`/handoff\` skill to bootstrap the next session.
> Read this first when resuming work, especially if switching models.

---

*No handoff recorded yet. Run \`/handoff\` to populate.*
EOF

echo -e "${GREEN}✓ Created CONTINUATION_GUIDE.md${NC}"

# ============================================================================
# Create .claude/settings.json - Configuration with Hooks
# ============================================================================

mkdir -p .claude

cat > .claude/settings.json << 'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path // empty' | xargs -I{} sh -c 'case \\\"{}\\\" in *.sh) chmod +x \\\"{}\\\" ;; esac'"
          }
        ]
      },
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node .claude/hooks/statusline.js"
          }
        ]
      },
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "node .claude/hooks/context-monitor.js"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"' 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
EOF

echo -e "${GREEN}✓ Created .claude/settings.json${NC}"

# ============================================================================
# Create .claude/settings.local.json - Personal overrides (gitignored)
# ============================================================================

cat > .claude/settings.local.json << 'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
EOF

echo -e "${GREEN}✓ Created .claude/settings.local.json${NC}"

# ============================================================================
# Create .claude/hooks/ - Statusline and Context Monitor
# ============================================================================

mkdir -p .claude/hooks

cat > .claude/hooks/statusline.js << 'HOOK_EOF'
#!/usr/bin/env node

// Claude Code Statusline with Context Usage
// Adapted from GSD's gsd-statusline.js for standalone use
// Source: https://github.com/gsd-build/get-shit-done/blob/main/hooks/gsd-statusline.js
//
// Shows: model | current task | directory | context usage bar

const fs = require('fs');
const path = require('path');
const os = require('os');

let input = '';
// Timeout guard: if stdin doesn't close within 3s, exit silently.
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // Context window display
    // Claude Code reserves ~16.5% for autocompact buffer, so usable context
    // is 83.5% of the total window. We normalize to show 100% at that point.
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctx = '';
    if (remaining != null) {
      const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      // Write context metrics to bridge file for the context-monitor hook
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
          const bridgeData = JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000)
          });
          fs.writeFileSync(bridgePath, bridgeData);
        } catch (e) {
          // Silent fail — bridge is best-effort
        }
      }

      // Build progress bar (10 segments)
      const filled = Math.floor(used / 10);
      const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(10 - filled);

      // Color based on usable context thresholds
      if (used < 50) {
        ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;          // green
      } else if (used < 65) {
        ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;          // yellow
      } else if (used < 80) {
        ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;    // orange
      } else {
        ctx = ` \x1b[5;31m\uD83D\uDC80 ${bar} ${used}%\x1b[0m`; // blinking red + skull
      }
    }

    // Current task from Claude Code's todos
    let task = '';
    const homeDir = os.homedir();
    const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
    const todosDir = path.join(claudeDir, 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          try {
            const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
            const inProgress = todos.find(t => t.status === 'in_progress');
            if (inProgress) task = inProgress.activeForm || '';
          } catch (e) {}
        }
      } catch (e) {
        // Silently fail on file system errors
      }
    }

    // Output statusline
    const dirname = path.basename(dir);
    if (task) {
      process.stdout.write(`\x1b[2m${model}\x1b[0m \u2502 \x1b[1m${task}\x1b[0m \u2502 \x1b[2m${dirname}\x1b[0m${ctx}`);
    } else {
      process.stdout.write(`\x1b[2m${model}\x1b[0m \u2502 \x1b[2m${dirname}\x1b[0m${ctx}`);
    }
  } catch (e) {
    // Silent fail — don't break statusline on parse errors
  }
});
HOOK_EOF

chmod +x .claude/hooks/statusline.js

echo -e "${GREEN}✓ Created .claude/hooks/statusline.js${NC}"

cat > .claude/hooks/context-monitor.js << 'HOOK_EOF'
#!/usr/bin/env node

// Context Monitor - PostToolUse hook
// Adapted from GSD's gsd-context-monitor.js for standalone use
// Source: https://github.com/gsd-build/get-shit-done/blob/main/hooks/gsd-context-monitor.js
//
// How it works:
// 1. The statusline hook writes metrics to /tmp/claude-ctx-{session_id}.json
// 2. This hook reads those metrics after each tool use
// 3. When remaining context drops below thresholds, it injects a warning
//    as additionalContext, which the agent sees in its conversation
//
// Thresholds:
//   WARNING  (remaining <= 35%): Agent should wrap up current task
//   CRITICAL (remaining <= 25%): Agent should stop immediately and save state
//
// Debounce: 5 tool uses between warnings to avoid spam
// Severity escalation bypasses debounce (WARNING -> CRITICAL fires immediately)

const fs = require('fs');
const os = require('os');
const path = require('path');

const WARNING_THRESHOLD = 35;   // remaining_percentage <= 35%
const CRITICAL_THRESHOLD = 25;  // remaining_percentage <= 25%
const STALE_SECONDS = 60;       // ignore metrics older than 60s
const DEBOUNCE_CALLS = 5;       // min tool uses between warnings

let input = '';
// Timeout guard: if stdin doesn't close within 10s, exit silently
// instead of hanging until Claude Code kills the process.
const stdinTimeout = setTimeout(() => process.exit(0), 10000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;

    if (!sessionId) {
      process.exit(0);
    }

    const tmpDir = os.tmpdir();
    const metricsPath = path.join(tmpDir, `claude-ctx-${sessionId}.json`);

    // If no metrics file, this is a subagent or fresh session — exit silently
    if (!fs.existsSync(metricsPath)) {
      process.exit(0);
    }

    const metrics = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
    const now = Math.floor(Date.now() / 1000);

    // Ignore stale metrics
    if (metrics.timestamp && (now - metrics.timestamp) > STALE_SECONDS) {
      process.exit(0);
    }

    const remaining = metrics.remaining_percentage;
    const usedPct = metrics.used_pct;

    // No warning needed
    if (remaining > WARNING_THRESHOLD) {
      process.exit(0);
    }

    // Debounce: check if we warned recently
    const warnPath = path.join(tmpDir, `claude-ctx-${sessionId}-warned.json`);
    let warnData = { callsSinceWarn: 0, lastLevel: null };
    let firstWarn = true;

    if (fs.existsSync(warnPath)) {
      try {
        warnData = JSON.parse(fs.readFileSync(warnPath, 'utf8'));
        firstWarn = false;
      } catch (e) {
        // Corrupted file, reset
      }
    }

    warnData.callsSinceWarn = (warnData.callsSinceWarn || 0) + 1;

    const isCritical = remaining <= CRITICAL_THRESHOLD;
    const currentLevel = isCritical ? 'critical' : 'warning';

    // Emit immediately on first warning, then debounce subsequent ones
    // Severity escalation (WARNING -> CRITICAL) bypasses debounce
    const severityEscalated = currentLevel === 'critical' && warnData.lastLevel === 'warning';
    if (!firstWarn && warnData.callsSinceWarn < DEBOUNCE_CALLS && !severityEscalated) {
      fs.writeFileSync(warnPath, JSON.stringify(warnData));
      process.exit(0);
    }

    // Reset debounce counter
    warnData.callsSinceWarn = 0;
    warnData.lastLevel = currentLevel;
    fs.writeFileSync(warnPath, JSON.stringify(warnData));

    // Build advisory warning message
    let message;
    if (isCritical) {
      message = `CONTEXT CRITICAL: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
        'Context is nearly exhausted. Inform the user that context is low and ask how they ' +
        'want to proceed. Consider using /compact or starting a fresh session.';
    } else {
      message = `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
        'Be aware that context is getting limited. Avoid unnecessary exploration or ' +
        'starting new complex work. Consider using /compact soon.';
    }

    const output = {
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: message
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    // Silent fail — never block tool execution
    process.exit(0);
  }
});
HOOK_EOF

chmod +x .claude/hooks/context-monitor.js

echo -e "${GREEN}✓ Created .claude/hooks/context-monitor.js${NC}"

# ============================================================================
# Create .claude/rules/ - Modular rule files
# ============================================================================

mkdir -p .claude/rules

cat > .claude/rules/code-style.md << 'EOF'
---
paths:
  - "src/**"
---

# Code Style

<!-- Customize these conventions for your language and project -->

- Use consistent naming: `snake_case` for functions/variables, `PascalCase` for classes/types
- Keep functions focused — one responsibility per function
- Use environment variables for configuration, never hardcode secrets
- Prefer explicit over implicit — avoid magic numbers, use named constants
- Use parameterized queries for database operations (never string interpolation)
EOF

echo -e "${GREEN}✓ Created .claude/rules/code-style.md${NC}"

cat > .claude/rules/testing.md << 'EOF'
---
paths:
  - "tests/**"
---

# Testing Standards

<!-- Customize these standards for your test framework -->

- Every new feature or bug fix requires tests
- Test both success and failure paths
- Mock external dependencies (APIs, databases, filesystems)
- Use descriptive test names that explain the scenario
- Aim for >80% code coverage on new code
- Keep test files mirroring the source directory structure
EOF

echo -e "${GREEN}✓ Created .claude/rules/testing.md${NC}"

# ============================================================================
# Create commit skill
# ============================================================================

mkdir -p .claude/skills/commit

cat > .claude/skills/commit/SKILL.md << 'EOF'
---
name: commit
description: Create properly formatted git commits
user-invocable: true
---

# Commit Skill

**Purpose:** Create properly formatted git commits with consistent style.

---

## When to Use

- User explicitly asks to commit
- After completing a feature or fix
- When work reaches a logical checkpoint

## Blocking Gates

1. Must have changes to commit (staged or unstaged)
2. Must not have merge conflicts
3. Tests should pass (if test suite exists)

## Steps

1. **Check Status**
   - Run `git status` to see all changes
   - Run `git diff` to review unstaged changes
   - Run `git diff --staged` to review staged changes

2. **Review Recent Style**
   - Run `git log --oneline -5` to see recent commit messages
   - Match the project's commit message style

3. **Stage Changes**
   - Stage relevant files with `git add`
   - Do NOT stage files that contain secrets

4. **Generate Message**
   - Use conventional commits format: `type: subject`
   - Types: feat, fix, docs, refactor, test, chore
   - Include body explaining what and why
   - Add Co-Authored-By footer

5. **Create Commit**
   ```bash
   git commit -m "$(cat <<'COMMIT_EOF'
   type: Short description

   - Detailed point 1
   - Detailed point 2

   Co-Authored-By: Claude <noreply@anthropic.com>
   COMMIT_EOF
   )"
   ```

6. **Verify**
   - Run `git status` to confirm commit succeeded
   - Run `git log -1` to review the commit

## Safety Rules

- NEVER commit files containing secrets
- NEVER use --force or --no-verify
- NEVER amend pushed commits without explicit permission
- ALWAYS use HEREDOC for multi-line messages
EOF

echo -e "${GREEN}✓ Created .claude/skills/commit/SKILL.md${NC}"

# ============================================================================
# Create handoff skill (v4.1 addition)
# ============================================================================

mkdir -p .claude/skills/handoff

cat > .claude/skills/handoff/SKILL.md << 'EOF'
---
name: handoff
description: Populate session state files for model switch or context transfer
user-invocable: true
---

# Handoff Skill

**Purpose:** Capture current session context into state files so work can continue in a different model, session, or context window.

---

## When to Use

- User says `/handoff` or asks to "hand off", "save state", "switch models"
- Before a long break or context switch
- When context window is getting full and work needs to resume later

## What It Does

Populates three files in one atomic commit:

1. **SESSION_LOG.md** — What happened this session (decisions, blockers, progress)
2. **CONTINUATION_GUIDE.md** — Bootstrap instructions for the next session
3. **PROJECT_STATE.md** — Updated system status snapshot

## Steps

1. **Check for existing state**
   - Read `SESSION_LOG.md` if it exists (to append, not overwrite history)
   - Read `PROJECT_STATE.md` for current status
   - Read `CONTINUATION_GUIDE.md` for prior context

2. **Generate SESSION_LOG.md entry**
   - Date and model used
   - Goal of the session
   - What was accomplished
   - Key decisions made and why
   - Blockers or issues encountered
   - What was NOT finished

3. **Generate CONTINUATION_GUIDE.md**
   - One-paragraph summary of where things stand
   - Exact next steps (numbered, actionable)
   - Files that were being worked on
   - Any commands that need to be run
   - Warnings or gotchas for the next session

4. **Update PROJECT_STATE.md**
   - Update component statuses
   - Update recent changes
   - Update known issues if applicable

5. **Commit state files**
   ```bash
   git add SESSION_LOG.md CONTINUATION_GUIDE.md PROJECT_STATE.md
   git diff --cached --quiet || git commit -m "$(cat <<'COMMIT_EOF'
   chore: session handoff

   Co-Authored-By: Claude <noreply@anthropic.com>
   COMMIT_EOF
   )"
   ```

## Safety Rules

- Guard commit with `git diff --cached --quiet ||` to prevent empty commits
- NEVER overwrite SESSION_LOG.md history — append new entries
- NEVER include secrets or credentials in state files
- Keep CONTINUATION_GUIDE.md actionable and concise
EOF

echo -e "${GREEN}✓ Created .claude/skills/handoff/SKILL.md${NC}"

# ============================================================================
# Create .gitignore
# ============================================================================

if [ ! -f .gitignore ]; then
cat > .gitignore << 'EOF'
# Claude Code local overrides
CLAUDE.local.md
.claude/settings.local.json

# Environment
.env
.env.*
!.env.example

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Dependencies
node_modules/
vendor/
venv/
.venv/

# Build artifacts
build/
dist/
out/
*.egg-info/

# Testing / Coverage
.coverage
htmlcov/
coverage/
*.lcov

# Data
*.db
*.sqlite
*.sqlite3

# Logs
*.log
logs/

# Credentials (NEVER commit)
credentials/
*.pem
*.key
secrets.json
token.json
EOF

echo -e "${GREEN}✓ Created .gitignore${NC}"
else
echo -e "${YELLOW}⊘ .gitignore already exists, skipping${NC}"
fi

# ============================================================================
# Create directory structure
# ============================================================================

mkdir -p src tests docs scripts .claude/skills .claude/rules .claude/hooks .github/workflows

echo -e "${GREEN}✓ Created directories: src/, tests/, docs/, scripts/, .claude/{skills,rules,hooks}/, .github/workflows/${NC}"

# ============================================================================
# Create GitHub Actions workflow template
# ============================================================================

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      # TODO: Add your language-specific setup steps here
      # Examples:
      # - uses: actions/setup-node@v4
      #   with: { node-version: '20' }
      # - uses: actions/setup-python@v5
      #   with: { python-version: '3.12' }
      # - uses: actions/setup-go@v5
      #   with: { go-version: '1.22' }

      - name: Install dependencies
        run: echo "TODO: Add your install command (npm ci, pip install -r requirements.txt, etc.)"

      - name: Run tests
        run: echo "TODO: Add your test command (npm test, pytest -v, go test ./..., etc.)"
EOF

echo -e "${GREEN}✓ Created .github/workflows/ci.yml${NC}"

# ============================================================================
# Initialize git if not already a repo
# ============================================================================

if [ ! -d .git ]; then
    echo ""
    echo -e "${YELLOW}Initialize git repository? (y/n):${NC}"
    read -r INIT_GIT
    if [ "$INIT_GIT" = "y" ] || [ "$INIT_GIT" = "Y" ]; then
        git init
        git add .
        git commit -m "$(cat <<'COMMIT_EOF'
chore: Initialize project with Claude Code setup v4.1.1

Project Files:
- CLAUDE.md - Session reference (model-agnostic continuity)
- PROJECT_STATE.md - Status tracking
- SESSION_LOG.md - Cross-model session log (handoff only)
- CONTINUATION_GUIDE.md - Resume bootstrap (handoff only)

Configuration:
- .claude/settings.json - Permissions, hooks (statusline, context monitor, shell fixer, notifications)
- .claude/settings.local.json - Personal overrides (gitignored)
- .claude/hooks/statusline.js - Context-aware status bar
- .claude/hooks/context-monitor.js - Agent context warnings
- .claude/rules/code-style.md - Path-specific code conventions
- .claude/rules/testing.md - Path-specific testing standards
- .claude/skills/commit/ - Commit skill with YAML frontmatter
- .claude/skills/handoff/ - Session handoff skill
- .github/workflows/ci.yml - CI pipeline template

v4.1.1 Changes:
- Context-aware statusline hook (adapted from GSD)
- Context monitor with agent-facing warnings and debounce
- /handoff skill for model-agnostic session continuity
- Cross-platform sed (no more macOS-only sed -i '')
- SESSION_LOG.md and CONTINUATION_GUIDE.md restored as cross-model fallback

Co-Authored-By: Claude <noreply@anthropic.com>
COMMIT_EOF
)"
        echo -e "${GREEN}✓ Initialized git repository and made initial commit${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Git repository already exists${NC}"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN} Setup Complete! (v4.1.1)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "Created files:"
echo -e " ${GREEN}✓${NC} CLAUDE.md - Main session reference (model-agnostic)"
echo -e " ${GREEN}✓${NC} PROJECT_STATE.md - System status tracking"
echo -e " ${GREEN}✓${NC} SESSION_LOG.md - Cross-model session log"
echo -e " ${GREEN}✓${NC} CONTINUATION_GUIDE.md - Resume bootstrap"
echo -e " ${GREEN}✓${NC} .claude/settings.json - Permissions, hooks (statusline + context monitor)"
echo -e " ${GREEN}✓${NC} .claude/settings.local.json - Personal overrides (gitignored)"
echo -e " ${GREEN}✓${NC} .claude/hooks/statusline.js - Context-aware status bar"
echo -e " ${GREEN}✓${NC} .claude/hooks/context-monitor.js - Agent context warnings"
echo -e " ${GREEN}✓${NC} .claude/rules/code-style.md - Code conventions (path-specific)"
echo -e " ${GREEN}✓${NC} .claude/rules/testing.md - Testing standards (path-specific)"
echo -e " ${GREEN}✓${NC} .claude/skills/commit/SKILL.md - Commit skill"
echo -e " ${GREEN}✓${NC} .claude/skills/handoff/SKILL.md - Handoff skill"
echo -e " ${GREEN}✓${NC} .github/workflows/ci.yml - CI pipeline template"
echo -e " ${GREEN}✓${NC} .gitignore - Git ignore rules"
echo ""

echo -e "${CYAN}v4.1.1 Highlights:${NC}"
echo -e " • Context statusline — colored progress bar showing context usage in terminal"
echo -e " • Context monitor — agent-facing warnings at 65%/75% used (with debounce)"
echo -e " • Handoff skill — /handoff populates state files for cross-model continuity"
echo -e " • Cross-platform sed — works on macOS and Linux"
echo -e " • Three-state session continuity (Claude auto-memory / explicit handoff / other models)"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo -e " 1. cd $PROJECT_DIR"
echo -e " 2. Customize .claude/rules/ for your language and framework"
echo -e " 3. Run /init to generate codebase-specific instructions"
echo -e " 4. Start Claude Code: claude"
echo ""
