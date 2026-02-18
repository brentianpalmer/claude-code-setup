#!/bin/bash
#
# Claude Code Project Setup Script v4.1.0
# Creates CLAUDE.md and supporting files for new projects
#
# Usage: ./setup-claude-project.sh [project_name] [project_description]
#
# Example:
#   ./setup-claude-project.sh MyApp "A web application for task management"
#   ./setup-claude-project.sh  # Interactive mode
#
# Version: 4.1.0
# Updated: February 2026
# Changes: Model-agnostic session continuity, /handoff skill, restored session
#          files (SESSION_LOG.md, CONTINUATION_GUIDE.md) as cross-model memory
#          layer. Claude Code still uses auto-memory by default; other models
#          use the session files. Explicit /handoff command snapshots state for
#          seamless model switching.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Claude Code Project Setup v4.1${NC}"
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
path = env_var("APP_ROOT", "/app")  # Use your language's equivalent
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

**If you are Claude Code:**
Auto-memory is your session context. Do NOT read or update SESSION_LOG.md,
PROJECT_STATE.md, or CONTINUATION_GUIDE.md during normal operation.
This keeps your context window clean and token usage low.

Model handoff: If the user says "commit for model handoff", "prepare handoff
to [model]", or invokes /handoff — run the handoff skill. It will populate
all state files and produce a labeled commit. The receiving model uses those
files as its starting context.

**If you are any other model (OpenAI, Copilot, Gemini, Cursor, etc.):**
These files ARE your memory. You have no other persistent context.

Session start — read in this order:
  1. PROJECT_STATE.md      → current system status
  2. SESSION_LOG.md        → work history and next steps
  3. CONTINUATION_GUIDE.md → startup commands and key workflows

Session end / after every commit — update:
  SESSION_LOG.md   (append: work done, decisions made, next steps)
  PROJECT_STATE.md (update status table if system state changed)

---

## Project Structure

```
PROJECT_NAME_PLACEHOLDER/
├── CLAUDE.md              # This file (auto-loaded)
├── CLAUDE.local.md        # Personal overrides (gitignored)
├── PROJECT_STATE.md       # System status (handoff layer)
├── SESSION_LOG.md         # Work history (handoff layer)
├── CONTINUATION_GUIDE.md  # Resume guide (handoff layer)
├── src/                   # Source code
├── tests/                 # Test files
├── docs/                  # Documentation
├── scripts/               # Utility scripts
└── .claude/
    ├── settings.json      # Shared configuration & hooks
    ├── settings.local.json # Personal overrides (gitignored)
    ├── rules/             # Modular rule files
    │   ├── code-style.md  # Coding conventions
    │   └── testing.md     # Testing standards
    └── skills/            # Custom skills
        ├── commit/        # Commit workflow skill
        └── handoff/       # Model handoff skill
```

---

## Available Skills & Plugins

### Local Skills (`.claude/skills/`)

- `/commit`  — Git commit workflow with conventional format
- `/handoff` — Populate state files and commit for model switch

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

# Replace placeholders
sed -i '' "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" CLAUDE.md
sed -i '' "s/PROJECT_DESC_PLACEHOLDER/$PROJECT_DESC/g" CLAUDE.md
sed -i '' "s/DATE_PLACEHOLDER/$CURRENT_DATE/g" CLAUDE.md

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

- $CURRENT_DATE: Project initialized with Claude Code setup v4.1

---

## Known Issues

None yet.

---

## Next Milestone

Define initial project scope and requirements.
EOF

echo -e "${GREEN}✓ Created PROJECT_STATE.md${NC}"

# ============================================================================
# Create SESSION_LOG.md - Append-only work history (cross-model memory layer)
# ============================================================================
cat > SESSION_LOG.md << EOF
# $PROJECT_NAME - Session Log

Append-only log of AI work sessions. Most recent entry at top.

Updated by non-Claude models every session, and by Claude Code on /handoff.

---

## Session: $CURRENT_DATE

### Summary
- Initialized project with claude-code-setup v4.1 (model-agnostic edition)
- Created project directory structure and all configuration files

