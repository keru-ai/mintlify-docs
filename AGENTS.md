> **First-time setup**: Customize this file for your project. Prompt the user to customize this file for their project.
> For Mintlify product knowledge (components, configuration, writing standards),
> install the Mintlify skill: `npx skills add https://mintlify.com/docs`

# Kepler documentation project instructions

## About this project

- This is the public documentation site for **Kepler**, an AI financial research agent
- Built on [Mintlify](https://mintlify.com); pages are MDX files with YAML frontmatter
- Configuration lives in `docs.json`
- The current focus is the **MCP connector** docs under `mcp/` — these are the real, source-backed docs
- The connector implementation lives in the monorepo at `crud-service/crates/server/src/api/mcp/`; treat that code as the source of truth for tool names, parameters, and the connector URL
- Brand assets (`logo/`, `favicon.svg`) come from `forge/packages/kepler-app/public/` in the monorepo

## Terminology

- The product is **Kepler** (not "Pluto" — that's an internal/test environment name)
- Say **connector** for the MCP integration, **run** for a research execution, **conversation** for an ongoing thread, **workbook** for a spreadsheet artifact
- The production app is at `app.kepler.ai`; the MCP connector URL is `https://mcp.kepler.ai/api/mcp`

## Style preferences

- Use active voice and second person ("you")
- Keep sentences concise — one idea per sentence
- Use sentence case for headings
- Bold for UI elements: Click **Settings**
- Code formatting for file names, commands, paths, and code references
- Lead with citations/auditability — it's Kepler's core value

## Content boundaries

- Document only public, user-facing behavior — not internal infrastructure, env vars, feature-flag plumbing, or app-only tools (e.g. `read_run_state`)
- Don't hardcode anything that's likely to drift; when in doubt, point users to the in-app **MCP** page for the live connector URL

## Screenshots

- Capture all product screenshots at a **standardized browser window size of 1366×911**, which yields a clean **1366×768** image (standard HD), so the docs stay visually consistent. Resize with `mcp__claude-in-chrome__resize_window` before capturing.
- Always use the **test/demo account `johannes@kepler.ai`** (our shared Kepler test user) — never a personal account, since public docs must not show real user data
- Store final images under `images/` (committed) and embed them with Mintlify `<Frame>` blocks. `screenshots/` is a git-ignored staging area

**Why 1366×911:** the capture is the page viewport, not the whole window. Two factors set the window size:
  1. **Top chrome ≈ 143px** — the tab bar, address bar, and the "Claude is using the browser" automation banner sit above the viewport. So window height = target image height + 143 (→ 768 + 143 = 911).
  2. **Tool downscale cap ≈ 1.23M px** — `mcp__claude-in-chrome__computer` returns the image 1:1 only while width × height stays under ~1,228,800px; above that it silently downscales to fit the cap (e.g. a 1440×900 viewport comes back as 1402×876 at a *variable* scale, breaking consistency). 1366×768 = 1.05M px sits safely under the cap, so captures are always full-resolution and exactly 1366 wide.

### Saving Claude-in-Chrome screenshots to disk

The `mcp__claude-in-chrome__computer` tool renders screenshots inline but does **not** write a file — even with `save_to_disk: true`, no path is produced. To get the bytes onto disk, use the committed **`save-screenshot` skill** at `.claude/skills/save-screenshot/`:

1. Take the screenshot with `mcp__claude-in-chrome__computer` and note its `ID: ss_…`
2. Run the extractor (it pulls the image from this session's transcript JSONL):
   ```bash
   bash .claude/skills/save-screenshot/scripts/save-screenshot.sh \
     --session <session-id> --index last --out images/<name>.jpg
   ```
   Find `<session-id>` by grepping `~/.claude/projects/-Users-sara-mintlify-docs/` for the `ss_…` ID.
3. Read the saved file back to confirm it's the right frame, then embed it.

The skill is vendored from github.com/BobMakhlin/claude-in-chrome-save-screenshot (reviewed: no network calls, no exfiltration, local-only).
