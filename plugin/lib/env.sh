# Shared environment for the cBioPortal Ask Muse plugin.
# Sourced by every script. Derives all paths; nothing is hardcoded to a machine.
# shellcheck shell=bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${PLUGIN_DIR}/../.." && pwd)}"
WORKSPACE="${PROJECT_ROOT}/workspace"
SETUP_DIR="${PROJECT_ROOT}/agentic-setup"
VENV="${SETUP_DIR}/.venv"
BIN_DIR="${SETUP_DIR}/bin"
LOG_DIR="${WORKSPACE}/logs"
PID_DIR="${LOG_DIR}/pids"
ENV_FILE="${SETUP_DIR}/.env"

NODE_VERSION="22.18.0"

# Load the env file LITERALLY. Never `source` it: a Meta key looks like
# LLM|<id>|<secret>, and bash parses an unquoted `|` as a pipeline, so
# `source` silently leaves META_API_KEY unset and Ask Muse falls back to the
# offline demo. This parser treats every value as plain text, strips one layer
# of matching quotes, and lets an already-exported variable win — the same
# precedence the sidecar uses (load_dotenv override=False). Bash 3.2 safe.
load_env_file() {
  local f="$1" line key val first last
  [[ -f "$f" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "${line:0:1}" == "#" || "$line" != *=* ]] && continue
    key="${line%%=*}"; val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if (( ${#val} >= 2 )); then
      first="${val:0:1}"; last="${val:${#val}-1:1}"
      if [[ ( "$first" == '"' && "$last" == '"' ) || ( "$first" == "'" && "$last" == "'" ) ]]; then
        val="${val:1:${#val}-2}"
      fi
    fi
    [[ -n "${!key:-}" ]] && continue   # a non-empty exported value wins
    export "$key=$val"
  done < "$f"
}
load_env_file "$ENV_FILE"

# --- platform ------------------------------------------------------------
# Node ships per platform; pick the right tarball instead of assuming macOS ARM.
node_platform() {
  local os arch
  case "$(uname -s)" in
    Darwin) os=darwin ;;
    Linux)  os=linux ;;
    *) echo "unsupported OS: $(uname -s)" >&2; return 1 ;;
  esac
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64)  arch=x64 ;;
    *) echo "unsupported arch: $(uname -m)" >&2; return 1 ;;
  esac
  echo "${os}-${arch}"
}

NODE_DIR="${BIN_DIR}/node-v${NODE_VERSION}-$(node_platform 2>/dev/null || echo unknown)"

# Homebrew lives in different places on ARM and Intel Macs.
BREW_PREFIX="$( (command -v brew >/dev/null && brew --prefix) 2>/dev/null || echo /opt/homebrew)"

# Find a JDK of a given major version: JAVA<N>_HOME wins, then Homebrew,
# then macOS java_home, then whatever java is on PATH.
java_home_for() {
  local want="$1" explicit
  explicit="JAVA${want}_HOME"
  if [[ -n "${!explicit:-}" ]]; then echo "${!explicit}"; return 0; fi
  local cand="${BREW_PREFIX}/opt/openjdk@${want}/libexec/openjdk.jdk/Contents/Home"
  [[ -d "$cand" ]] && { echo "$cand"; return 0; }
  cand="${BREW_PREFIX}/opt/openjdk@${want}"
  [[ -d "$cand" ]] && { echo "$cand"; return 0; }
  if [[ "$(uname -s)" == Darwin ]] && /usr/libexec/java_home -v "$want" >/dev/null 2>&1; then
    /usr/libexec/java_home -v "$want"; return 0
  fi
  return 1
}

use_node() { export PATH="${NODE_DIR}/bin:${BREW_PREFIX}/bin:${PATH}"; }

# --- paths the sidecar resolves OUTSIDE its own repo ---------------------
# app/sample_trainer.py resolves three paths from the directory above the
# sidecar checkout. The OncoTree map is not in any repository, so the plugin
# ships it and points the sidecar here. Without this, every tissue lookup
# silently returns no mapping and the Colab flow answers 422.
export ONCOTREE_MAP_PATH="${ONCOTREE_MAP_PATH:-${PLUGIN_DIR}/contracts/oncotree_to_uberon.json}"
export COPILOT_KB_DIR="${COPILOT_KB_DIR:-${LOG_DIR}/copilot_kb}"
export ALPHAGENOME_DEBUG_LOG="${ALPHAGENOME_DEBUG_LOG:-${LOG_DIR}/alphagenome_pipeline_debug.log}"
export COLAB_NOTEBOOK_REF="${COLAB_NOTEBOOK_REF:-w6-muse-copilot}"
export COLAB_NOTEBOOK_REPO="${COLAB_NOTEBOOK_REPO:-DixitPatel/alphagenome_sidecar}"
mkdir -p "$COPILOT_KB_DIR" 2>/dev/null || true

mkdir -p "$LOG_DIR" "$PID_DIR" 2>/dev/null || true


# --- Genome Nexus MongoDB: prebuilt Docker image ------------------------
# genomenexus/gn-mongo:latest is Bitnami MongoDB 4.0, amd64 only, so Apple
# Silicon runs it emulated. Under emulation its config render crashes and
# mongod falls back to loopback only; --bind_ip_all keeps the port usable.
GN_MONGO_IMAGE="genomenexus/gn-mongo:latest"
GN_MONGO_FLAGS="--dbpath /bitnami/mongodb/data/db --bind_ip_all"

# is_mongo_ready: true only when all three hold.
#  1. Bitnami /setup.sh has exited. The first-run import runs inside it.
#  2. mongod answers on the container IP, where the published port forwards.
#     Not loopback, and not 0.0.0.0, which Linux routes to loopback.
#  3. The `version` collection exists. import_mongo.sh writes it last.
is_mongo_ready() {
  local ip
  docker exec gn-mongo sh -c 'grep -qs "[s]etup.sh" /proc/[0-9]*/cmdline' 2>/dev/null && return 1
  ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gn-mongo 2>/dev/null)"
  [[ -n "$ip" ]] || return 1
  docker exec gn-mongo mongo --quiet --host "$ip" annotator \
    --eval "print(db.getCollection('version').count())" 2>/dev/null | grep -Eq '^[1-9][0-9]*$'
}
