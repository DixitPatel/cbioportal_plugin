#!/usr/bin/env bash
# Genome Nexus backend — Spring Boot war on :38080 (needs JDK 11)
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
PORT="${1:-38080}"
JH="$(java_home_for 11)" || { echo "JDK 11 not found. Set JAVA11_HOME or: brew install openjdk@11" >&2; exit 1; }
export JAVA_HOME="$JH"
export PATH="${JAVA_HOME}/bin:${BREW_PREFIX}/bin:${PATH}"
cd "${WORKSPACE}/genome-nexus"
WAR="$(find web/target -name 'web-*.war' 2>/dev/null | head -n 1 || true)"
if [[ -z "$WAR" || ! -f "$WAR" ]]; then
  PREBUILT="$(find "${PLUGIN_DIR}/prebuilt" -name 'web-*.war' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$PREBUILT" && -f "$PREBUILT" ]]; then
    echo "Prebuilt WAR found in plugin (${PREBUILT}); copying to web/target..."
    mkdir -p web/target
    cp "$PREBUILT" web/target/
    WAR="$(find web/target -name 'web-*.war' | head -n 1)"
  else
    echo "No war found; building (first run, several minutes)..."
    mvn install -N -DskipTests -B && mvn clean install -DskipTests -B
    WAR="$(find web/target -name 'web-*.war' | head -n 1)"
  fi
fi
exec java -Dserver.port="$PORT" -Dspring.data.mongodb.auto-index-creation=false -jar "$WAR"
