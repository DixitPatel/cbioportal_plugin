#!/usr/bin/env bash
# ==============================================================================
# One-time setup: clone the six repositories, install the toolchain, install
# every dependency. Run this once, then ./start_all.sh.
#
#   ./bootstrap.sh                 # everything needed for the demo
#   ./bootstrap.sh --with-pipeline # also the annotation pipeline (slow, optional)
#   ./bootstrap.sh --check         # report what is missing; change nothing
# ==============================================================================
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

WITH_PIPELINE=0; CHECK_ONLY=0
for a in "$@"; do case "$a" in
  --with-pipeline) WITH_PIPELINE=1 ;;
  --check) CHECK_ONLY=1 ;;
  -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
esac; done

say()  { printf '\n=== %s ===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Repositories come from repos.tsv, the single source of truth. Nothing here
# hardcodes a branch, so the manifest and the clone can never disagree.
MANIFEST="${PLUGIN_DIR}/repos.tsv"
[[ -f "$MANIFEST" ]] || { echo "missing $MANIFEST" >&2; exit 1; }

REPOS=()
while IFS=$'\t' read -r name url branch required; do
  [[ -z "${name:-}" || "${name:0:1}" == "#" ]] && continue
  [[ "$required" == "no" && $WITH_PIPELINE -eq 0 ]] && continue
  REPOS+=("${name}|${url}|${branch}")
done < "$MANIFEST"
[[ ${#REPOS[@]} -gt 0 ]] || { echo "no repositories parsed from $MANIFEST" >&2; exit 1; }

# ---------- keys ----------
# judges.env carries the AlphaGenome key and leaves META_API_KEY blank. The
# Meta key is personal: it is asked for here and stored only in
# agentic-setup/.env, outside this repository.
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ $CHECK_ONLY -eq 1 ]]; then
    echo "  note: ${ENV_FILE} does not exist yet; ./bootstrap.sh creates it from plugin/judges.env"
    load_env_file "${PLUGIN_DIR}/judges.env"
  else
    mkdir -p "$(dirname "$ENV_FILE")"
    cp "${PLUGIN_DIR}/judges.env" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "Created ${ENV_FILE} from plugin/judges.env (AlphaGenome key included)."
    load_env_file "$ENV_FILE"
  fi
fi
if [[ -z "${META_API_KEY:-}" && $CHECK_ONLY -eq 0 && -t 0 ]]; then
  say "Meta Model API key"
  echo "  Ask Muse needs your own Meta Model API key."
  echo "  It is stored only in ${ENV_FILE}, never in this repository."
  if "${PLUGIN_DIR}/set_meta_key.sh"; then load_env_file "$ENV_FILE"; fi
fi

# ---------- preflight ----------
say "Preflight"
MISSING=0
for t in git curl docker; do
  if have "$t"; then echo "  ok      $t"; else echo "  MISSING $t"; MISSING=1; fi
done
if have brew || [[ "$(uname -s)" != Darwin ]]; then echo "  ok      package manager"; else
  echo "  MISSING brew (https://brew.sh)"; MISSING=1; fi
if JH="$(java_home_for 11 2>/dev/null)"; then echo "  ok      JDK 11 ($JH)"; else
  echo "  MISSING JDK 11 — brew install openjdk@11, or set JAVA11_HOME"; MISSING=1; fi
if have mvn; then echo "  ok      maven"; else echo "  MISSING maven — brew install maven"; MISSING=1; fi
PY313="$(command -v python3.13 || echo "${BREW_PREFIX}/opt/python@3.13/bin/python3.13")"
if [[ -x "$PY313" ]]; then echo "  ok      python3.13"; else
  echo "  MISSING python3.13 — brew install python@3.13"; MISSING=1; fi
if [[ -n "${META_API_KEY:-}" ]]; then echo "  ok      META_API_KEY"; else
  echo "  MISSING META_API_KEY — run ./set_meta_key.sh (input is hidden)"; MISSING=1; fi
if [[ -n "${ALPHA_GENOME_API_KEY:-}" ]]; then echo "  ok      ALPHA_GENOME_API_KEY"; else
  echo "  MISSING ALPHA_GENOME_API_KEY — expected from plugin/judges.env"; MISSING=1; fi

if [[ $CHECK_ONLY -eq 1 ]]; then
  [[ $MISSING -eq 0 ]] && echo -e "\nAll preflight checks pass." || echo -e "\nInstall what is marked MISSING, then re-run."
  exit $MISSING
fi
[[ $MISSING -eq 0 ]] || { echo -e "\nFix the MISSING items above first, or run --check for the list only."; exit 1; }

# ---------- clone ----------
say "Repositories"
echo "  None of this work is on main or master. Exact branches from repos.tsv:"
printf '    %-34s %s\n' "REPOSITORY" "BRANCH"
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name _ branch <<< "$entry"
  printf '    %-34s %s\n' "$name" "$branch"
done
echo

mkdir -p "$WORKSPACE"
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name url branch <<< "$entry"
  target="${WORKSPACE}/${name}"

  if [[ -d "${target}/.git" ]]; then
    actual="$(git -C "$target" branch --show-current)"
    if [[ "$actual" == "$branch" ]]; then
      echo "  present  ${name} @ ${branch}"
    else
      echo "  WRONG BRANCH  ${name}: on '${actual}', expected '${branch}'" >&2
      echo "                cd ${target} && git checkout ${branch}" >&2
      exit 1
    fi
    continue
  fi

  echo "  cloning  ${name} @ ${branch}"
  if ! git clone --branch "$branch" "$url" "$target" 2>&1 | sed 's/^/           /'; then
    cat >&2 <<ERR
           FAILED to clone ${name} at branch ${branch}
           remote: ${url}

           The branch is not published, or the repository is private.
           Do NOT fall back to main or master: they do not contain this work,
           and the stack would start cleanly while missing the whole feature.
           Stop here and report the remote and branch above.
ERR
    exit 1
  fi

  # A clone can land elsewhere if the remote moved the ref. Verify.
  actual="$(git -C "$target" branch --show-current)"
  if [[ "$actual" != "$branch" ]]; then
    echo "           FAILED: cloned '${actual}', expected '${branch}'" >&2
    exit 1
  fi
  echo "           ok, HEAD $(git -C "$target" rev-parse --short HEAD) on ${actual}"
done

# ---------- node toolchain ----------
say "Node ${NODE_VERSION} toolchain"
if [[ -x "${NODE_DIR}/bin/node" ]]; then
  echo "  present  ${NODE_DIR}"
else
  PLAT="$(node_platform)"
  TARBALL="node-v${NODE_VERSION}-${PLAT}.tar.gz"
  echo "  fetching ${TARBALL}"
  mkdir -p "$BIN_DIR"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}" | tar -xz -C "$BIN_DIR"
fi
use_node
node --version | sed 's/^/  node    /'
have pnpm && [[ "$(pnpm --version)" == 10.33.0 ]] || npm install -g pnpm@10.33.0 >/dev/null
have yarn || npm install -g yarn@1.22.22 >/dev/null
echo "  pnpm    $(pnpm --version)"
echo "  yarn    $(yarn --version)"

# ---------- python ----------
say "Python environment"
if [[ -x "${VENV}/bin/python" ]]; then
  echo "  present  ${VENV}"
else
  "$PY313" -m venv "$VENV"
fi
"${VENV}/bin/pip" install --quiet --upgrade pip setuptools wheel
"${VENV}/bin/pip" install --quiet "mcp<2" fastapi uvicorn httpx pypdf pytest python-dotenv nbformat \
  "pymongo>=4.9,<4.14"   # sidecar reads gn-mongo (MongoDB 4.0; pymongo 4.14 dropped 4.0)
echo "  installing alphagenome SDK (editable)"
"${VENV}/bin/pip" install --quiet -e "${WORKSPACE}/alphagenome"
echo "  installing sidecar + dev extras (editable)"
"${VENV}/bin/pip" install --quiet -e "${WORKSPACE}/alphagenome-sidecar[dev]"
"${VENV}/bin/python" -c "import importlib.metadata as m; print('  alphagenome', m.version('alphagenome'))"

# ---------- frontend deps ----------
say "Frontend dependencies (several minutes)"
( cd "${WORKSPACE}/genome-nexus-frontend" && yarn install --non-interactive ) \
  2>&1 | tail -2 | sed 's/^/  gn-frontend  /'
( cd "${WORKSPACE}/cbioportal-frontend" && pnpm install --frozen-lockfile ) \
  2>&1 | tail -2 | sed 's/^/  cbio         /'

# ---------- java deps ----------
say "Genome Nexus Maven dependencies"
export JAVA_HOME="$(java_home_for 11)"
export PATH="${JAVA_HOME}/bin:${BREW_PREFIX}/bin:${PATH}"
PREBUILT="$(find "${PLUGIN_DIR}/prebuilt" -name 'web-*.war' 2>/dev/null | head -n 1 || true)"
if [[ -n "$PREBUILT" && -f "$PREBUILT" ]]; then
  echo "  prebuilt WAR present in plugin: $(basename "$PREBUILT")"
  echo "  installing into ${WORKSPACE}/genome-nexus/web/target (skips 15-25m build)"
  mkdir -p "${WORKSPACE}/genome-nexus/web/target"
  cp "$PREBUILT" "${WORKSPACE}/genome-nexus/web/target/"
else
  ( cd "${WORKSPACE}/genome-nexus" && mvn install -N -DskipTests -B && mvn -q dependency:go-offline -B ) \
    2>&1 | tail -3 | sed 's/^/  /' || echo "  (go-offline reported errors; the build in start_all will resolve the rest)"
fi

say "Muse Code skills"
"${PLUGIN_DIR}/install_skills.sh" | sed 's/^/  /'

say "Done"
echo "Next:  ./start_all.sh          (or ask Muse Code: use the setup-agent skill)"
echo "       Stack starts in ~3 minutes (prebuilt WAR included). The first start also"
echo "       imports the gn-mongo reference data (~4 min native, up to ~15 min emulated)."
