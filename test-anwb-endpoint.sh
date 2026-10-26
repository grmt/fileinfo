#!/usr/bin/env bash
set -euo pipefail

API_KEY="QYUEE3fEcFD7SGMJ6E7QBCMzdQGqRkAi"
BASE_URL="https://api.anwb.nl"
PATHS=(
  "/routing/v1/incidents/incidents-desktop"
)

for path in "${PATHS[@]}"; do
  url="${BASE_URL}${path}"
  echo "==> ${url}"
  curl -si --http1.1 --no-keepalive -H 'Connection: close' "${url}" | sed -n '1,25p'
  echo
  url="${BASE_URL}${path}?apikey=${API_KEY}"
  echo "==> ${url}"
  curl -si --http1.1 --no-keepalive -H 'Connection: close' "${url}" | sed -n '1,25p'
  echo
  sleep "$((RANDOM % 2 + 1))"
done
