#!/usr/bin/env bash
set -euo pipefail

CSV_PATH="${1:-data/rakuten_links.csv}"
HTML_PATH="${2:-site/index.html}"

if [[ ! -f "$CSV_PATH" ]]; then
  echo "CSV not found: $CSV_PATH" >&2
  exit 1
fi

if [[ ! -f "$HTML_PATH" ]]; then
  echo "HTML not found: $HTML_PATH" >&2
  exit 1
fi

updated=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line//$'\r'/}"

  if [[ -z "$line" ]]; then
    continue
  fi

  key="${line%%,*}"
  rakuten_url="${line#*,}"

  if [[ "$key" == "key" ]] || [[ -z "$key" ]]; then
    continue
  fi

  # URLが空欄なら現状維持。
  if [[ -z "$rakuten_url" ]]; then
    continue
  fi

  KEY="$key" URL="$rakuten_url" perl -0777 -i -pe '
    my $k = $ENV{"KEY"};
    my $u = $ENV{"URL"};
    s{(<a\s+data-rakuten-key="\Q$k\E"[^>]*\shref=")[^"]*(")}{$1.$u.$2}g;
  ' "$HTML_PATH"

  updated=$((updated + 1))
done < "$CSV_PATH"

echo "Updated $updated Rakuten link(s) in $HTML_PATH"
