#!/usr/bin/env bash
set -euo pipefail

CSV_PATH="${1:-data/rakuten_links.csv}"
HTML_PATH="${2:-site/index.html}"
DEFAULT_RAKUTEN_URL="https://www.rakuten.co.jp/"

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSV not found: $CSV_PATH" >&2
  exit 1
fi

if [[ ! -f "$HTML_PATH" ]]; then
  echo "HTML not found: $HTML_PATH" >&2
  exit 1
fi

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

updated=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line//$'\r'/}"

  if [[ -z "$line" ]]; then
    continue
  fi

  if [[ "$line" != *","* ]]; then
    echo "Invalid CSV row (missing comma): $line" >&2
    exit 1
  fi

  key="${line%%,*}"
  rakuten_url="${line#*,}"

  key="${key%\"}"
  key="${key#\"}"
  rakuten_url="${rakuten_url%\"}"
  rakuten_url="${rakuten_url#\"}"

  key="$(trim_whitespace "$key")"
  rakuten_url="$(trim_whitespace "$rakuten_url")"

  if [[ "$key" == "key" ]] || [[ -z "$key" ]]; then
    continue
  fi

  match_count="$(rg -o "data-rakuten-key=\"$key\"" "$HTML_PATH" | wc -l | tr -d ' ')"
  if [[ "$match_count" -ne 1 ]]; then
    echo "Expected exactly 1 anchor for key '$key' in $HTML_PATH, found $match_count" >&2
    exit 1
  fi

  # URLが空欄なら楽天トップURLを設定。
  if [[ -z "$rakuten_url" ]]; then
    rakuten_url="$DEFAULT_RAKUTEN_URL"
  fi

  KEY="$key" URL="$rakuten_url" perl -0777 -i -pe '
    my $k = $ENV{"KEY"};
    my $u = $ENV{"URL"};
    s{(<a\b[^>]*\bdata-rakuten-key="\Q$k\E"[^>]*\bhref=")[^"]*(")}{$1$u$2}g;
  ' "$HTML_PATH"

  updated=$((updated + 1))
done < "$CSV_PATH"

echo "Updated $updated Rakuten link(s) in $HTML_PATH"
