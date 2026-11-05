#!/usr/bin/env bash
# Genome Nexus frontend — CRA dev server on :3088, pointed at the local backend
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
use_node
export PORT="${PORT:-3088}"
export REACT_APP_GENOME_NEXUS_URL="${REACT_APP_GENOME_NEXUS_URL:-http://localhost:38080}"
export BROWSER=none CI=true
export NODE_OPTIONS="${NODE_OPTIONS:---openssl-legacy-provider}"
cd "${WORKSPACE}/genome-nexus-frontend"
[[ -d node_modules ]] || yarn install --non-interactive
exec yarn run start
