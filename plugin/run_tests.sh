#!/usr/bin/env bash
# ==============================================================================
# Run the test suites. OPTIONAL and advisory.
#
# Nothing in bootstrap.sh or start_all.sh calls this, and a failure here never
# blocks installing, building or starting the stack. Run it if you want to see
# the suite; skip it and the demo is unaffected.
#
#   ./run_tests.sh            offline suites only (default)
#   ./run_tests.sh --network  also the tests that call GitHub and NCBI
# ==============================================================================
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

WITH_NETWORK=0
[[ "${1:-}" == "--network" ]] && WITH_NETWORK=1

# These call GitHub and NCBI E-utilities. They are deselected by default: an
# unauthenticated or proxied host gets 403 or a rate limit and the test fails
# for a reason that has nothing to do with this code.
NETWORK_TESTS=(
  "tests/test_colab.py::test_ensure_notebook_published_existing_file_live"
  "tests/test_colab.py::test_colab_params_live"
  "tests/test_muse_tools.py::test_clinvar_lookup_exact_allele_live"
  "tests/test_muse_tools.py::test_gene_summary_and_pubmed_live"
  "tests/test_muse_tools.py::test_civic_and_cohort_live"
)

echo "=============================================================="
echo " Tests (advisory — the demo does not depend on this)"
echo "=============================================================="

RC=0

echo
echo "--- sidecar (pytest) ---"
if [[ -x "${VENV}/bin/python" ]]; then
  ARGS=(-q -p no:cacheprovider)
  if [[ $WITH_NETWORK -eq 0 ]]; then
    for t in "${NETWORK_TESTS[@]}"; do ARGS+=(--deselect "$t"); done
  fi
  # ONCOTREE_MAP_PATH comes from lib/env.sh. Without it three map_oncotree
  # tests fail on a missing file rather than on behaviour.
  ( cd "${WORKSPACE}/alphagenome-sidecar" && "${VENV}/bin/python" -m pytest "${ARGS[@]}" ) || RC=1
else
  echo "  venv not found — run ./bootstrap.sh first. Skipping."
fi

echo
echo "--- cBioPortal frontend (typecheck) ---"
if [[ -d "${WORKSPACE}/cbioportal-frontend/node_modules" ]]; then
  use_node
  ( cd "${WORKSPACE}/cbioportal-frontend" && npx tsc --noEmit -p tsconfig.json ) \
    && echo "  no type errors" || RC=1
else
  echo "  node_modules not found — run ./bootstrap.sh first. Skipping."
fi

echo
echo "--------------------------------------------------------------"
if [[ $RC -eq 0 ]]; then
  echo " Tests passed."
else
  echo " Some tests failed. This does NOT block the demo:"
  echo "   ./start_all.sh   brings the stack up regardless"
  echo "   ./verify.sh      is the check that matters for the demo"
fi
# Exit 0 on purpose: this script reports, it does not gate.
exit 0
