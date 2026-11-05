# Handoff Plan 5 (WS-09 & WS-09.R): Multi-Agent Teaming, Remediation & E2E Verification Orchestration for Meta Muse Wonder Co-Pilot

**Workstream ID**: `WS-09.R` / `Task-D-Muse-Wonder-Copilot-Remediation`  
**Status**: Ready for Meta Muse Code Remediation Pass (Zero Manual Code Edits in This Session)  
**Target Harness**: Meta Muse Code CLI (`agentic-setup/bin/muse` v1.4.14)  
**Target Repositories & Active Feature Branches**:
- `workspace/alphagenome-sidecar` (Branch: `w6-muse-copilot`)
- `workspace/cbioportal-frontend` (Branch: `w6-muse-copilot`)

---

## 1. WS-09.R Remediation Tasks (Fixing All 7 Surfaced Audit Findings)

### Fix 1 (Critical — `AskMuseFloatingWindow.tsx` & `copilot_router.py`): Align `action_type` Contract & Free-Text Chat Handling
- **In `src/pages/patientView/mutation/AskMuseFloatingWindow.tsx`**:
  - In `sendChat(actionType: string | null, message: string)`:
    - Send `action_type: actionType` (snake_case, matching `ChatRequest.action_type`) instead of `action`.
    - When submitting free-text chat from the input box, pass `actionType = null` (not `'chat'`) so `request.action_type` is `None` for free-text queries and one of `map_oncotree | cross_reference_genes | show_batch_failures | prep_literature_context` for Quick-Prompt Pills.
- **In `app/copilot_router.py`**:
  - Accept both `action_type: str | None = None` and optional alias `action: str | None = None` on `ChatRequest`, normalizing `action_type = None` when value is `"chat"` or `""`.

### Fix 2 (Critical — `AskMuseFloatingWindow.tsx` & `copilot_router.py`): Extract Real `variant_id` (HGVS) & Snake_Case `VariantRef` Fields
- **In `src/pages/patientView/mutation/AskMuseFloatingWindow.tsx`**:
  - Remove `.slice(0, 50)` truncation so all sample mutations are included.
  - Extract the real HGVS `variant_id` from `store.streamingAlphaGenomeAnnotations` / `store.indexedAlphaGenomeAnnotations.result` (keyed by `${m.chr},${m.startPosition},${m.endPosition},${m.referenceAllele},${m.variantAllele}` $\rightarrow$ `ann?.variant`) with deterministic fallback `${m.chr}:g.${m.startPosition}${m.referenceAllele}>${m.variantAllele}`.
  - Map each mutation to snake_case fields matching `VariantRef`:
    ```ts
    {
        variant_id: variantId,
        hugo_symbol: m.gene?.hugoGeneSymbol || m.hugoGeneSymbol || 'UNKNOWN',
        protein_change: m.proteinChange || null,
    }
    ```
- **In `app/copilot_router.py`**:
  - Also accept camelCase fallbacks (`hugoGeneSymbol`, `proteinChange`, `variantId`) in `VariantRef` so both snake_case and camelCase payloads work seamlessly.

### Fix 3 (Critical — `AskMuseFloatingWindow.tsx` & `copilot_router.py`): Resolve OncoTree Code (`study.cancerTypeId`) & Support Full Name / Message Lookup
- **In `src/pages/patientView/mutation/AskMuseFloatingWindow.tsx`**:
  - Prioritize the OncoTree code `study.cancerTypeId || study.cancerType?.shortName || study.cancerType?.name || ''` so `PAAD` is sent instead of `"Pancreatic Adenocarcinoma"`.
- **In `app/sample_trainer.py` & `app/copilot_router.py`**:
  - Match `cancer_type` by exact OncoTree code key (`PAAD`, `PANET`, etc.) OR case-insensitive `oncotree_name` (`"Pancreatic Adenocarcinoma"`), AND scan `request.message` for any known OncoTree code token (e.g. if the user types `"Find mapping for PANET"` in chat while viewing a `PAAD` study).
  - Include `"oncotree_name": entry.get("oncotree_name", "")` inside `suggested_mapping` so clicking `💾 Save Mapping` preserves `oncotree_name`.

