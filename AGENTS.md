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

Product screenshots are captured with the **Playwright MCP server** running its **own browser** — this gives clean, lossless, retina images with **no automation border, no browser chrome, and no cursor**. (Don't use the `claude-in-chrome` MCP for final shots: it returns lossy JPEG, and screen-capture fallbacks add Chrome's orange "Claude is using the browser" border.)

**Standard:** **1400×1050 viewport (4:3) at `deviceScaleFactor: 2` → a 2800×2100 PNG.** 4:3 gives comfortable vertical headroom; 2× is true retina.

- Always use the **test/demo account `johannes@kepler.ai`** (our shared Kepler test user) — never a personal account, since public docs must not show real user data. Login persists in the Playwright profile.
- **Sidebar:** collapse the app sidebar when it's a distracting chat list that adds nothing to the shot; keep it open when it shows relevant content (e.g. sources). Playwright renders no cursor, so nothing to move out of frame.
- Store final images under `images/` as **`.png`** (committed) and embed them with Mintlify `<Frame>` blocks. `screenshots/` is the git-ignored staging area (also the Playwright `--output-dir`).

### Playwright MCP setup

Registered in local config (`~/.claude.json`, this project) — **own browser, not `--extension`** (extension mode blocks CDP emulation, so it can't force retina, and `setViewportSize` there pins DPR to 1):

```bash
claude mcp add playwright -- npx @playwright/mcp@latest \
  --config /Users/sara/mintlify-docs/.claude/playwright-config.json \
  --user-data-dir /Users/sara/.cache/playwright-kepler-profile \
  --output-dir /Users/sara/mintlify-docs/screenshots
```

`.claude/playwright-config.json` sets the viewport + DPR:

```json
{ "browser": { "contextOptions": { "viewport": { "width": 1400, "height": 1050 }, "deviceScaleFactor": 2 } } }
```

### Capturing

The MCP `browser_take_screenshot` hardcodes `scale: 'css'` (1×), so use **`browser_run_code_unsafe`** to capture at device scale:

```js
async (page) => {
  await page.screenshot({ path: '/Users/sara/mintlify-docs/screenshots/<name>@2x.png', scale: 'device', type: 'png' });
}
```

Notes: the spreadsheet grid is **canvas-based** — select a cell via the name box (`page.mouse.click` the box, type e.g. `B11`, Enter) rather than clicking the canvas. Collapse the right chat panel via the `Collapse chat panel` button for citation/provenance shots. Read the PNG back to verify, then `cp` it into `images/<name>.png`.

A legacy `save-screenshot` skill (`.claude/skills/save-screenshot/`) exists for extracting `claude-in-chrome` JPEGs from the transcript — superseded by Playwright, kept only as a fallback.
