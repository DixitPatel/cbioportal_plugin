#!/usr/bin/env bash
# Install the plugin's Muse Code skills so `muse` can find them.
# Run this FIRST if you want the setup agent to drive the install.
#   ./install_skills.sh            -> workspace/.agents/skills/ and plugin/.agents/skills/
#   ./install_skills.sh --user     -> ~/.agents/skills/
#   ./install_skills.sh <dir>      -> a directory you choose
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"
if [[ "${1:-}" == "--user" ]]; then
  DEST="${HOME}/.agents/skills"
else
  DEST="${1:-${WORKSPACE}/.agents/skills}"
fi
mkdir -p "$DEST"
for s in "${PLUGIN_DIR}"/skills/*/; do
  name="$(basename "$s")"
  rm -rf "${DEST:?}/${name}"
  cp -R "$s" "${DEST}/${name}"
  echo "installed ${name} -> ${DEST}/${name}"
  if [[ $# -eq 0 ]]; then
    mkdir -p "${PLUGIN_DIR}/.agents/skills" "${PLUGIN_DIR}/../.agents/skills"
    rm -rf "${PLUGIN_DIR}/.agents/skills/${name}" "${PLUGIN_DIR}/../.agents/skills/${name}"
    cp -R "$s" "${PLUGIN_DIR}/.agents/skills/${name}"
    cp -R "$s" "${PLUGIN_DIR}/../.agents/skills/${name}"
  fi
done
echo
echo "In Muse Code:  \"use the setup-agent skill to install the stack\""
