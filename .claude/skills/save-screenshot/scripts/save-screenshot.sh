#!/usr/bin/env bash
# Decode a base64 screenshot (written to a temp file by the agent) into an image.
#
# Usage:
#   save-screenshot.sh --b64-file <path> --out <output-path>
#   save-screenshot.sh --session <session-id> [--index <n|last>] --out <output-path>
#
# The --b64-file form is the primary path: the agent writes the raw base64 string
# (no header, no data: URI) to a temp file and points this script at it.
#
# The --session form extracts from a stored Claude Code transcript JSONL
# (useful for recovering past screenshots without re-running them).
#
# Options:
#   --b64-file FILE   path to a file containing raw base64 text
#   --session ID      session UUID to extract from (looks in ~/.claude/projects/<slug>/)
#   --index N|last    which image block to extract when using --session (default: last)
#   --out FILE        destination image path (created incl. parent dirs)
#   --project-slug S  override the project dir slug (default: auto-detected from git)

set -euo pipefail

B64_FILE=""
SESSION=""
INDEX="last"
OUTPUT=""
PROJECT_SLUG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --b64-file)    B64_FILE="$2";    shift 2 ;;
    --session)     SESSION="$2";     shift 2 ;;
    --index)       INDEX="$2";       shift 2 ;;
    --out|-o)      OUTPUT="$2";      shift 2 ;;
    --project-slug) PROJECT_SLUG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$OUTPUT" ]]; then
  echo "Error: --out <path> is required" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

# ── mode 1: decode from a pre-written base64 file ────────────────────────────
if [[ -n "$B64_FILE" ]]; then
  if [[ ! -f "$B64_FILE" ]]; then
    echo "Error: --b64-file '$B64_FILE' not found" >&2
    exit 1
  fi
  # Strip any whitespace/newlines that might have crept in
  tr -d '[:space:]' < "$B64_FILE" | base64 -d > "$OUTPUT"
  echo "Saved: $OUTPUT"
  file "$OUTPUT"
  exit 0
fi

# ── mode 2: extract from session transcript ───────────────────────────────────
if [[ -n "$SESSION" ]]; then
  if [[ -z "$PROJECT_SLUG" ]]; then
    # Derive slug from git root: replace / with - and strip leading -
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
    PROJECT_SLUG=$(echo "$GIT_ROOT" | tr '/' '-')
  fi
  PROJ_DIR="$HOME/.claude/projects/$PROJECT_SLUG"
  TRANSCRIPT="$PROJ_DIR/${SESSION}.jsonl"
  if [[ ! -f "$TRANSCRIPT" ]]; then
    echo "Error: transcript not found: $TRANSCRIPT" >&2
    echo "Available sessions:" >&2
    ls "$PROJ_DIR"/*.jsonl 2>/dev/null | xargs -n1 basename | sed 's/\.jsonl$//' >&2
    exit 1
  fi

  python3 - "$TRANSCRIPT" "$INDEX" "$OUTPUT" <<'PY'
import sys, json, base64, os

transcript, index_arg, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
ext_map = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}

found = []

def walk(node):
    if isinstance(node, dict):
        if node.get("type") == "image":
            src = node.get("source") or {}
            data = src.get("data") or node.get("data")
            mt = src.get("media_type") or node.get("mimeType") or "image/jpeg"
            if isinstance(data, str) and len(data) > 100:
                found.append((mt, data))
        for v in node.values():
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)

with open(transcript) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            walk(json.loads(line))
        except Exception:
            pass

# Dedupe by content hash
import hashlib
seen, unique = set(), []
for mt, data in found:
    h = hashlib.md5(data.encode()).hexdigest()
    if h not in seen:
        seen.add(h)
        unique.append((mt, data))

if not unique:
    print("Error: no image blocks found in transcript", file=sys.stderr)
    sys.exit(1)

idx = -1 if index_arg == "last" else int(index_arg)
try:
    mt, data = unique[idx]
except IndexError:
    print(f"Error: index {index_arg} out of range (0–{len(unique)-1})", file=sys.stderr)
    sys.exit(1)

raw = base64.b64decode(data)

# Adjust extension to match actual media type
root, _ = os.path.splitext(out_path)
ext = ext_map.get(mt, "jpg")
final_path = f"{root}.{ext}" if not out_path.endswith(f".{ext}") else out_path
os.makedirs(os.path.dirname(final_path) or ".", exist_ok=True)

with open(final_path, "wb") as fh:
    fh.write(raw)

print(f"Saved: {final_path}  ({mt}, {len(raw):,} bytes, image #{idx} of {len(unique)} unique)")
PY
  exit 0
fi

echo "Error: provide either --b64-file or --session" >&2
exit 1
