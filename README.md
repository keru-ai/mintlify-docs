# Kepler documentation

Public documentation for **Kepler**, an AI financial research agent. Built with [Mintlify](https://mintlify.com).

## Structure

- `docs.json` — site config (branding, navigation, colors)
- `index.mdx`, `quickstart.mdx` — getting-started pages
- `mcp/` — the **MCP connector** docs (overview, client setup, tools, prompts, examples)
- `logo/`, `favicon.svg` — Kepler brand assets (sourced from `forge/packages/kepler-app/public/` in the monorepo)

The connector docs are source-backed by the implementation in the monorepo at
`crud-service/crates/server/src/api/mcp/`. When the connector's tools, parameters, or URL change there, update `mcp/` to match.

## Develop

Install the [Mintlify CLI](https://www.npmjs.com/package/mint) and preview locally:

```bash
npm i -g mint
mint dev
```

View the preview at `http://localhost:3000`. Run `mint update` if the dev server misbehaves.

## Publishing

Changes deploy automatically to production after merging to the default branch, via the Mintlify GitHub app.

## Resources

- [Mintlify documentation](https://mintlify.com/docs)
- Kepler app: [app.kepler.ai](https://app.kepler.ai)
