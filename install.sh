#!/usr/bin/env bash
# Kelley Austin · one-shot installer for ka-sfskills + claude-code-dashboard.
#
# Designed to be safe to run on a fresh macOS install with no developer
# tooling. Detects what's missing, installs only that, and is idempotent
# (running it twice does nothing harmful).
#
# Usage (paste into Terminal):
#   bash <(curl -fsSL https://raw.githubusercontent.com/bkkelley/ka-marketplace/main/install.sh)
#
# Or after cloning the marketplace repo:
#   ./install.sh
#
# What this script does, in order:
#   1. Verifies macOS + Xcode CLI tools (offers to install if missing).
#   2. Installs Homebrew if missing.
#   3. Installs Python 3.13 via brew if missing.
#   4. Installs Node.js + Salesforce CLI via brew if missing.
#   5. Installs Claude Code (claude CLI) via the official installer.
#   6. Installs the Python deps the dashboard needs (aiohttp et al)
#      into the user's Python (no sudo).
#   7. Registers the kelleyaustin marketplace with Claude Code.
#   8. Installs ka-sfskills (claude-code-dashboard comes as a dep).
#   9. Prints next-step instructions.

set -euo pipefail

# ----- pretty-print helpers -----------------------------------------
BOLD="\033[1m"; DIM="\033[2m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
step()   { printf "\n${BOLD}▸ %s${RESET}\n" "$1"; }
ok()     { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
skip()   { printf "  ${DIM}✓${RESET} ${DIM}%s${RESET}\n" "$1"; }
warn()   { printf "  ${YELLOW}!${RESET} %s\n" "$1"; }
fail()   { printf "  ${RED}✘${RESET} %s\n" "$1"; exit 1; }
ask()    { local prompt="$1"; local default="${2:-y}"; printf "${BOLD}? %s${RESET} [%s] " "$prompt" "$default"; read -r reply; reply=${reply:-$default}; [[ "$reply" =~ ^[Yy] ]]; }

# ----- preflight ----------------------------------------------------
step "Preflight"

if [[ "$OSTYPE" != darwin* ]]; then
  fail "This installer only supports macOS. Detected: $OSTYPE"
fi
ok "macOS detected"

# Xcode CLI tools are required for git, compiler toolchain, brew.
if ! xcode-select -p >/dev/null 2>&1; then
  warn "Xcode Command Line Tools missing — these are needed for everything else."
  warn "Running 'xcode-select --install' will pop a system dialog. Click Install."
  if ! ask "Continue?"; then exit 1; fi
  xcode-select --install || true
  echo "  Wait for the installer to finish, then re-run this script."
  exit 0
fi
ok "Xcode Command Line Tools"

# ----- Homebrew -----------------------------------------------------
step "Homebrew"

if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew is not installed. Installing now."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple silicon installs into /opt/homebrew; Intel into /usr/local.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
ok "brew $(brew --version | head -1 | awk '{print $2}')"

# ----- Python 3.10+ -------------------------------------------------
step "Python"

# Use the system python3 if it's >= 3.10. Otherwise install via brew.
PYTHON_BIN="$(command -v python3 || true)"
PYTHON_OK=0
if [[ -n "$PYTHON_BIN" ]]; then
  PY_MINOR="$("$PYTHON_BIN" -c 'import sys; print(sys.version_info[1])' 2>/dev/null || echo 0)"
  PY_MAJOR="$("$PYTHON_BIN" -c 'import sys; print(sys.version_info[0])' 2>/dev/null || echo 0)"
  if [[ "$PY_MAJOR" == 3 && "$PY_MINOR" -ge 10 ]]; then
    PYTHON_OK=1
    skip "python3 $($PYTHON_BIN --version | awk '{print $2}') (system)"
  fi
fi
if [[ "$PYTHON_OK" == 0 ]]; then
  brew install python@3.13
  PYTHON_BIN="$(brew --prefix python@3.13)/bin/python3"
  ok "python3 $($PYTHON_BIN --version | awk '{print $2}') (brew)"
fi

# ----- Node + Salesforce CLI ---------------------------------------
step "Salesforce CLI"

if ! command -v node >/dev/null 2>&1; then
  brew install node
  ok "node $(node --version)"
else
  skip "node $(node --version)"
fi

if ! command -v sf >/dev/null 2>&1; then
  npm install -g @salesforce/cli
  ok "sf $(sf --version 2>&1 | head -1)"
else
  skip "sf $(sf --version 2>&1 | head -1)"
fi

# ----- Claude Code --------------------------------------------------
step "Claude Code"

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI not found. Installing via the official installer."
  curl -fsSL https://claude.ai/install.sh | bash
  # The installer typically drops claude into ~/.local/bin
  export PATH="$HOME/.local/bin:$PATH"
fi
if ! command -v claude >/dev/null 2>&1; then
  fail "Claude Code install ran but 'claude' is still not on PATH. Add ~/.local/bin to your shell PATH and re-run."
fi
ok "claude $(claude --version 2>&1 | head -1)"

# ----- Python deps for the dashboard --------------------------------
step "Dashboard Python deps"

"$PYTHON_BIN" -m pip install --quiet --upgrade --user aiohttp aiohttp_jinja2 jinja2
ok "aiohttp, aiohttp_jinja2, jinja2 installed for $($PYTHON_BIN -c 'import sys; print(sys.executable)')"

# ----- Claude Code marketplace + plugins ----------------------------
step "Plugins"

# Add the kelleyaustin marketplace. If it's already added, this is a
# no-op or a low-noise error — capture both.
if claude plugin marketplace list 2>/dev/null | grep -qi "kelleyaustin"; then
  skip "marketplace 'kelleyaustin' already added"
else
  # HTTPS form on purpose — the bare github.com/<owner>/<repo>
  # shorthand makes claude-code try git@github.com, which fails on a
  # fresh Mac (no SSH host key in ~/.ssh/known_hosts).
  claude plugin marketplace add https://github.com/bkkelley/ka-marketplace
  ok "added marketplace https://github.com/bkkelley/ka-marketplace"
fi

# Install the plugin. Dashboard is pulled as a dependency.
if claude plugin list 2>/dev/null | grep -qi "ka-sfskills"; then
  skip "ka-sfskills already installed"
else
  claude plugin install ka-sfskills@kelleyaustin
  ok "ka-sfskills installed (claude-code-dashboard came as a dep)"
fi

# ----- done ---------------------------------------------------------
step "All set"

cat <<EOF

  ${GREEN}${BOLD}Setup complete.${RESET}

  ${BOLD}Next steps${RESET}

  1. Authenticate the Salesforce CLI against your orgs (one-time):
       ${DIM}sf org login web --alias myorg${RESET}

  2. Open Claude Code in any project directory:
       ${DIM}claude${RESET}

  3. In Claude Code, type a slash command — try one of:
       ${DIM}/start-dashboard${RESET}  (opens the browser UI at localhost:9000)
       ${DIM}/build-apex${RESET}       (generate Apex)
       ${DIM}/audit-router${RESET}     (audit Lightning record pages, validation rules, etc.)

  ${BOLD}Where things live${RESET}
    plugins        ~/.claude/plugins/cache/
    state          ~/.claude/dashboard/
    logs           ~/.claude/dashboard/dashboard.log

  Questions / issues — ping #salesforce-ai-tools on Slack.

EOF
