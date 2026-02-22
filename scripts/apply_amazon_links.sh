#!/usr/bin/env bash
set -euo pipefail

CSV_PATH="${1:-data/amazon_links.csv}"
HTML_PATH="${2:-site/index.html}"

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
  amazon_url="${line#*,}"

  key="${key%\"}"
  key="${key#\"}"
  amazon_url="${amazon_url%\"}"
  amazon_url="${amazon_url#\"}"

  key="$(trim_whitespace "$key")"
  amazon_url="$(trim_whitespace "$amazon_url")"

  if [[ "$key" == "key" ]] || [[ -z "$key" ]]; then
    continue
  fi

  match_count="$(rg -o "data-amazon-key=\"$key\"" "$HTML_PATH" | wc -l | tr -d ' ')"
  if [[ "$match_count" -ne 1 ]]; then
    echo "Expected exactly 1 anchor for key '$key' in $HTML_PATH, found $match_count" >&2
    exit 1
  fi

  # 空欄キーは置換しない。
  if [[ -z "$amazon_url" ]]; then
    continue
  fi

  KEY="$key" URL="$amazon_url" perl -0777 -i -pe '
    my $k = $ENV{"KEY"};
    my $u = $ENV{"URL"};
    s{(<a\b[^>]*\bdata-amazon-key="\Q$k\E"[^>]*\bhref=")[^"]*(")}{$1$u$2}g;
  ' "$HTML_PATH"

  updated=$((updated + 1))
done < "$CSV_PATH"

echo "Updated $updated Amazon link(s) in $HTML_PATH"
