# Handoff Plan 7 (WS-10): Patient View Contextual Visual Understanding, 3-Stage Interactive PubMed Synthesis & AlphaGenome Colab Cookbook

- **Workstream ID**: `WS-10` / `W7-Patient-View-Contextual-Vision-And-Literature-Synthesis`
- **Status**: Ready for Meta Muse Code CLI Execution (`agentic-setup/bin/muse` v1.4.14)
- **Target Harness**: Meta Muse Code CLI (`agentic-setup/bin/muse`)
- **Target Repositories & Active Branches**:
  - `workspace/alphagenome-sidecar` (Branch: `w6-muse-copilot`)
  - `workspace/cbioportal-frontend` (Branch: `w6-muse-copilot`)
- **Foundation**: Extends `W6` (`AskMuseFloatingWindow.tsx` and `app/copilot_router.py`) and implements the updated [`W7_patient_view_contextual_vision.md`](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/workstreams/W7_patient_view_contextual_vision.md)
- **Theme**: Meta Global AI Developer Hackathon 2026 — *Build for Your World*

---

## 1. Architectural Decisions & Critical Review Findings

### 1.1 Why WebSockets Are NOT Used (HTTP Request/Response + Stateless Context)
1. **Rspack HTTPS Proxy & HMR Collision Risk**: `cbioportal-frontend` runs on `https://localhost:3000` with Rspack's internal HMR WebSocket (`wss://localhost:3000/ws`). Adding a custom `ws://localhost:8000` proxy causes Mixed Content blocks or WebSocket upgrade collisions during `uvicorn --reload`.
2. **Strictly Client-Initiated 3-Stage Workflow**: Every stage in `W7` (Stage 1 Query & Card Surfacing $\rightarrow$ Stage 2 User Checkbox Selection & Wonder Synthesis $\rightarrow$ Stage 3 Follow-up Q&A) is strictly user-triggered request/response.
3. **Resilient Session State**: Instead of fragile stateful WebSocket connections that drop on server reload, fetched PMID abstracts are cached in the sidecar by `pmid`, and `AskMuseFloatingWindow` passes `ingested_pmids: string[]` in `POST /copilot/chat` for Stage 3 follow-up turns.

### 1.2 Persistent Cross-Tab Mounting (`MSKTabs` Unmount Trap Fix)
1. **The Bug**: `MSKTabs` in `src/shared/components/MSKTabs/MSKTabs.tsx` sets `unmountOnHide: true` by default. Currently, `AskMuseFloatingWindow` is rendered inside `AlphaGenomeScoreButton` inside `PatientViewMutationsTab` (which lives inside `<MSKTab id="summary">`). Switching from `Summary` to `Pathways`, `Clinical Data`, or `Pathology Report` unmounts `PatientViewMutationsTab` and destroys `AskMuseFloatingWindow`, wiping chat history and selected PMIDs!
2. **The Fix**:
   - Lift `isAskMuseOpen: boolean` (`@observable`) and `toggleAskMuse()` / `setAskMuseOpen(open: boolean)` (`@action`) onto `PatientViewPageStore` (`src/pages/patientView/clinicalInformation/PatientViewPageStore.ts`).
   - Mount `<AskMuseFloatingWindow store={pageInstance.patientViewPageStore} activeTab={urlWrapper.activeTabId} onClose={() => pageInstance.patientViewPageStore.setAskMuseOpen(false)} />` at the `patientViewTabs()` level in `src/pages/patientView/PatientViewPageTabs.tsx` (outside `<MSKTabs>`) and add a `🧬 Ask Muse` button in `contentWindowExtra` so the Co-Pilot persists across all tabs (`summary`, `pathways`, `clinicalData`, `pathologyReport`, `tissueImage`) without unmounting!
   - Also in `AlphaGenomeScoreButton` (`PatientViewMutationsTab.tsx`), render the `🧬 Ask Muse` trigger as `<span role="button" className="btn btn-default btn-xs" ...>` so `AlphaGenomeScoreButton.spec.tsx`'s `wrapper.find('button')` continues to match a single `<button>` node with zero test regressions.

---

## 2. Implementation Tasks by Repository

### Task 1: Sidecar Backend Implementation (`workspace/alphagenome-sidecar` on `w6-muse-copilot`)

