#!/usr/bin/env bash
# =============================================================================
# jsbt0 monthly dependency update — local trigger script
#
# Called by launchd (see com.mobycode.jsbt0.monthly-update.plist) or manually.
# The heavy lifting is done by Claude Code; this script just sets the stage.
#
# First-time setup:
#   1. Put your Anthropic API key in ~/.config/jsbt0/env:
#        echo 'ANTHROPIC_API_KEY=sk-ant-...' > ~/.config/jsbt0/env
#        chmod 600 ~/.config/jsbt0/env
#   2. Ensure claude CLI is installed: npm install -g @anthropic-ai/claude-code
#   3. Ensure GraalVM 25 is installed at GRAALVM_HOME below (or override via env)
#   4. Ensure git remote is configured with SSH push access (no password prompt)
#
# Manual run:
#   bash scripts/monthly-update.sh
# =============================================================================
set -euo pipefail

# ---- Paths ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_FILE="$SCRIPT_DIR/update-prompt.md"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/update-$(date +%Y-%m).log"

# ---- GraalVM 25 location (macOS default) ------------------------------------
GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-25.jdk/Contents/Home"

# ---- Load API key from secure file if not already in environment ------------
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  ENV_FILE="$HOME/.config/jsbt0/env"
  if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
  fi
fi

# ---- Validate prerequisites -------------------------------------------------
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ERROR: ANTHROPIC_API_KEY is not set." >&2
  echo "       Create ~/.config/jsbt0/env with: ANTHROPIC_API_KEY=sk-ant-..." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "ERROR: claude CLI not found. Run: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi

if ! command -v mvn &>/dev/null; then
  echo "ERROR: mvn not found. Install Maven and ensure it's on PATH." >&2
  exit 1
fi

# ---- Set JAVA_HOME to GraalVM 25 if not already pointing at Java 25+ --------
CURRENT_JAVA_MAJOR="$("${JAVA_HOME:-/usr}/bin/java" -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1 || echo 0)"
if [ "$CURRENT_JAVA_MAJOR" -lt 25 ]; then
  if [ -d "$GRAALVM_HOME" ]; then
    export JAVA_HOME="$GRAALVM_HOME"
  else
    echo "ERROR: GraalVM 25 not found at $GRAALVM_HOME" >&2
    echo "       Install with: brew install --cask graalvm-jdk@25" >&2
    exit 1
  fi
fi
export PATH="$JAVA_HOME/bin:$PATH"

# ---- Ensure log directory exists --------------------------------------------
mkdir -p "$LOG_DIR"

# ---- Guard: abort if a run already occurred in the past 7 days --------------
cd "$PROJECT_DIR"
CHANGELOG="$PROJECT_DIR/CHANGELOG.md"

if [ -f "$CHANGELOG" ]; then
  LAST_DATE=$(grep -m1 "^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]" "$CHANGELOG" \
    | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" || true)

  if [ -n "$LAST_DATE" ]; then
    # macOS (BSD date) vs Linux (GNU date)
    if [[ "$(uname)" == "Darwin" ]]; then
      LAST_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_DATE" +%s 2>/dev/null || echo 0)
      SEVEN_AGO=$(date -j -v-7d +%s)
    else
      LAST_EPOCH=$(date -d "$LAST_DATE" +%s 2>/dev/null || echo 0)
      SEVEN_AGO=$(date -d "7 days ago" +%s)
    fi

    if [ "$LAST_EPOCH" -gt "$SEVEN_AGO" ]; then
      MSG="Aborting: last run was $LAST_DATE (within 7 days). No update needed."
      echo "[$(date)] $MSG" | tee -a "$LOG_FILE"
      exit 0
    fi
  fi
fi

# ---- Run --------------------------------------------------------------------

{
  echo "========================================================================"
  echo "jsbt0 monthly update started at $(date)"
  echo "JAVA_HOME: $JAVA_HOME"
  echo "Java version: $(java -version 2>&1 | head -1)"
  echo "Claude version: $(claude --version 2>&1 | head -1)"
  echo "========================================================================"
} | tee -a "$LOG_FILE"

claude -p "$(cat "$PROMPT_FILE")" \
  --dangerously-skip-permissions \
  --max-turns 80 \
  --model claude-opus-4-6 \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

{
  echo "========================================================================"
  echo "jsbt0 monthly update finished at $(date) — exit code: $EXIT_CODE"
  echo "========================================================================"
} | tee -a "$LOG_FILE"

exit $EXIT_CODE
