#!/usr/bin/env bash
# ==============================================================================
# Store your Meta Model API key in agentic-setup/.env.
#
#   ./set_meta_key.sh            prompts; input is hidden
#   ./set_meta_key.sh --stdin    reads the key from stdin (for the setup agent)
#
# The key is written only to agentic-setup/.env, which is outside this
# repository. It is never printed, logged, or committed.
# ==============================================================================
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

# Seed the env file from judges.env if this is the first run.
if [[ ! -f "$ENV_FILE" ]]; then
  mkdir -p "$(dirname "$ENV_FILE")"
  cp "${PLUGIN_DIR}/judges.env" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "Created ${ENV_FILE} from plugin/judges.env"
fi

if [[ "${1:-}" == "--stdin" ]]; then
  IFS= read -r KEY || true
else
  echo "Paste your Meta Model API key. Input is hidden."
  IFS= read -rs -p "META_API_KEY: " KEY; echo
fi
KEY="$(printf '%s' "$KEY" | tr -d '[:space:]')"

# Strip accidental surrounding quotes if present
KEY="${KEY#\"}"
KEY="${KEY%\"}"
KEY="${KEY#\'}"
KEY="${KEY%\'}"

if [[ -z "$KEY" ]]; then
  echo "No key entered. Nothing changed." >&2; exit 1
fi

# Replace the line in place, or append it. Python avoids sed escaping the |.
python3 - "$ENV_FILE" "$KEY" <<'PY'
import sys, pathlib
path, key = pathlib.Path(sys.argv[1]), sys.argv[2]
lines = path.read_text().splitlines()
out, done = [], False
for l in lines:
    if l.startswith("META_API_KEY="):
        out.append("META_API_KEY='" + key + "'"); done = True
    else:
        out.append(l)
if not done:
    out.append("META_API_KEY='" + key + "'")
path.write_text("\n".join(out) + "\n")
PY
chmod 600 "$ENV_FILE"
echo "META_API_KEY saved to ${ENV_FILE} (${#KEY} chars)."
echo "Next: ./check_muse.sh   — confirms the key works before you build."
