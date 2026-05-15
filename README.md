# ka-marketplace

A Claude Code marketplace bundling
[`ka-sfskills`](https://github.com/bkkelley/ka-sfskills) (Salesforce
agents, skills, commands, MCP server) and
[`claude-code-dashboard`](https://github.com/bkkelley/claude-code-dashboard)
(local web UI), plus a one-shot `install.sh` for non-developer
teammates on macOS.

---

## For team members — install on your Mac

### 1. Open Terminal

Press `⌘+Space`, type `Terminal`, hit Enter. A window pops up with a
text prompt. You'll paste one command into it.

### 2. Paste this and press Enter

```
bash <(curl -fsSL https://raw.githubusercontent.com/bkkelley/ka-marketplace/main/install.sh)
```

### 3. Follow the prompts

The script will tell you what it's doing at every step. The bigger
installs (Xcode tools, Homebrew) ask `[y/n]` before they run — type
`y` and Enter.

**First-time install on a clean Mac: 15–25 minutes**, mostly waiting
for downloads.

Total disk space added: ~2 GB (mostly Xcode CLI tools, Homebrew, Node).

### 4. When it finishes

The script prints a `Setup complete` banner with the next steps. The
short version:

```
sf org login web --alias myorg     # one-time, authenticate to Salesforce
claude                              # open Claude Code
/start-dashboard                    # opens the web UI in your browser
/build-apex                         # or try any other slash command
```

### If something goes wrong

The script stops on the first failure and prints a red `✘` line. Take
a screenshot of the last 20 lines of output and ping
`#salesforce-ai-tools` on Slack — that's all the info I need to help.

The most common things that break a clean install:

| Symptom | Fix |
|---|---|
| "xcode-select: command not found" | Run `xcode-select --install` first, click Install on the dialog, wait for it to finish, then re-run the script. |
| "Permission denied" trying to install Homebrew | You may not be an administrator on this Mac. Get IT to grant admin or run an elevated install. |
| Script hangs on "Installing Homebrew…" | Corporate proxy/VPN sometimes blocks brew. Disable VPN and retry, or contact IT for a brew-allowed network. |
| "claude: command not found" after the script finishes | Restart Terminal. Run `echo $PATH` and confirm `~/.local/bin` is in there. If not, add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc`. |
| `sf org login` opens a browser that never returns to Terminal | Either the org auth completed (try `sf org list` to confirm) or your default browser refused the redirect. Try `sf org login web --instance-url https://test.salesforce.com` for a sandbox. |

---

## What the installer touches

The script is **idempotent** (running it twice does nothing harmful)
and **non-destructive** (doesn't remove anything you have installed).
On a brand-new Mac it walks through:

| Step | What | Asks first? |
|---|---|---|
| 1 | Xcode Command Line Tools (system dialog) | Yes |
| 2 | Homebrew | No (after step 1 consent) |
| 3 | Python 3.13 — only if system Python < 3.10 | No |
| 4 | Node.js — only if missing | No |
| 5 | Salesforce CLI (`@salesforce/cli` via npm) | No |
| 6 | Claude Code (`claude` via the official installer) | No |
| 7 | Python deps: `aiohttp`, `aiohttp_jinja2`, `jinja2` (`pip install --user`) | No |
| 8 | Adds the `kelleyaustin` marketplace to Claude Code | No |
| 9 | Installs `ka-sfskills` (the dashboard plugin comes as a dependency) | No |

Nothing requires `sudo`. Nothing modifies anything outside Homebrew's
prefix and your home directory (`~/.claude/`, `~/.local/`).

---

## What you actually get

After the install:

```
~/.claude/plugins/cache/
├── kelleyaustin/
│   ├── ka-sfskills/0.2.0/
│   │   ├── agents/                 # 60+ Salesforce run-time agents
│   │   ├── skills/                 # 982 source-cited skill docs
│   │   ├── commands/               # /build-apex, /audit-router, etc.
│   │   └── mcp/sfskills-mcp/       # live-org MCP server
│   └── claude-code-dashboard/1.0.0/
│       ├── scripts/dashboard/      # the web UI
│       └── hooks/                  # subagent + slash lifecycle hooks
└── …
```

In Claude Code, type `/` and you'll see autocomplete for every
ka-sfskills slash command. `/start-dashboard` opens the local web UI
at `http://localhost:9000`.

State is at `~/.claude/dashboard/`:
- `events.jsonl` — live event stream
- `chat-sessions.json` — chat session history
- `projects.json` — chat panel's recent projects
- `dashboard.log` — server stderr

---

## For the maintainer (me) — updating the marketplace

When `ka-sfskills` or `claude-code-dashboard` cuts a new version:

1. Bump the corresponding `version` field in
   `.claude-plugin/marketplace.json`.
2. Commit and push.

```bash
git pull
$EDITOR .claude-plugin/marketplace.json
git commit -am "bump ka-sfskills to 0.3.0"
git push
```

Team members on the existing marketplace pick up the new version on
their next `claude plugin update`. The marketplace is pinned to
GitHub source, not a specific commit SHA, so the install fetches
whatever's on `main` for each repo at install time. To pin a specific
SHA, change the source entry shape:

```json
"source": {
  "source": "github",
  "repo": "bkkelley/ka-sfskills",
  "sha": "abc123..."
}
```

### Adding another plugin

To ship a third plugin through the same marketplace, append to the
`plugins` array in `marketplace.json`:

```json
{
  "name": "my-new-plugin",
  "version": "0.1.0",
  "description": "…",
  "source": { "source": "github", "repo": "bkkelley/my-new-plugin" }
}
```

The plugin's repo just needs a `.claude-plugin/plugin.json` (and a
`dashboard.json` if it wants to surface in the dashboard's
agents/skills pages).

---

## Related repos

- [`ka-sfskills`](https://github.com/bkkelley/ka-sfskills) — Salesforce
  agents, skills, commands, MCP server.
- [`claude-code-dashboard`](https://github.com/bkkelley/claude-code-dashboard) —
  the local web UI.

## License

MIT.
