# ka-marketplace · install ka-sfskills on a teammate's Mac

A Claude Code marketplace bundling [`ka-sfskills`](https://github.com/bkkelley/ka-sfskills)
and [`claude-code-dashboard`](https://github.com/bkkelley/claude-code-dashboard),
plus a one-shot `install.sh` for non-developer teammates.

## For team members — quick start

> If you're setting this up on your own Mac for the first time.

1. Open **Terminal**: press `⌘+Space`, type `Terminal`, hit Enter.
2. Paste this and press Enter:

   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/bkkelley/ka-marketplace/main/install.sh)
   ```

3. Wait. The script tells you what it's doing at every step and asks
   before any of the bigger installs (Xcode tools, Homebrew). Total
   first-time install on a clean Mac: **15–25 minutes**, mostly
   downloads.

4. When it's done, follow the **Next steps** printed at the bottom —
   authenticate the Salesforce CLI, then open Claude Code and try a
   slash command.

If anything fails: take a screenshot of the last red `✘` line and
ping `#salesforce-ai-tools` on Slack.

## What gets installed

The script is *idempotent* — it only installs what's missing. On a
machine that already has some of these, it'll skip the ones that are
already there.

| Component | Why | How |
|---|---|---|
| Xcode Command Line Tools | Compiler + git, required by everything else | `xcode-select --install` (system dialog) |
| Homebrew | Package manager | Official install script |
| Python 3.13 | Runs the dashboard | `brew install python@3.13` if system Python is < 3.10 |
| Node.js | Runs `sf` (Salesforce CLI) | `brew install node` |
| Salesforce CLI (`sf`) | Talks to Salesforce orgs | `npm install -g @salesforce/cli` |
| Claude Code (`claude`) | The AI assistant CLI | Official Anthropic installer |
| Python deps (aiohttp et al) | Dashboard web server | `pip install --user` |
| ka-sfskills + claude-code-dashboard | The actual plugins | Via Claude Code's plugin system |

Nothing requires `sudo`. Nothing modifies system files outside what
brew and pip-user place into the user's home / Homebrew prefix.

## For me (Blake) — updating the marketplace

When ka-sfskills or claude-code-dashboard ships a new version, bump
the corresponding `version` field in `.claude-plugin/marketplace.json`
and push. Team members on the existing marketplace will see the
update on next `claude plugin update`.

```
git add .claude-plugin/marketplace.json
git commit -m "bump ka-sfskills to 0.3.0"
git push
```

The plugins are referenced by GitHub repo, so the marketplace itself
doesn't pin to a specific git SHA — `claude plugin install` resolves
to the latest tag on each repo.
