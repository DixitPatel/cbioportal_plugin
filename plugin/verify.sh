#!/usr/bin/env bash
# Health-check every service. Exit 0 = all green; exit 1 = something is down.
# Each DOWN line names the command that fixes it.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

FAIL=0
ok()  { printf '  OK    %-24s %s\n' "$1" "$2"; }
bad() { printf '  DOWN  %-24s %s\n' "$1" "$2"; FAIL=1; }

echo "=============================================================="
echo " cBioPortal Ask Muse — health check"
echo "=============================================================="

is_mongo_ready \
  && ok "gn-mongo :27017" "ready on the container network, data loaded" \
  || bad "gn-mongo :27017" "./start_all.sh (recreates gn-mongo with --bind_ip_all if needed)"

SC=$(curl -fsS --max-time 5 http://localhost:8000/health 2>/dev/null)
[[ -n "$SC" ]] && ok "sidecar :8000" "$(printf '%s' "$SC" | head -c 50)" \
               || bad "sidecar :8000" "services/start_sidecar.sh"

# Assert the alpha_genome field is really there. A port that merely answers
# is not enough: that is the failure you would otherwise meet mid-demo.
GN=$(curl -fsS --max-time 90 \
  "http://localhost:38080/annotation/7:g.140453136A%3ET?fields=alpha_genome" 2>/dev/null)
if [[ -n "$GN" ]]; then
  N=$(printf '%s' "$GN" | python3 -c '
import json,sys
try:
    a = json.load(sys.stdin)["alpha_genome"]["annotation"]
    print("%d scores, merged %s" % (len(a["scores"]), a["merged_splicing_score"]))
except Exception:
    print("NO_FIELD")' 2>/dev/null)
  [[ "$N" == "NO_FIELD" ]] \
    && bad "GN backend :38080" "up, but no alpha_genome — is the sidecar healthy?" \
    || ok "GN backend :38080" "$N"
else
  bad "GN backend :38080" "services/start_gn_backend.sh"
fi

curl -fsS --max-time 5 -o /dev/null http://localhost:3088/ 2>/dev/null \
  && ok "GN frontend :3088" "serving" \
  || bad "GN frontend :3088" "services/start_gn_frontend.sh"

curl -fsSk --max-time 10 -o /dev/null https://localhost:3000/ 2>/dev/null \
  && ok "cbio frontend :3000" "serving (https, self-signed)" \
  || bad "cbio frontend :3000" "services/start_cbio_frontend.sh"

# The OncoTree map is not in any repository; the plugin ships it. If this is
# missing, services still start but every tissue lookup returns nothing and
# the Colab flow answers 422 — a silent failure, so check it explicitly.
if [[ -f "$ONCOTREE_MAP_PATH" ]] && \
   python3 -c "import json,sys;d=json.load(open(sys.argv[1]));sys.exit(0 if d.get('mappings',{}).get('PAAD') else 1)" \
     "$ONCOTREE_MAP_PATH" 2>/dev/null; then
  ok "OncoTree map" "$(python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))['mappings']),'mappings')" "$ONCOTREE_MAP_PATH")"
else
  bad "OncoTree map" "not found or incomplete at ONCOTREE_MAP_PATH"
fi

if [[ -z "${META_API_KEY:-}" ]]; then
  bad "Meta API key" "not set — run ./set_meta_key.sh"
else
  CODE=$(curl -sS -o /tmp/muse_verify.json -w '%{http_code}' --max-time 60 \
    -X POST "${MUSE_WONDER_API_URL:-https://api.meta.ai/v1}/chat/completions" \
    -H "Authorization: Bearer ${META_API_KEY}" -H 'Content-Type: application/json' \
    -d '{"model":"muse-wonder-1.0","reasoning_effort":"low",
         "messages":[{"role":"user","content":"Reply with OK"}]}' 2>/dev/null)
  [[ "$CODE" == "200" ]] && ok "muse-wonder-1.0" "200" \
    || bad "muse-wonder-1.0" "http $CODE — $(head -c 100 /tmp/muse_verify.json 2>/dev/null)"
fi

echo "--------------------------------------------------------------"
if [[ $FAIL -eq 0 ]]; then
  echo " ALL GREEN — see plugin/docs/DEMO.md for the walkthrough"
else
  echo " INCOMPLETE — fix the DOWN lines above, then re-run ./verify.sh"
  echo " Stuck? Give the output and the named log to Muse Code and ask it"
  echo " to use the demo-recovery skill."
fi
exit $FAIL