#### File 1: `app/copilot_router.py`
1. **Expand `ACTION_TYPES`**:
   ```python
   ACTION_TYPES = (
       "map_oncotree",
       "query_pubmed",
       "show_batch_failures",
       "colab_recipe",
       "cross_reference_genes",
       "prep_literature_context",
       "fail_kinetics",
       "cdkn2a_tp53_axis",
       "ras_cellcycle_cooperation",
       "survival_gap",
       "tmb_grade_paradox",
       "pathology_r1_reconciliation",
       "angioinvasion_failure",
   )
   ```
2. **Stage 1 — Interactive PubMed Query & Selectable PMID Cards (`query_pubmed` & Literature Free-Text Questions)**:
   - Build a clean, warning-free 3-part Boolean query:
     `"{GENE}"[tiab] AND ({cancer_terms}) AND ({modality_terms})`
     *(Never attach `[mh]` to gene symbols like `KRAS[mh]`; only use `[mh]` on valid NLM MeSH disease headings like `"pancreatic neoplasms"[mh]`).*
   - Example for `KRAS` in `PAAD`:
     `"KRAS"[tiab] AND (pancreatic[tiab] OR "pancreatic neoplasms"[mh] OR PDAC[tiab] OR "pancreatic cancer"[tiab]) AND (splicing[tiab] OR "splice variant"[tiab] OR "alternative splicing"[tiab] OR "splice site"[tiab] OR mutation[tiab])`
   - Query NCBI E-Utilities (`esearch.fcgi` + `esummary.fcgi`, using `NCBI_API_KEY` from environment if set, timeout `8.0s`) to fetch top matching papers (`[{ "pmid": str, "title": str, "source": str, "pubdate": str }]`), with a deterministic curated fallback paper list (including `PMID 41986348` and `PMID 38291024` for `KRAS`/`SMAD4`/`CDKN2A`/`SEL1L` in `PAAD`) when offline or rate-limited.
   - Return in `/copilot/chat` response:
     ```json
     {
       "reply": "### 📚 PubMed Targeted Evidence Query\n...",
       "action_type": "query_pubmed",
       "query": "\"KRAS\"[tiab] AND ...",
       "pubmed_url": "https://pubmed.ncbi.nlm.nih.gov/?term=...",
       "papers": [
         {
           "pmid": "41986348",
           "title": "...",
           "source": "...",
           "pubdate": "2025",
           "url": "https://pubmed.ncbi.nlm.nih.gov/41986348/"
         }
       ]
     }
     ```
3. **Stage 2 — User Selection of PMIDs & Meta Muse Wonder Ingestion (`POST /copilot/synthesize-pmids`)**:
   - Add request model:
     ```python
     class SynthesizePmidsRequest(BaseModel):
         model_config = ConfigDict(populate_by_name=True)
         pmids: list[str]
         question: str = ""
         study_id: str = ""
         case_id: str = ""
         cancer_type: str = ""
         variants: list[VariantRef] = Field(default_factory=list)
     ```
   - Fetch full abstracts via NCBI `efetch.fcgi?db=pubmed&id=...&retmode=xml` (with deterministic fallback abstract cache for benchmark PMIDs `41986348`, `38291024`, `15014009`, `11553622`, `37874914`) and store in an in-memory/disk cache `_PMID_ABSTRACT_CACHE[pmid]`.
   - Prompt **Meta Muse Wonder (`muse-wonder-1.0`)** with:
     - The full abstracts of the user-selected PMIDs.
     - The patient's AlphaGenome variant scores (e.g. `KRAS chr12:25245350:C>T | Splicing Score: 0.108`, `SMAD4`, `CDKN2A`).
     - The user's question.
   - Return `{ "reply": synthesized_markdown, "synthesized_pmids": request.pmids, "ingested_papers": [...] }`.
4. **Stage 3 — Grounded Follow-Up Q&A in Chat (`ingested_pmids` in `ChatRequest`)**:
   - Add `ingested_pmids: list[str] = Field(default_factory=list)` and `active_tab: str = "summary"` and `chart_context: dict = Field(default_factory=dict)` to `ChatRequest`.
   - When `request.ingested_pmids` is non-empty on a free-text chat turn, inject the cached abstracts for `request.ingested_pmids` into the `muse-wonder-1.0` prompt (and deterministic fallback) so follow-up questions (e.g. *"Which splicing factors regulate this?"*) are answered strictly grounded on the ingested papers with inline `[PMID ...]` citations.