### Fix 4 (High — `sample_trainer.py`): Live MongoDB Join via `pymongo` OR `docker exec gn-mongo mongosh` Fallback + `_id` Primary Key Lookup
- **In `app/sample_trainer.py`**:
  - Query `"_id"` first in `query_keys = ("_id", "variant", "hg38_variant", "variant_id")` and reuse a module-level cached `MongoClient` instead of creating a new client per variant.
  - When `pymongo` is not installed in the Python environment, automatically fall back to querying `gn-mongo` via `subprocess.check_output(["docker", "exec", "gn-mongo", "mongosh", "--quiet", "--eval", ...])` (matching `pipeline_monitor.py`) so `copilot_health()` reports the real `mongo_cached_count > 0` and `index_patient_sample` populates real `scores`, `top_tracks`, `hg38_variant`, and `merged_splicing_score` from `annotator.alphagenome.annotation`!
  - Unwrap nested `annotation` dict if present (`inner = doc.get("annotation") if isinstance(doc.get("annotation"), dict) else doc`) before extracting `scores`, `canonical_gene`, `hg38_variant`, `score_level`, and `merged_splicing_score`.

### Fix 5 (High — `sample_trainer.py`): Prevent False-Positive `sidecar_error` in `inspect_batch_failures`
- **In `app/sample_trainer.py`**:
  - Only flag `absent_from_mongo` as a failure when MongoDB is actually reachable (`mongo_reachable() is True`) AND the variant is missing from `annotator.alphagenome.annotation` (or has explicit `FAILED`/`ERROR`/`REJECTED`/`MISMATCH` lines in the 5 MB log tail). Never report cached or unqueried variants as `sidecar_error` when Mongo is offline.

