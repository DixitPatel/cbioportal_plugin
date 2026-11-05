---
name: workstream_acceptance_tests
description: Acceptance tests and verification commands for workstreams W1 through W5.
type: project
---

# Workstream Acceptance Tests (`W1`–`W5`)

| Workstream | Target Repository | Acceptance Test Criteria | Command |
| :--- | :--- | :--- | :--- |
| **`W1` Liftover & REF Check** | `genome-nexus` & `alphagenome-sidecar` | `DDX41` `5:176940011 C>T` -> `chr5:177513010 C>T`; `SMAD4 c.1520_1521del` -> `GAA>G`; mismatched `REF` rejected without scoring or caching | `pytest -v` / `mvn test -pl component,service` |
| **`W2` AlphaGenome Sidecar & Literature** | `alphagenome-sidecar` | `POST /score` filters `tidy_scores` rows to canonical gene, computes `merged_splicing_score`, echoes `variant`, and verifies every quote verbatim | `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v` |
| **`W3` Genome Nexus Enricher** | `genome-nexus` | `GET /annotation/{v}?fields=alpha_genome` returns `alpha_genome` payload; second call hits `alphagenome.annotation` cache | `JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home mvn test -pl model,component,service -B` |
| **`W4` cBioPortal Annotation Cell** | `cbioportal-frontend` | `AlphaGenomeCell` and `AlphaGenomeTooltipContent` render after `reVUE`, gated by `show_alphagenome`; unit tests pass | `pnpm --filter react-mutation-mapper run build && pnpm run testPackages` |
| **`W5` Genome Nexus Variant Page** | `genome-nexus-frontend` | `alpha_genome` in `DEFAULT_ANNOTATION_QUERY_FIELDS`; `AlphaGenome` row in `FunctionalGroups` renders score table & tissue selector | `CI=true yarn test --watchAll=false && yarn build` |