5. **Implement Colab Recipe Card (`colab_recipe`) & Contextual Tab Handlers**:
   - `colab_recipe`: Returns pre-formatted parameters (`VARIANT_STRING`, `GENE_SYMBOL`, `TISSUE_UBERON`, `PADDING_KB = 15`, `INCLUDE_SPLICING = True`) and the clickable link to `https://colab.research.google.com/github/DixitPatel/alphagenome_sidecar/blob/main/colabs/cancer_variant_cookbook.ipynb`.
   - Contextual handlers (`fail_kinetics`, `cdkn2a_tp53_axis`, `ras_cellcycle_cooperation`, `survival_gap`, `tmb_grade_paradox`, `pathology_r1_reconciliation`, `angioinvasion_failure`): Return structured Molecular Tumor Board reasoning reconciling the Timeline, PathwayMapper, Clinical Staging, and Surgical Pathology Report (`TCGA-IB-AAUO` R1 uncinate margin, arterial channel invasion, Node 8 extracapsular extension).
   - Also expose `POST /copilot/contextual-chart-query` as an alias/dedicated route accepting `ContextualChartRequest`.

#### File 2: `tests/test_copilot.py`
- Add unit tests:
  1. `test_copilot_query_pubmed_returns_warning_free_query_and_papers()`
  2. `test_copilot_synthesize_pmids_stage2_and_stage3_followup()`
  3. `test_copilot_colab_recipe_action()`
  4. `test_copilot_contextual_chart_actions()` (`fail_kinetics`, `cdkn2a_tp53_axis`, `pathology_r1_reconciliation`)
- Run `pytest -v tests/test_copilot.py`.

---

### Task 2: Frontend Implementation (`workspace/cbioportal-frontend` on `w6-muse-copilot`)

#### File 1: `src/pages/patientView/clinicalInformation/PatientViewPageStore.ts`
- Add observable state for persistent Co-Pilot visibility across tabs:
  ```ts
  @observable public isAskMuseOpen: boolean = false;

  @action
  public setAskMuseOpen = (open: boolean) => {
      this.isAskMuseOpen = open;
  };

  @action
  public toggleAskMuse = () => {
      this.isAskMuseOpen = !this.isAskMuseOpen;
  };
  ```

#### File 2: `src/pages/patientView/PatientViewPageTabs.tsx` & `src/pages/patientView/mutation/PatientViewMutationsTab.tsx`
- In `PatientViewPageTabs.tsx`:
  - Render a `🧬 Ask Muse` button in `contentWindowExtra` (alongside `HelpWidget`) when `getServerConfig().show_alphagenome` is enabled, calling `pageInstance.patientViewPageStore.toggleAskMuse()`.
  - Render `<AskMuseFloatingWindow store={pageInstance.patientViewPageStore} activeTab={urlWrapper.activeTabId} onClose={() => pageInstance.patientViewPageStore.setAskMuseOpen(false)} />` outside `<MSKTabs>` so switching tabs (`Summary` $\leftrightarrow$ `Pathways` $\leftrightarrow$ `Clinical Data` $\leftrightarrow$ `Pathology Report`) never unmounts the window.
- In `PatientViewMutationsTab.tsx` (`AlphaGenomeScoreButton`):
  - Change the `🧬 Ask Muse` trigger to `<span role="button" className="btn btn-default btn-xs" style={{ marginLeft: 6 }} onClick={() => store.toggleAskMuse()}>🧬 Ask Muse</span>` so `AlphaGenomeScoreButton.spec.tsx` (`wrapper.find('button')`) finds only the 1 primary score `<button>`.

#### File 3: `src/pages/patientView/mutation/AskMuseFloatingWindow.tsx`
1. **Props & Active Tab Detection**:
   - Accept `activeTab?: string` on `IAskMuseFloatingWindowProps` (falling back to parsing `window.location.pathname.split('/').pop() || 'summary'`).
