#!/usr/bin/env bash
set -euo pipefail

COMMIT_MESSAGE="${1:-update rakuten links}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV_PATH="$ROOT_DIR/data/rakuten_links.csv"
SITE_HTML_PATH="$ROOT_DIR/site/index.html"
PUBLIC_HTML_PATH="$ROOT_DIR/index.html"

bash "$ROOT_DIR/scripts/apply_rakuten_links.sh" "$CSV_PATH" "$SITE_HTML_PATH"
cp "$SITE_HTML_PATH" "$PUBLIC_HTML_PATH"

python3 "$ROOT_DIR/scripts/validate_links.py" "$CSV_PATH" "$SITE_HTML_PATH"
python3 "$ROOT_DIR/scripts/validate_links.py" "$CSV_PATH" "$PUBLIC_HTML_PATH"

git -C "$ROOT_DIR" add "$CSV_PATH" "$SITE_HTML_PATH" "$PUBLIC_HTML_PATH"
if git -C "$ROOT_DIR" diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git -C "$ROOT_DIR" commit -m "$COMMIT_MESSAGE"
git -C "$ROOT_DIR" push origin main