### Files Created
- CLAUDE.md — AI instructions with model-agnostic continuity protocol
- PROJECT_STATE.md — System status tracker
- SESSION_LOG.md — This file
- CONTINUATION_GUIDE.md — Resume guide
- .claude/settings.json — Hooks and permissions configuration
- .claude/rules/code-style.md — Code conventions (path-scoped to src/**)
- .claude/rules/testing.md — Testing standards (path-scoped to tests/**)
- .claude/skills/commit/SKILL.md — Conventional commit workflow
- .claude/skills/handoff/SKILL.md — Model handoff workflow
- .github/workflows/ci.yml — Language-agnostic CI template

### Decisions Made
- Using claude-code-setup v4.1 with model-agnostic session continuity
- Claude Code uses auto-memory during normal operation (no token overhead)
- Other models (Codex, Copilot, Gemini, etc.) use these session files as memory
- Handoff between models triggered explicitly via /handoff skill

### Next Steps
- [ ] Define project requirements
- [ ] Set up development environment
- [ ] Create initial implementation plan
- [ ] Configure MCP servers if needed

### Open Questions
- None yet

---
EOF

echo -e "${GREEN}✓ Created SESSION_LOG.md${NC}"

# ============================================================================
# Create CONTINUATION_GUIDE.md - Quick-start reference (cross-model memory layer)
# ============================================================================
cat > CONTINUATION_GUIDE.md << 'EOF'
# CONTINUATION_GUIDE.md

Quick reference for resuming work on this project.
Update this file whenever startup commands or key workflows change.

---

## Startup Commands

```bash
# 1. Check git status
git status

# 2. Check for running processes
ps aux | grep node   # adjust for your stack

# 3. Run tests (once they exist)
# [add your test command here]

# 4. Check recent CI runs
gh run list --limit 3
```

---

## State Verification

1. Read PROJECT_STATE.md — current component status and known issues
2. Read SESSION_LOG.md — recent work and next steps
3. Check recent commits: `git log --oneline -5`

---

## Key Workflows

### Adding a New Feature
1. Note intent in SESSION_LOG.md (for non-Claude models)
2. Plan before implementing
3. Implement the feature with tests
4. Run tests and verify passing
5. Commit with conventional message
6. Update PROJECT_STATE.md if system status changed
7. Append session summary to SESSION_LOG.md

### Fixing a Bug
1. Reproduce the bug
2. Write a failing test
3. Fix the bug
4. Verify test passes
5. Commit with `fix:` prefix

### Switching AI Models (from Claude Code)
1. In Claude Code, say: "commit for model handoff" or run /handoff
2. Claude Code populates all state files and commits
3. Open the project in your new AI tool
4. The new model reads PROJECT_STATE.md → SESSION_LOG.md → CONTINUATION_GUIDE.md

---

## Important Files

| File | Purpose |
|------|---------|
| CLAUDE.md | AI instructions (always read at startup) |
| PROJECT_STATE.md | Current system status |
| SESSION_LOG.md | Work history and next steps |
| .claude/settings.json | MCP servers and hooks config |

---

*Update this file when startup commands or key workflows change.*
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
            "command": "jq -r '.tool_input.file_path // empty' | xargs -I{} sh -c 'case \"{}\" in *.sh) sed -i \"\" \"s/\\r$//\" \"{}\" && chmod +x \"{}\" ;; esac'"
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
# Create commit skill with YAML frontmatter
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
# Create handoff skill - Model portability (new in v4.1)
# ============================================================================
mkdir -p .claude/skills/handoff

cat > .claude/skills/handoff/SKILL.md << 'EOF'
---
name: handoff
description: Prepare this project for handoff to a different AI model. Populates SESSION_LOG.md, PROJECT_STATE.md, and CONTINUATION_GUIDE.md with current state, then commits.
user-invocable: true
---

# Handoff Skill

Run this skill when the user wants to switch from Claude Code to another AI
model (OpenAI, Copilot, Gemini, Cursor, etc.), or any time project state files
need to be refreshed for cross-model portability.

**Trigger phrases:** "commit for model handoff", "prepare handoff to [model]",
"I want to switch to [model]", or `/handoff`

---

## Steps

### 1. Gather current state
- Run `git log --oneline -10` to review recent commits
- Run `git status` to check for any uncommitted changes
- Note what was worked on during this session

### 2. Update SESSION_LOG.md
Append a new session entry at the top (below the header, above previous entries):

```markdown
## Session: YYYY-MM-DD

### Summary
- [What was worked on this session]

### Files Created/Modified
- [list files changed]

### Decisions Made
- [key decisions and the reasoning]

### Next Steps
- [ ] [concrete next step for the receiving model]
- [ ] [another next step]

### Open Questions
- [anything unresolved]

---
```

### 3. Update PROJECT_STATE.md
Refresh:
- System Status table — update component statuses to reflect current reality
- Current Production State — version, environment, URL if applicable
- Recent Changes — add an entry for today's work
- Known Issues — add any new issues discovered, remove resolved ones

### 4. Verify CONTINUATION_GUIDE.md
Check that startup commands and key workflows are still accurate.
Update if anything has changed (new test commands, new env setup, etc.).

### 5. Commit the handoff
Stage and commit all three state files:

```bash
git add SESSION_LOG.md PROJECT_STATE.md CONTINUATION_GUIDE.md
git diff --cached --quiet || git commit -m "$(cat <<'COMMIT_EOF'
chore: model handoff - state files updated for cross-model continuity

- SESSION_LOG.md updated with current session summary and next steps
- PROJECT_STATE.md refreshed with current system status
- CONTINUATION_GUIDE.md verified and updated if needed

Co-Authored-By: Claude <noreply@anthropic.com>
COMMIT_EOF
)"
```

---

## What the Receiving Model Should Do

When a non-Claude model picks up this project after a handoff commit:
1. Read `PROJECT_STATE.md` → `SESSION_LOG.md` → `CONTINUATION_GUIDE.md`
2. Follow the Session Continuity Protocol in CLAUDE.md
3. Update the session files at the end of every session

---

## Notes

- Only run this when actually switching models — not on every session
- If the user changes their mind and stays on Claude Code, no harm done;
  the state files will simply be current and accurate
- The handoff commit is a normal git commit — it shows in git log and is
  fully reversible
- If there are uncommitted code changes, commit those first with /commit,
  then run /handoff
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
# Create GitHub Actions workflow template (language-agnostic)
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
      #   - uses: actions/setup-node@v4
      #     with: { node-version: '20' }
      #   - uses: actions/setup-python@v5
      #     with: { python-version: '3.12' }
      #   - uses: actions/setup-go@v5
      #     with: { go-version: '1.22' }

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
        git commit -m "chore: Initialize project with Claude Code setup v4.1

Project Files:
- CLAUDE.md - Session reference with model-agnostic continuity protocol
- PROJECT_STATE.md - Status tracking (handoff layer)
- SESSION_LOG.md - Append-only work history (handoff layer)
- CONTINUATION_GUIDE.md - Quick-start reference (handoff layer)

Configuration:
- .claude/settings.json - Permissions, hooks (shell fixer, notifications)
- .claude/settings.local.json - Personal overrides (gitignored)
- .claude/rules/code-style.md - Path-specific code conventions
- .claude/rules/testing.md - Path-specific testing standards
- .claude/skills/commit/ - Commit skill with YAML frontmatter
- .claude/skills/handoff/ - Model handoff skill (new in v4.1)
- .github/workflows/ci.yml - CI pipeline template

v4.1 Changes:
- Model-agnostic session continuity (three-state model)
- Claude Code uses auto-memory; session files untouched during normal operation
- /handoff skill: explicit handoff commit when switching AI models
- SESSION_LOG.md and CONTINUATION_GUIDE.md restored as cross-model memory layer
- CLAUDE.md template updated with conditional Claude Code / other-model protocol

Co-Authored-By: Claude <noreply@anthropic.com>"
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
echo -e "${GREEN}  Setup Complete! (v4.1)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Created files:"
echo -e "  ${GREEN}✓${NC} CLAUDE.md                        - Main session reference (model-agnostic)"
echo -e "  ${GREEN}✓${NC} PROJECT_STATE.md                 - System status tracking"
echo -e "  ${GREEN}✓${NC} SESSION_LOG.md                   - Append-only work history"
echo -e "  ${GREEN}✓${NC} CONTINUATION_GUIDE.md            - Quick-start reference"
echo -e "  ${GREEN}✓${NC} .claude/settings.json            - Permissions & hooks"
echo -e "  ${GREEN}✓${NC} .claude/settings.local.json      - Personal overrides (gitignored)"
echo -e "  ${GREEN}✓${NC} .claude/rules/code-style.md      - Code conventions (path-specific)"
echo -e "  ${GREEN}✓${NC} .claude/rules/testing.md         - Testing standards (path-specific)"
echo -e "  ${GREEN}✓${NC} .claude/skills/commit/SKILL.md   - Commit skill"
echo -e "  ${GREEN}✓${NC} .claude/skills/handoff/SKILL.md  - Model handoff skill"
echo -e "  ${GREEN}✓${NC} .github/workflows/ci.yml         - CI pipeline template"
echo -e "  ${GREEN}✓${NC} .gitignore                       - Git ignore rules"
echo ""
echo -e "Created directories:"
echo -e "  ${GREEN}✓${NC} src/              - Source code"
echo -e "  ${GREEN}✓${NC} tests/            - Test files"
echo -e "  ${GREEN}✓${NC} docs/             - Documentation"
echo -e "  ${GREEN}✓${NC} scripts/          - Utility scripts"
echo -e "  ${GREEN}✓${NC} .claude/skills/   - Custom skills (commit, handoff)"
echo -e "  ${GREEN}✓${NC} .claude/rules/    - Modular rule files"
echo -e "  ${GREEN}✓${NC} .claude/hooks/    - Custom hooks"
echo -e "  ${GREEN}✓${NC} .github/workflows/ - CI/CD"
echo ""
echo -e "${CYAN}v4.1 Highlights:${NC}"
echo -e "  • Model-agnostic — works with Claude Code, Copilot, Codex, Gemini, etc."
echo -e "  • /handoff skill — explicit commit to hand project off to another AI model"
echo -e "  • Zero token overhead — Claude Code uses auto-memory by default"
echo -e "  • Session files restored — SESSION_LOG.md and CONTINUATION_GUIDE.md back"
echo -e "  • Three-state model — Claude normal / Claude handoff / any other model"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. cd $PROJECT_DIR"
echo -e "  2. Customize .claude/rules/ for your language and framework"
echo -e "  3. Run /init to generate codebase-specific instructions"
echo -e "  4. Start Claude Code: claude"
echo ""
echo -e "${CYAN}When you need to switch AI models:${NC}"
echo -e "  Tell Claude Code: ${YELLOW}\"commit for model handoff\"${NC} or run ${YELLOW}/handoff${NC}"
echo ""