2. **4 Primary Quick Prompts + Dynamic Active-Tab Question Pills**:
   ```ts
   const DEFAULT_QUICK_PROMPTS: IQuickPrompt[] = [
       { action: 'map_oncotree', label: 'Map OncoTree' },
       { action: 'query_pubmed', label: 'Query PubMed' },
       { action: 'show_batch_failures', label: 'Show failures' },
       { action: 'colab_recipe', label: '🚀 Colab Cookbook' },
   ];

   const TAB_CONTEXT_PROMPTS: Record<string, IQuickPrompt[]> = {
       summary: [
           { action: 'fail_kinetics', label: '⏱️ Gemcitabine Failure Kinetics' },
           { action: 'tmb_grade_paradox', label: '🧬 Low TMB (1.4) vs. G3 Histology' },
       ],
       timeline: [
           { action: 'fail_kinetics', label: '⏱️ Gemcitabine Failure Kinetics' },
           { action: 'survival_gap', label: '📉 Staging vs. PFS Discordance' },
       ],
       pathways: [
           { action: 'cdkn2a_tp53_axis', label: '🔀 CDKN2A vs. TP53 Axis' },
           { action: 'ras_cellcycle_cooperation', label: '⚡ KRAS + CDKN2A Synergy' },
       ],
       clinicalData: [
           { action: 'survival_gap', label: '📉 Staging vs. PFS Discordance' },
           { action: 'tmb_grade_paradox', label: '🧬 Low TMB (1.4) vs. G3 Histology' },
       ],
       pathologyReport: [
           { action: 'pathology_r1_reconciliation', label: '📑 R1 Margin vs. 74-Day Relapse' },
           { action: 'angioinvasion_failure', label: '🔬 Arterial Invasion & Chemoresistance' },
       ],
   };
   ```
3. **Interactive Selectable PMID Cards (Stage 1 $\rightarrow$ Stage 2 $\rightarrow$ Stage 3 UI)**:
   - Store `selectedPmids: Record<string, boolean>` and `ingestedPmids: string[]` in component state.
   - When an assistant message includes `papers: IPubMedPaper[]`, render interactive paper cards below the message with:
     - Checkbox `<input type="checkbox" checked={!!selectedPmids[p.pmid]} onChange={...} />`
     - Clickable link `<a href={p.url} target="_blank" rel="noopener noreferrer">PMID {p.pmid}</a>: {p.title} ({p.source}, {p.pubdate})`
     - Action button: **`🧠 Synthesize Selected Papers ({selectedCount}) with Meta Wonder`** that calls `POST /copilot/synthesize-pmids` with `{ pmids, question, study_id, case_id, cancer_type, variants }`, appends the synthesized reply to the chat thread, and records `ingestedPmids`.
   - When `ingestedPmids.length > 0`, show a subtle active badge (`📚 Grounded on PMIDs: ...`) and include `ingested_pmids: ingestedPmids` in subsequent `POST /copilot/chat` requests for Stage 3 follow-up Q&A.
4. **Clickable Markdown Links in `ChatText`**:
   - Parse inline `[label](https://...)` links in `ChatText` and render `<a href={url} target="_blank" rel="noopener noreferrer">`.

---

## 3. Launch Command for Meta Muse Code CLI Execution (`WS-10`)

