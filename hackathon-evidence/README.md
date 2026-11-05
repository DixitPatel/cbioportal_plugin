# hackathon

The work ran as seven workstreams (W1–W7), driven by Muse Code against the
specs and skills recorded here. Each workstream had its own acceptance test and
a human approval gate between steps.

| Folder | Contents |
|---|---|
| `workstreams/` | W1–W7 specifications, handoff plans between stages, and the API contracts (`contracts/sidecar_openapi.yaml`, `alpha_genome_schema.json`, `oncotree_to_uberon.json`) |
| `agent-config/` | The `AGENTS.md` each repository was given, the shared agent memory, and the implementation plan |
| `agent-skills/` | The skills Muse Code worked from — `alphagenome-sidecar`, `genome-nexus-enricher`, `cbioportal-annotation-cell`, `liftover-refcheck`, `variant-page-view`, `verify-pipeline`, `tdd`, `code-review`, `ncbi-etiquette`, and others |
| `reports/` | Verification reports and per-workstream retrospectives, including `trajectories/event_log.jsonl` |
| `command-references/` | The original setup, build and service-restart command files, with machine-specific paths generalised |

## Workstreams

| ID | Scope |
|---|---|
| W1 | GRCh37→GRCh38 liftover and reference-allele check |
| W2 | AlphaGenome scoring sidecar |
| W3 | Genome Nexus enricher — the `alpha_genome` annotation field |
| W4 | cBioPortal annotation cell, click-to-score with a background queue |
| W5 | Genome Nexus variant page |
| W6 | Ask Muse co-pilot and the Colab cookbook |
| W7 | Patient-view contextual charts and the cross-tab Ask Muse window |
