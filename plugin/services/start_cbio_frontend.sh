#!/usr/bin/env bash
# cBioPortal frontend — rspack dev server on :3000 (https, self-signed).
# GENOME_NEXUS_URL points at the LOCAL backend: the alpha_genome field only
# exists there. The public host would answer 404 for it and the cell stays blank.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
use_node
export PORT="${PORT:-3000}"
export BRANCH_ENV="${BRANCH_ENV:-master}"
export CBIOPORTAL_URL="${CBIOPORTAL_URL:-https://www.cbioportal.org}"
export GENOME_NEXUS_URL="${GENOME_NEXUS_URL:-http://localhost:38080}"
cd "${WORKSPACE}/cbioportal-frontend"
[[ -d node_modules ]] || pnpm install --frozen-lockfile
if [[ -x ./scripts/check_build_prereqs.sh ]]; then
  ./scripts/check_build_prereqs.sh || pnpm run buildModules
else
  pnpm run buildModules
fi
mkdir -p env
cat > env/custom.sh <<INNER
export CBIOPORTAL_URL="${CBIOPORTAL_URL}"
export GENOME_NEXUS_URL="${GENOME_NEXUS_URL}"
INNER
exec pnpm run watch
