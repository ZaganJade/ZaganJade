#!/usr/bin/env bash
# Fetch a dynamic README SVG into assets/.
# Tries each URL in order with retries; keeps the previous version on total failure
# so the README never shows a broken image.
# Usage: fetch-asset.sh OUT URL1 [URL2 ...]
set -u
OUT="$1"; shift

is_valid_svg() {
  grep -q '<svg' "$1" 2>/dev/null &&
  ! grep -qi 'Something went wrong\|Failed to retrieve\|Error lable' "$1" 2>/dev/null
}

try_url() {
  local url="$1" i
  for i in 1 2 3 4 5; do
    if curl -sfL --max-time 30 "$url" -o "$OUT.part" && is_valid_svg "$OUT.part"; then
      mv "$OUT.part" "$OUT"
      return 0
    fi
    sleep $((i * 10))
  done
  return 1
}

for url in "$@"; do
  if try_url "$url"; then
    echo "OK        $OUT <- $url"
    exit 0
  fi
done

rm -f "$OUT.part"
if [ -f "$OUT" ]; then
  echo "KEEP-OLD  $OUT (all sources failed, previous version kept)"
else
  echo "MISS      $OUT (no cached version yet!)"
fi
