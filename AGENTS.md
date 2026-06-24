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