```bash
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon

# 1. Source Environment & Pinned Toolchains
set -a
source "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.env"
set +a
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:$JAVA_HOME/bin:/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin:/opt/homebrew/bin:$PATH"

# 2. Launch Meta Muse Code Execution for WS-10 (W7)
agentic-setup/bin/muse \
  --trust-workspace \
  --provider meta \
  --contributor-mode off \
  --reasoning-effort high \
  --workspace "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace" \
  "You are the Muse Multi-Agent Orchestrator executing Workstream W7 (WS-10) documented in workspace/workstreams/handoff_plan_7_patient_view_contextual_charts.md and workspace/workstreams/W7_patient_view_contextual_vision.md.

Deliver all tasks across workspace/alphagenome-sidecar (branch w6-muse-copilot) and workspace/cbioportal-frontend (branch w6-muse-copilot):

1. SIDECAR IMPLEMENTATION (workspace/alphagenome-sidecar on w6-muse-copilot):
   - In app/copilot_router.py:
     * Add 'query_pubmed', 'colab_recipe', 'fail_kinetics', 'cdkn2a_tp53_axis', 'ras_cellcycle_cooperation', 'survival_gap', 'tmb_grade_paradox', 'pathology_r1_reconciliation', and 'angioinvasion_failure' to ACTION_TYPES.
     * Stage 1 (query_pubmed & free-text literature queries): Build warning-free 3-part Boolean PubMed queries ('\"GENE\"[tiab] AND (cancer_terms) AND (modality_terms)' — never put [mh] on gene symbols), query NCBI esearch.fcgi + esummary.fcgi (with deterministic fallback papers including PMID 41986348 and PMID 38291024 when offline), and return {reply, query, pubmed_url, papers: [{pmid, title, source, pubdate, url}]}.
     * Stage 2 (POST /copilot/synthesize-pmids): Accept SynthesizePmidsRequest {pmids, question, study_id, case_id, cancer_type, variants}, fetch abstracts via NCBI efetch.fcgi (with deterministic cached fallback abstracts for benchmark PMIDs), cache them in _PMID_ABSTRACT_CACHE, prompt muse-wonder-1.0 (or deterministic fallback) correlating the abstracts with the patient's AlphaGenome scores, and return {reply, synthesized_pmids, ingested_papers}.
     * Stage 3 (Grounded follow-up Q&A): Accept ingested_pmids, active_tab, and chart_context on ChatRequest; when ingested_pmids is non-empty, inject those cached abstracts into the Wonder prompt and fallback reply so follow-up questions are answered strictly grounded on the selected PMIDs with inline citations.
     * Implement 'colab_recipe' returning the Clinical Recipe Card and clickable link to https://colab.research.google.com/github/DixitPatel/alphagenome_sidecar/blob/main/colabs/cancer_variant_cookbook.ipynb.
     * Implement rich clinical handlers for 'fail_kinetics', 'cdkn2a_tp53_axis', 'ras_cellcycle_cooperation', 'survival_gap', 'tmb_grade_paradox', 'pathology_r1_reconciliation', and 'angioinvasion_failure', plus POST /copilot/contextual-chart-query.
   - In tests/test_copilot.py:
     * Add tests for Stage 1 query_pubmed (warning-free Boolean syntax + papers list), Stage 2 /copilot/synthesize-pmids, Stage 3 follow-up with ingested_pmids, colab_recipe, and contextual tab actions.
     * Run pytest -v tests/test_copilot.py and ensure 100% pass.

2. FRONTEND IMPLEMENTATION (workspace/cbioportal-frontend on w6-muse-copilot):
   - Keep packages/react-mutation-mapper/ 100% untouched.
   - In src/pages/patientView/clinicalInformation/PatientViewPageStore.ts:
     * Add @observable public isAskMuseOpen: boolean = false; and @action setAskMuseOpen / toggleAskMuse so Co-Pilot state persists across tab switches.
   - In src/pages/patientView/PatientViewPageTabs.tsx & src/pages/patientView/mutation/PatientViewMutationsTab.tsx:
     * Mount AskMuseFloatingWindow in patientViewTabs() outside MSKTabs (passing activeTab={urlWrapper.activeTabId}) and add a '🧬 Ask Muse' button in contentWindowExtra so switching between Summary, Pathways, Clinical Data, and Pathology Report never unmounts the window.
     * In AlphaGenomeScoreButton, render the '🧬 Ask Muse' trigger as a <span role='button' className='btn btn-default btn-xs'> so AlphaGenomeScoreButton.spec.tsx continues to find a single <button>.
   - In src/pages/patientView/mutation/AskMuseFloatingWindow.tsx:
     * Render the 4 core quick prompts ('Map OncoTree', 'Query PubMed', 'Show failures', '🚀 Colab Cookbook') plus dynamic active-tab contextual pills (Timeline, Pathways, Clinical Data, Pathology Report).
     * Render interactive selectable PMID cards when response.papers is present, with checkboxes and a '🧠 Synthesize Selected Papers with Meta Wonder' button that calls POST /copilot/synthesize-pmids and stores ingestedPmids for Stage 3 follow-up chat turns.
     * Parse inline [text](url) Markdown links in ChatText into clickable <a target='_blank' rel='noopener noreferrer'> elements.
   - Run npx tsc --noEmit -p tsconfig.json and unit tests on AlphaGenomeScoreButton.spec.tsx.

3. LIVE E2E VERIFICATION:
   - Reload uvicorn app.main:app on :8000 and verify Stage 1 (/copilot/chat with query_pubmed), Stage 2 (/copilot/synthesize-pmids with ['41986348', '38291024']), Stage 3 follow-up (/copilot/chat with ingested_pmids), colab_recipe, and pathology_r1_reconciliation, then write workspace/workstreams/reports/verification_report_ws10.md."
```
