#!/usr/bin/env bash
# Smoke-test the Meta Model API key and endpoint for both models.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"
: "${META_API_KEY:?META_API_KEY not set — run ./set_meta_key.sh}"
BASE="${MUSE_WONDER_API_URL:-https://api.meta.ai/v1}"
for MODEL in muse-wonder-1.0 muse-spark-1.3; do
  CODE=$(curl -sS -o /tmp/muse_check.json -w '%{http_code}' --max-time 60 \
    -X POST "$BASE/chat/completions" \
    -H "Authorization: Bearer $META_API_KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"$MODEL\",\"reasoning_effort\":\"low\",
         \"messages\":[{\"role\":\"developer\",\"content\":\"Answer in one word.\"},
                       {\"role\":\"user\",\"content\":\"Reply with OK\"}]}")
  if [[ "$CODE" != "200" ]]; then
    echo "FAIL $MODEL — http $CODE"; head -c 300 /tmp/muse_check.json; echo; exit 1
  fi
  echo "OK   $MODEL  $(python3 -c 'import json;d=json.load(open("/tmp/muse_check.json"));print(d["choices"][0]["message"]["content"].strip(),"|",d["usage"]["completion_tokens"],"out tokens")')"
done
