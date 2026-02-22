#!/usr/bin/env bash
set -euo pipefail

COMMIT_MESSAGE="${1:-apply amazon links}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV_PATH="$ROOT_DIR/data/amazon_links.csv"
SITE_HTML_PATH="$ROOT_DIR/site/index.html"
PUBLIC_HTML_PATH="$ROOT_DIR/index.html"
APPLY_SCRIPT="$ROOT_DIR/scripts/apply_amazon_links.sh"
VALIDATE_AMAZON_SCRIPT="$ROOT_DIR/scripts/validate_amazon_links.py"
VALIDATE_RAKUTEN_SCRIPT="$ROOT_DIR/scripts/validate_links.py"

bash "$APPLY_SCRIPT" "$CSV_PATH" "$SITE_HTML_PATH"
cp "$SITE_HTML_PATH" "$PUBLIC_HTML_PATH"

python3 "$VALIDATE_AMAZON_SCRIPT" "$CSV_PATH" "$SITE_HTML_PATH"
python3 "$VALIDATE_AMAZON_SCRIPT" "$CSV_PATH" "$PUBLIC_HTML_PATH"
python3 "$VALIDATE_RAKUTEN_SCRIPT" "$ROOT_DIR/data/rakuten_links.csv" "$SITE_HTML_PATH"
python3 "$VALIDATE_RAKUTEN_SCRIPT" "$ROOT_DIR/data/rakuten_links.csv" "$PUBLIC_HTML_PATH"

git -C "$ROOT_DIR" add \
  "$CSV_PATH" \
  "$SITE_HTML_PATH" \
  "$PUBLIC_HTML_PATH" \
  "$APPLY_SCRIPT" \
  "$VALIDATE_AMAZON_SCRIPT" \
  "$ROOT_DIR/scripts/publish_amazon.sh"

if git -C "$ROOT_DIR" diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git -C "$ROOT_DIR" commit -m "$COMMIT_MESSAGE"
git -C "$ROOT_DIR" push origin main
