#!/usr/bin/env bash
# ==============================================================================
# Start the whole stack in dependency order, gating on health before each step.
#   ./start_all.sh              start everything, then verify
#   ./start_all.sh --no-mongo   gn-mongo is already running elsewhere
#   ./start_all.sh --stop       stop what this script started
# Logs: workspace/logs/<service>.log
# ==============================================================================
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"
SVC="${PLUGIN_DIR}/services"

SKIP_MONGO=0
case "${1:-}" in
  --stop)
    for f in "$PID_DIR"/*.pid; do
      [[ -e "$f" ]] || continue
      pid=$(cat "$f"); name=$(basename "$f" .pid)
      kill -0 "$pid" 2>/dev/null && kill "$pid" && echo "stopped $name ($pid)"
      rm -f "$f"
    done
    echo "gn-mongo left running: docker stop gn-mongo"
    exit 0 ;;
  --no-mongo) SKIP_MONGO=1 ;;
  -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
esac

# is_alive NAME: the process this script started for NAME (or, for gn-mongo,
# the container) still runs.
is_alive() {
  if [[ "$1" == gn-mongo ]]; then
    [[ "$(docker inspect -f '{{.State.Running}}' gn-mongo 2>/dev/null)" == true ]]
    return
  fi
  local pid
  pid="$(cat "$PID_DIR/$1.pid" 2>/dev/null)" || return 1
  kill -0 "$pid" 2>/dev/null
}

# wait_for NAME LABEL LIMIT CMD...: poll CMD every 2 s until it succeeds.
# Stops at once, with the last errors, if NAME is no longer running.
wait_for() {
  local name="$1" label="$2" limit="$3"; shift 3
  local n=0
  printf '  waiting for %s ' "$label"
  while (( n < limit )); do
    "$@" >/dev/null 2>&1 && { printf ' up (%ds)\n' "$n"; return 0; }
    if ! is_alive "$name"; then
      printf ' EXITED (%ds)\n' "$n"
      if [[ "$name" == gn-mongo ]]; then
        docker logs --tail 5 gn-mongo 2>&1 | cut -c1-240 | sed 's/^/    /'
      else
        { grep -E 'ERROR|Caused by|Error:' "$LOG_DIR/$name.log" 2>/dev/null \
            || tail -n 3 "$LOG_DIR/$name.log" 2>/dev/null; } \
          | tail -n 3 | cut -c1-240 | sed 's/^/    /'
        rm -f "$PID_DIR/$name.pid"
      fi
      return 1
    fi
    printf '.'; sleep 2; n=$((n+2))
  done
  printf ' TIMEOUT (%ds)\n' "$limit"; return 1
}

start_bg() {
  local name="$1"; shift
  if [[ -f "$PID_DIR/$name.pid" ]] && kill -0 "$(cat "$PID_DIR/$name.pid")" 2>/dev/null; then
    echo "  $name already running (pid $(cat "$PID_DIR/$name.pid"))"; return 0
  fi
  "$@" > "$LOG_DIR/$name.log" 2>&1 &
  echo $! > "$PID_DIR/$name.pid"
  echo "  $name started (pid $!) → logs/$name.log"
}

echo "=============================================================="
echo " cBioPortal Ask Muse — starting stack"
echo " PROJECT_ROOT: $PROJECT_ROOT"
echo "=============================================================="

if [[ $SKIP_MONGO -eq 0 ]]; then
  echo "[0/5] gn-mongo :27017 (${GN_MONGO_IMAGE})"
  if is_mongo_ready; then
    echo "  already running and ready"
  else
    if docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' gn-mongo 2>/dev/null \
         | grep -q -- '--bind_ip_all'; then
      docker start gn-mongo >/dev/null && echo "  started existing container"
    else
      # Missing, or created without --bind_ip_all (its mongod is loopback only).
      docker rm -f gn-mongo >/dev/null 2>&1 || true
      docker run --platform linux/amd64 --name=gn-mongo --restart=always -p 27017:27017 \
        -e MONGODB_EXTRA_FLAGS="$GN_MONGO_FLAGS" -d "$GN_MONGO_IMAGE" >/dev/null \
        && echo "  created container"
    fi
    echo "  first start imports reference data: ~4 min native, up to ~15 min emulated"
    wait_for gn-mongo "gn-mongo" 1200 is_mongo_ready \
      || { echo "  see: docker logs gn-mongo"; exit 1; }
  fi
fi

echo "[1/5] AlphaGenome sidecar :8000"
start_bg sidecar "$SVC/start_sidecar.sh"
wait_for sidecar "sidecar" 90 curl -fsS --max-time 5 http://localhost:8000/health \
  || { echo "  see logs/sidecar.log"; exit 1; }

# The backend calls the sidecar on a cache miss, so the sidecar goes first.
echo "[2/5] Genome Nexus backend :38080"
start_bg gn-backend "$SVC/start_gn_backend.sh"
wait_for gn-backend "GN backend" 900 curl -fsS --max-time 10 \
  "http://localhost:38080/annotation/7:g.140453136A%3ET" \
  || { echo "  see logs/gn-backend.log"; exit 1; }

echo "[3/5] Genome Nexus frontend :3088"
start_bg gn-frontend "$SVC/start_gn_frontend.sh"
wait_for gn-frontend "GN frontend" 240 curl -fsS --max-time 5 -o /dev/null http://localhost:3088/ \
  || { echo "  see logs/gn-frontend.log"; exit 1; }

echo "[4/5] cBioPortal frontend :3000"
start_bg cbio-frontend "$SVC/start_cbio_frontend.sh"
wait_for cbio-frontend "cbio frontend" 600 curl -fsSk --max-time 10 -o /dev/null https://localhost:3000/ \
  || { echo "  see logs/cbio-frontend.log"; exit 1; }

echo "[5/5] Verify"; echo
exec "${PLUGIN_DIR}/verify.sh"
