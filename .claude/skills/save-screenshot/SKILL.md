---
name: save-screenshot
description: >
  Persist a Claude-in-Chrome MCP screenshot to a real image file in the project. Use when
  you just took a screenshot with mcp__Claude_in_Chrome__computer and want the image saved to
  disk (e.g. for visual-regression docs, before/after comparisons, or issue evidence).
  Trigger phrases: "save the screenshot", "save that screenshot to …", "persist the screenshot",
  "/save-screenshot", or any variant asking to write a browser screenshot to a file.
version: 0.1.0
---

# save-screenshot

Save the most recent `mcp__Claude_in_Chrome__computer` screenshot from the current conversation
context to a real image file in the project.

## Why this exists

`mcp__Claude_in_Chrome__computer` returns screenshots as inline base64 — the bytes reach the
model's context window but no image file is written to disk (even with `save_to_disk: true` on
the CLI harness). The harness renders the image visually but does not expose the raw base64 as
copyable text. The bytes ARE persisted in the session's JSONL transcript. This skill locates
that transcript, extracts the base64 from it, and decodes it to a real image file.

## Invocation

```
/save-screenshot [<output-path>]
/save-screenshot [--session <uuid>] [--index <n|last>] [--out <output-path>]
```

- `output-path` — destination relative to the project root. Defaults to
  `screenshots/screenshot-<YYYYMMDD_HHMMSS>.jpg` when omitted.
- `--session` — extract from a stored past transcript instead of current context.
- `--index` — which image block to use (0-based; `last` = most recent). Default: `last`.

Examples:
```
/save-screenshot
/save-screenshot img/before.jpg
/save-screenshot --session 9b7db7d7-ec38-4e55-981b-5bf5d72501b8 --index 2 --out img/old.jpg
```

## How screenshots are stored

The harness renders the screenshot as a visible image in my context but does NOT make the raw
base64 string available as copyable text — so the model cannot write it directly to a file. The
bytes ARE persisted in the session transcript JSONL
(`~/.claude/projects/<slug>/<session-id>.jsonl`). The extraction path is therefore always:
grep the project's transcript directory for the screenshot ID, then decode via the script.

## Steps you MUST follow exactly

### Normal path (current-session screenshot)

1. **Find the screenshot ID.** Read it from the most recent `mcp__Claude_in_Chrome__computer`
   tool result in context — it looks like `ID: ss_xxxxxxxxx`.

2. **Find the right transcript.** Run:
   ```bash
   GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
   PROJ_DIR="$HOME/.claude/projects/$(echo "$GIT_ROOT" | tr '/' '-')"
   grep -rl "<screenshot-id>" "$PROJ_DIR/"
   ```
   Take the first match. Extract the UUID filename (without `.jsonl`) — that is `<session-id>`.

3. **Determine the output path.** Use the path from args. If none given, default to
   `screenshots/screenshot-<YYYYMMDD_HHMMSS>.<ext>` where `<ext>` matches the media type
   (`jpeg` → `.jpg`, `png` → `.png`, `webp` → `.webp`).
   Do NOT invent the timestamp — run `date +%Y%m%d_%H%M%S` first.

4. **Decode and save.** Run:
   ```bash
   bash .claude/skills/save-screenshot/scripts/save-screenshot.sh \
     --session <session-id> \
     --index last \
     --out <output-path>
   ```

5. **Verify.** Read the saved file back with the Read tool to confirm it renders correctly.

6. **Confirm.** Report the final path to the user.

### Recovering a past screenshot (explicit --session)

Use when the user names a specific past session or screenshot index.

1. **Determine timestamp** for default naming if no `--out` given: `date +%Y%m%d_%H%M%S`

2. **Run the script** directly:
   ```bash
   bash .claude/skills/save-screenshot/scripts/save-screenshot.sh \
     --session <uuid> \
     --index <n|last> \
     --out <output-path>
   ```

3. **Verify and confirm** the saved path.

## Error handling

| Problem | Action |
|---|---|
| No screenshot in context | Tell the user; suggest taking one first with `mcp__Claude_in_Chrome__computer` |
| Multiple screenshots in context | Use the most recent (last) one; tell the user which it was |
| `base64 -d` fails (corrupt data) | Show the error; the base64 may have been truncated — user should retake the screenshot |
| Output path parent doesn't exist | The script creates it; if mkdir fails (permissions), tell the user |
| `--session` not found | The script lists available sessions; relay that list |

## Notes

- Each screenshot is stored **twice** in the JSONL transcript (one in the request, one in the
  response). The `--session` script dedupes by MD5 of the base64, so `--index 0` is image #1,
  not the duplicate. The "from context" mode reads directly from what you see, so no dedup needed.
- The base64 is already lossy (MCP captures as JPEG for full screenshots, PNG for zoom/element
  crops). Do not apply further compression.
- This skill does **not** crop, resize, or stitch images. For side-by-side v14|v15 composites,
  use Pillow after this skill saves both source images.
