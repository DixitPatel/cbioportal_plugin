#!/usr/bin/env bash
# AlphaGenome scoring sidecar — FastAPI on :8000
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
PORT="${1:-8000}"
cd "${WORKSPACE}/alphagenome-sidecar"
exec "${VENV}/bin/uvicorn" app.main:app --host 0.0.0.0 --port "$PORT"
