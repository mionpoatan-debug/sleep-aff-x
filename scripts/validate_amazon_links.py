#!/usr/bin/env python3
from __future__ import annotations

import csv
import sys
from html.parser import HTMLParser
from pathlib import Path


TRACKING_ID = "sleepcomparej-22"
DEFAULT_CSV_PATH = Path("data/amazon_links.csv")
DEFAULT_HTML_PATH = Path("site/index.html")


class AmazonLinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: dict[str, list[str]] = {}

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "a":
            return

        attr_map = {name: (value or "") for name, value in attrs}
        key = attr_map.get("data-amazon-key", "").strip()
        if not key:
            return

        href = attr_map.get("href", "")
        self.links.setdefault(key, []).append(href)


def load_csv_mapping(csv_path: Path) -> tuple[dict[str, str], list[str]]:
    errors: list[str] = []
    mapping: dict[str, str] = {}

    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        expected_columns = {"key", "amazon_url"}
        if not reader.fieldnames:
            errors.append(f"{csv_path}: CSV header is missing")
            return mapping, errors

        fieldnames = {name.strip() for name in reader.fieldnames}
        if fieldnames != expected_columns:
            errors.append(
                f"{csv_path}: CSV header must be key,amazon_url (got: {','.join(reader.fieldnames)})"
            )
            return mapping, errors

        for row in reader:
            key = (row.get("key") or "").strip()
            url = (row.get("amazon_url") or "").strip()
            if not key:
                continue
            if key in mapping:
                errors.append(f"{csv_path}: duplicated key '{key}'")
                continue
            mapping[key] = url

    return mapping, errors


def parse_html_links(html_path: Path) -> dict[str, list[str]]:
    parser = AmazonLinkParser()
    parser.feed(html_path.read_text(encoding="utf-8"))
    parser.close()
    return parser.links


def validate(csv_path: Path, html_path: Path) -> list[str]:
    errors: list[str] = []

    if not csv_path.is_file():
        return [f"CSV not found: {csv_path}"]
    if not html_path.is_file():
        return [f"HTML not found: {html_path}"]

    mapping, csv_errors = load_csv_mapping(csv_path)
    errors.extend(csv_errors)
    if errors:
        return errors

    links = parse_html_links(html_path)
    csv_keys = set(mapping.keys())
    html_keys = set(links.keys())

    missing_keys = sorted(csv_keys - html_keys)
    extra_keys = sorted(html_keys - csv_keys)

    for key in missing_keys:
        errors.append(f"{html_path}: missing anchor for key '{key}'")
    for key in extra_keys:
        errors.append(f"{html_path}: key '{key}' exists in HTML but not in CSV")

    for key in sorted(csv_keys):
        hrefs = links.get(key, [])
        if not hrefs:
            continue

        if len(hrefs) != 1:
            errors.append(f"{html_path}: key '{key}' must appear once (found {len(hrefs)})")
            continue

        href = hrefs[0]
        if ".https://" in href:
            errors.append(f"{html_path}: key '{key}' has broken href containing '.https://': {href}")

        csv_url = mapping[key]
        if csv_url:
            if not href.startswith("https://"):
                errors.append(f"{html_path}: key '{key}' href must start with https:// : {href}")

            if href != csv_url:
                errors.append(
                    f"{html_path}: key '{key}' href does not match CSV value\n"
                    f"  html: {href}\n"
                    f"  csv : {csv_url}"
                )

            if TRACKING_ID not in href:
                errors.append(
                    f"{html_path}: key '{key}' has non-empty CSV URL but missing tracking id '{TRACKING_ID}'"
                )

    return errors


def main() -> int:
    csv_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_CSV_PATH
    html_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_HTML_PATH

    errors = validate(csv_path, html_path)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"Validation passed: {html_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
