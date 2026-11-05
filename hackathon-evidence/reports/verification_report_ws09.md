# WS-09 Verification Report — Critical Section Task D (Muse Co-Pilot)

## WS-09.R Remediation & Re-Verification (2026-11-02, Muse orchestrator)

Branches: `w6-muse-copilot` (sidecar + frontend). No `.env` file was edited
(central `agentic-setup/.env` is only *read* at router import). Live MongoDB:
`gn-mongo` container, `annotator.alphagenome.annotation` = **5753 docs**.

### Fixes applied

- **Sidecar `app/sample_trainer.py`** (Fix 4): `query_keys = ("_id", "variant",
  `"hg38_variant"`, `"variant_id"`) with `_id` first; module-level cached
  `MongoClient`; `docker exec gn-mongo mongosh` fallback
  (`_mongosh_eval` with one retry, `_mongosh_find_one`, `_mongosh_count`)
  so `mongo_cached_count()` / `fetch_annotation()` read live docs with no
  pymongo installed; `_unwrap_doc()` unwraps a nested `annotation` dict when
  present. (One real bug caught live: the generated `--eval` JS was missing
  the final `)` closing `JSON.stringify(` → mongosh `SyntaxError`, every
  lookup MISS; fixed, verified OK.)
- **Same file** (Fix 5): `inspect_batch_failures` computes
  `reachable = mongo_reachable()`; `absent_from_mongo` is only true when
  Mongo is reachable AND the variant is missing; log evidence uses
  `EXPLICIT_FAILURE_KEYWORDS = (FAILED, ERROR, REJECTED, MISMATCH)` over the
  last 5 MB. Offline (unreachable) + no log hits → `[]`.
- **Same file** (Fix 7b): `gene_entry["variants"]` deduplicated by
  `(study_id, case_id, variant_id)` in place; JSONL records rewritten when a
  previously empty record gains real MongoDB top tracks (`jsonl_updated`).
  `index_patient_sample` also accepts camelCase entry keys defensively.
- **`app/copilot_router.py`** (Fix 1, 2, 3, 6): loads central `.env` via
  `dotenv.load_dotenv` with a manual parser fallback (`override=False`
  both ways); `VariantRef` accepts `variantId` / `hugoGeneSymbol(+gene)` /
  `proteinChange` aliases; `ChatRequest` accepts `action` alias and
  normalizes `"chat"`/`""` → `None`; `_resolve_oncotree()` matches code key
  OR case-insensitive `oncotree_name`, with an explicit message code token
  winning over the study type, and `suggested_mapping` now includes
  `oncotree_name`; `_fallback_reply` for `cross_reference_genes` /
  `prep_literature_context` returns rich multi-bullet KB summaries
  (studies, hg38 ids, `merged_splicing_score`, top UBERON/CL tracks per
  output type, PubMed search terms); `_wonder_reply` payload carries the same
  `kb_context` slice.
- **Tests** (`tests/test_copilot.py`, 10 new): offline-absent never flagged,
  reachable-absent flagged, nested-annotation unwrap, cross-call dedup,
  JSONL upgrade on tracks arrival, camelCase `VariantRef`, `action` alias +
  `"chat"` normalization, message OncoTree token (`PANET` over `PAAD`
  study), `oncotree_name` match, rich KB formatting. Existing 5 MB
  reverse-seek test now stubs `mongo_reachable() → True` (contract change);
  `isolated_kb` defaults to unreachable for hermetic offline runs.
- **Frontend** (`AskMuseFloatingWindow.tsx`, `PatientViewMutationsTab.tsx`):
  button `🧬 Ask Muse`; `sendChat(actionType: string | null, …)` posts
  snake_case `action_type` (`null` = free text); all mutations included,
  `variant_id` resolved from `indexed/streamingAlphaGenomeAnnotations`
  (`ann?.variant`, fallback `chr:g.startRef>Alt`), snake_case payload;
  `cancerTypeId || cancerType?.shortName || cancerType?.name`; index status
  from `data.indexed_count`. `packages/react-mutation-mapper/` diff empty.

### Fresh results (this session, observed)

- Sidecar: `48 passed` (pinned venv `pytest`, incl. 24 `test_score.py`).
- Frontend: `tsc --noEmit` exit 0; `pnpm --filter react-mutation-mapper
  run test`: 10 passed / 1 skipped suites, 62 passed / 4 skipped tests.
- `GET /copilot/health` → `mongo_cached_count: 5753` (live mongosh fallback).
- `POST /copilot/index-sample` (PAAD/TCGA-3E-AAVA, BRAF `7:g.140453136A>T`,
  TP53, 2× CDKN2A) → `indexed_count: 4`, `genes: [BRAF, CDKN2A, TP53]`;
  store + JSONL carry real tracks, e.g. BRAF `chr7:140753336:A>T`,
  `merged_splicing_score 0.042431640625`,
  `RNA_SEQ/SPLICE_SITES/SPLICE_SITE_USAGE/SPLICE_JUNCTIONS` all non-empty.
  `failed_count: 1` = one genuine pre-existing synthetic log line
  (`RuntimeError: boom` scoring probe from 11-01/11-02, still in the 5 MB
  tail) with `absent_from_mongo: false` — correctly surfaced with evidence,
  not a false absent flag.
- All 4 chat actions + free text verified live: `map_oncotree` PAAD →
  `UBERON:0001264` + `oncotree_name`; message `PANET` token wins over a
  `Pancreatic Adenocarcinoma` study type; `cross_reference_genes` and
  `prep_literature_context` return KB-grounded bullets/briefs;
  `action` alias + camelCase `VariantRef` accepted; free text →
  `action_type: null`.
- Server is session-managed (no `setsid` on macOS): restart with
  `COPILOT_KB_DIR=<dir> <venv>/bin/uvicorn app.main:app --host 127.0.0.1
  --port 8000` from `workspace/alphagenome-sidecar`.

---

# WS-09 Verification Report — Critical Section Task D (Muse Co-Pilot) — prior pass

Date: 2026-11-02 (UTC). Verifier: WS-09 agent-10. Branch: `w6-muse-copilot`
(sidecar + frontend). No `.env` file was edited during verification.

## Server readiness

- Stale sidecar PID 47604 (started 01:59, predated copilot mount → `GET
  /copilot/health` 404) was killed (`kill 47604`, port confirmed closed).
- Fresh `uvicorn app.main:app --host 0.0.0.0 --port 8000` started from
  `alphagenome-sidecar/` with the pinned venv; bounded curl health checks pass.
  NOTE: macOS has no `setsid`, so the server runs as a runtime-managed process
  and does NOT outlive this session — restart it before any later E2E run:
  `<pinned-venv>/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000`
  from `workspace/alphagenome-sidecar`.
- `curl -s http://localhost:8000/health` →
  `{"status":"ok","service":"alphagenome-sidecar"}` (HTTP 200).
- `curl -s http://localhost:8000/copilot/health` →
  `{"status":"ok","mongo_cached_count":0,"indexed_studies_count":0,...}`
  (HTTP 200). `mongo_cached_count: 0` — no MongoDB reachable from this host
  (no pymongo/mongosh); live annotation join degrades to empty docs by design.

## Gate verdicts

| Gate | Verdict | Key evidence |
|------|---------|--------------|
| D.1 branch isolation + 0-line guard + POST /score unchanged | PASS | `git diff --stat` sidecar: only `app/main.py` (+10: CORS + copilot router mount); `git diff --numstat -- app/scoring.py app/logger.py` empty; `git diff --stat -- packages/react-mutation-mapper/` empty (0 lines in AlphaGenome.tsx/Annotation.tsx). Live `POST /score` BRAF payload → HTTP 200, `hg38_variant chr7:140753336:A>T`, real SPLICE_JUNCTIONS scores |
| D.2 index-sample TCGA PAAD + KB + JSONL | PASS | `POST /copilot/index-sample` (paad_tcga_pan_can_atlas_2018/PAAD/TCGA-3E-AAAV, KRAS/TP53/SMAD4/CDKN2A) → `indexed_count:4`, `genes_indexed:[CDKN2A,KRAS,SMAD4,TP53]`, `kb_stats:{studies:1,samples:1,genes:4}` in 25 ms. `workspace/logs/copilot_kb/muse_wonder_training_samples.jsonl` = 4 lines with `study_id::case_id::hugo_symbol::variant_id` dedup keys; `study_gene_knowledge_store.json` present. `failed_count:4` with `cause:sidecar_error, absent_from_mongo:true` is the designed offline cross-check (no Mongo here), not a regression |
| D.3 chat show_batch_failures <50 ms reverse-seek, FAILED-only | PASS | `POST /copilot/chat` action `show_batch_failures` → 24 ms total round-trip; reply + `failed_variants[]` only (FAILED-only surface). 3.94 GB pipeline log (`logs/alphagenome_pipeline_debug.log`) served via 5 MB tail seek; unit test `test_inspect_batch_failures_5mb_reverse_seek` (<50 ms, TAIL_BYTES=5242880) passes in fresh suite |
| D.4 map_oncotree + xref + lit-context + save-mapping persistence | PASS | `map_oncotree` PAAD → `UBERON:0001264` pancreas + suggested_mapping; PANET → `UBERON:0000016` endocrine pancreas. `cross_reference_genes` and `prep_literature_context` return data-grounded fallbacks (`source:fallback`, live Wonder key unset). `POST /copilot/save-mapping` → `saved:true`; entry confirmed re-read from `workstreams/contracts/oncotree_to_uberon.json`, then probe entry removed (file reverted) |
| D.5 frontend Ask Muse button + floating window + tsc + Jest | PASS | `Ask Muse` companion button (2 hits in PatientViewMutationsTab.tsx, scored-complete branch only); floating window geometry verified (`position:fixed, bottom:24, right:24, width:440, height:560, zIndex:9999`, AskMuseFloatingWindow.tsx:209-214); zero auto-query (fetch only in click/send handlers). `npx tsc --noEmit` exit 0, 0 errors. `pnpm --filter react-mutation-mapper run test`: 10 passed/1 skipped suites, 62 passed/4 skipped tests, exit 0 |

## Test totals (freshly observed this session)

- Sidecar: `38 passed in 0.80s` (pinned venv `pytest -q`; includes 3 Tester
  reverse-seek/fallback/persistence tests + 24 `test_score.py` regression tests).
- Frontend: tsc exit 0; Jest 62 passed / 4 skipped (0 failed).

## Curl command log (all against http://localhost:8000)

1. `curl -s http://localhost:8000/health`
2. `curl -s -X POST /score -d '{"variant":"7:g.140453136A>T","chromosome":"chr7","position":140753336,"reference_allele":"A","alternate_allele":"T","canonical_gene_id":"ENSG00000157764","canonical_gene":"BRAF"}'`
3. `curl -s -X POST /copilot/index-sample -d '{"study_id":"paad_tcga_pan_can_atlas_2018","cancer_type":"PAAD","case_id":"TCGA-3E-AAAV","variants":[{KRAS},{TP53},{SMAD4},{CDKN2A}]}'`
4. `curl -s -X POST /copilot/chat -d '{"action_type":"show_batch_failures",...}'`
5. `curl -s -X POST /copilot/chat -d '{"action_type":"map_oncotree","cancer_type":"PAAD",...}'` (+ PANET, xref, lit-context variants)
6. `curl -s -X POST /copilot/save-mapping -d '{"oncotree_code":"PAAD_VERIFY",...}'` (probe entry reverted afterwards)

## Unresolved / non-blocking

- Live MongoDB join unverified (no pymongo/mongosh on host); code degrades to
  empty docs and tests mock the layer. `mongo_cached_count` = 0 observed.
- Live Muse Wonder path untested (`MUSE_WONDER_API_URL`/`META_API_KEY` unset);
  deterministic fallback verified for all 4 actions + unknown action.
- Sidecar server is session-managed (no `setsid` on macOS) — restart required
  for later runs (command above).
- Pre-existing uncommitted `env/custom.sh` + `rspack.config.js` mods in
  cbioportal-frontend predate this work; recommend excluding from squash/PR.