### Fix 6 (High — `copilot_router.py`): Load `agentic-setup/.env` & Enrich `cross_reference_genes` + `prep_literature_context` With Real KB Data
- **In `app/copilot_router.py`**:
  - Load `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.env` via `dotenv.load_dotenv` (or manual key-value parser) and pass the relevant slice of `study_gene_knowledge_store.json` + `oncotree_to_uberon.json` into both `_wonder_reply` and `_fallback_reply`.
  - In `_fallback_reply`:
    - `cross_reference_genes`: Read `study_gene_knowledge_store.json` (`genes{}`) and format a real multi-bullet breakdown per gene showing indexed studies, sample variants, `hg38_variant`, `merged_splicing_score`, and top `UBERON` / `CL` tissue tracks (`RNA_SEQ`, `SPLICE_JUNCTIONS`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`).
    - `prep_literature_context`: Read the sample's entry from `study_gene_knowledge_store.json` (`samples[f"{study_id}::{case_id}"]`) and generate a structured **Study + Sample + Gene + Modality Literature Foundation Brief** listing each mutated gene, its dominant AlphaGenome modality (`RNA_SEQ` expression vs. `SPLICE_*`), top tissue track scores, and suggested PubMed/literature search terms.

### Fix 7 (Medium — `AskMuseFloatingWindow.tsx` & `sample_trainer.py`): UI Status Count, Button Label & Store Deduplication
- In `src/pages/patientView/mutation/PatientViewMutationsTab.tsx`: Render `🧬 Ask Muse` as the button label.
- In `src/pages/patientView/mutation/AskMuseFloatingWindow.tsx`: Use `const count = data.indexed_count ?? (Array.isArray(data.genes_indexed) ? data.genes_indexed.length : '?'); setIndexStatus(\`Indexed \${count} variant(s)\`);`.
- In `app/sample_trainer.py`: Deduplicate `gene_entry["variants"]` by `(study_id, case_id, variant_id)` (updating in place) and update JSONL records if previously empty `top_tracks` now have real MongoDB tracks.

---

## 2. Launch Command for Meta Muse Code Remediation & Re-Verification (`WS-09.R`)

```bash
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon

# 1. Export Pinned Toolchains & Central .env
set -a
source "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.env"
set +a
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:$JAVA_HOME/bin:/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin:/opt/homebrew/bin:$PATH"

# 2. Launch Meta Muse Code Multi-Agent Remediation Pass
agentic-setup/bin/muse \
  --trust-workspace \
  --provider meta \
  --contributor-mode off \
  --reasoning-effort high \
  --workspace "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace" \
  "You are the Muse Multi-Agent Orchestrator executing the WS-09.R Remediation & Re-Verification pass documented in workspace/workstreams/handoff_plan_5_muse_wonder_copilot.md.
Fix all 7 audit findings across workspace/alphagenome-sidecar (branch w6-muse-copilot) and workspace/cbioportal-frontend (branch w6-muse-copilot), then re-run full E2E verification against live gn-mongo:

1. SIDECAR REMEDIATION (workspace/alphagenome-sidecar on w6-muse-copilot):
   - Fix 4 (Live MongoDB Join in app/sample_trainer.py):
     * Query '_id' first in query_keys = ('_id', 'variant', 'hg38_variant', 'variant_id') and cache the pymongo client at module level.
     * Add a docker exec gn-mongo mongosh fallback (using subprocess.check_output(['docker', 'exec', 'gn-mongo', 'mongosh', '--quiet', '--eval', ...])) when pymongo is unavailable so _mongo_cached_count() and fetch_annotation(variant_id) read real documents from gn-mongo (annotator.alphagenome.annotation).
     * Unwrap nested 'annotation' dict if present (inner = doc.get('annotation') if isinstance(doc.get('annotation'), dict) else doc) so scores, canonical_gene, hg38_variant, score_level, and merged_splicing_score are populated into study_gene_knowledge_store.json and muse_wonder_training_samples.jsonl.
   - Fix 5 (inspect_batch_failures in app/sample_trainer.py):
     * Only mark absent_from_mongo as a failure when MongoDB is reachable and the variant is actually missing from annotator.alphagenome.annotation, or when explicit FAILED/ERROR/REJECTED/MISMATCH log lines exist in the last 5 MB of alphagenome_pipeline_debug.log.
   - Fix 7b (Deduplication in app/sample_trainer.py):
     * Deduplicate gene_entry['variants'] by (study_id, case_id, variant_id) and rewrite/update existing JSONL records when a previously empty record now has real MongoDB top_tracks.
   - Fix 1, 2, 3 & 6 (app/copilot_router.py):
     * Load agentic-setup/.env automatically.
     * In VariantRef, accept both snake_case (variant_id, hugo_symbol, protein_change) and camelCase aliases (variantId, hugoGeneSymbol, proteinChange).
     * In ChatRequest, accept both action_type and action, normalizing 'chat' or '' to None.
     * In map_oncotree, match cancer_type by OncoTree code key OR case-insensitive oncotree_name, and also scan request.message for any OncoTree code token (e.g. PANET, PAAD, SKCM). Include 'oncotree_name' in suggested_mapping.
     * In cross_reference_genes and prep_literature_context, read study_gene_knowledge_store.json and return a rich, multi-bullet summary of the indexed genes, hg38_variant, merged_splicing_score, and top UBERON/CL tracks per output_type.
   - Add unit tests in tests/test_copilot.py covering camelCase VariantRef, action alias, message OncoTree code detection, variant deduplication, and rich KB formatting. Run pytest -v.

2. FRONTEND REMEDIATION (workspace/cbioportal-frontend on w6-muse-copilot):
   - Keep packages/react-mutation-mapper/ 100% untouched (0 diff).
   - In src/pages/patientView/mutation/PatientViewMutationsTab.tsx: set button text to '🧬 Ask Muse'.
   - In src/pages/patientView/mutation/AskMuseFloatingWindow.tsx:
     * Fix 1: Send action_type (null when free-text chat, or the quick-prompt action string when clicking a pill) in POST /copilot/chat.
     * Fix 2: Extract all mutations (remove .slice(0, 50)), resolve each mutation's variant_id from store.streamingAlphaGenomeAnnotations / store.indexedAlphaGenomeAnnotations.result (fallback to chr:g.startRef>Alt), and send snake_case {variant_id, hugo_symbol, protein_change}.
     * Fix 3: Prioritize OncoTree code: study.cancerTypeId || study.cancerType?.shortName || study.cancerType?.name || ''.
     * Fix 7a: Set indexStatus using data.indexed_count (number) instead of data.genes_indexed (array).
   - Run pnpm --filter react-mutation-mapper run test and npx tsc --noEmit -p tsconfig.json.

3. LIVE E2E VERIFICATION (Verifier Agent):
   - Start/reload uvicorn app.main:app on :8000.
   - Verify GET /copilot/health returns mongo_cached_count > 0 against live gn-mongo.
   - Index real cached variants (including 7:g.140453136A>T) via POST /copilot/index-sample and verify study_gene_knowledge_store.json and muse_wonder_training_samples.jsonl contain non-empty top_tracks from MongoDB.
   - Verify all 4 chat actions (map_oncotree, cross_reference_genes, show_batch_failures, prep_literature_context) and free-text chat, then update workspace/workstreams/reports/verification_report_ws09.md."
```
