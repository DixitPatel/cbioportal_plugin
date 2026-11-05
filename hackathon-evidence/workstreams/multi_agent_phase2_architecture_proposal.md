# Phase 2 Multi-Agent Architecture & Orchestration Proposal for Muse

**Project**: Genome Nexus, AlphaGenome & cBioPortal Integration  
**Role of This Session**: Pure Agent Definition & Documentation Proposal for Muse (Zero application code changes)  
**Target Harness**: Meta Muse Code CLI (`agentic-setup/bin/muse` v1.4.13)  
**Compliance Mode**: Standard Mode (`--contributor-mode off` — never train models on AlphaGenome outputs or NCBI text)

---

## 1. Executive Summary: The Phase 1 to Phase 2 Transition

| Milestone | Scope & Philosophy | Governance |
| :--- | :--- | :--- |
| **Phase 1 (The Bedrock)** | Established baseline services, liftover normalization, DeepMind AlphaGenome transformer inference, MongoDB caching, cBioPortal dual-gate mutations table cells, and unified telemetry (`alphagenome_pipeline_debug.log`). | Verified foundational contracts, ports, schemas, and end-to-end connectivity. |
| **Phase 2 (The Multi-Agent Engine)** | Orchestrates autonomous specialized agents to deliver high-throughput scaling, concurrency, async streaming, and automated validation without manual code modification. | Governed by contract schemas (`alpha_genome_schema.json`, `sidecar_openapi.yaml`) and evaluated by the **Verifier Agent**. |

> [!IMPORTANT]
> **Strict Non-Implementation Boundary**: No application code is modified in this session. Phase 2 starts from fixed, locked base references (`w2-sidecar`, `w3-enricher`, `w4-annotation-cell`). Stashes will not be referred to or used; the multi-agent pipeline implements code natively from the workstream specifications and contract schemas.

---

## 2. The 7-Agent Autonomous Roster

Seven specialized agents are defined in `workspace/.muse/agents/`, enabling clean separation of concerns, sandbox boundary enforcement, and real-time observability:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    MUSE ORCHESTRATOR                                        │
│                   workspace/.muse/agents/ · agentic-setup/bin/muse                          │
└──────────────┬───────────────────────────────┬──────────────────────────────┬───────────────┘
               │                               │                              │
        ┌──────▼───────┐                ┌──────▼───────┐               ┌──────▼───────┐
        │ 1. PLANNER   │                │ 2. IMPL      │               │ 3. TESTER    │
        │ Breaks specs │───────────────►│ Sandboxed    │──────────────►│ Native tool- │
        │ into atomic  │                │ repository   │               │ chains, zero │
        │ repo tasks   │                │ code author  │               │ regressions  │
        └──────────────┘                └──────┬───────┘               └──────┬───────┘
                                               │                              │
                                               │        ┌──────────────┐      │
                                               ├───────►│ 4. REVIEWER  │◄─────┘
                                               │        │ Schema & diff│
                                               │        │ auditor      │
                                               │        └──────┬───────┘
                                               │               │
                                               │        ┌──────▼───────┐
                                               │        │ 5. PR AGENT  │
                                               │        │ Squash & PR  │
                                               │        │ description  │
                                               │        └──────────────┘
                                               │
┌──────────────────────────────────────────────┴──────────────────────────────────────────────┐
│                                STANDING SPECIALIZED AGENTS                                  │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6. DEBUGGER AGENT (.muse/agents/debugger.md · bin/muse-debugger)                            │
│    • Real-time passive telemetry monitor; tails alphagenome_pipeline_debug.log              │
│    • Answers inter-agent questions regarding Phase 1-7 liftover / normalization anomalies   │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ 7. VERIFIER AGENT (.muse/agents/verifier.md · bin/muse-verify)                              │
│    • Authoritative active evaluation arbiter; verifies critical sections (Tasks A, B, C)   │
│    • Benchmarks cohort performance (TCGA PAAD 158 variants) & generates explanatory reports │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Critical Sections Verified by the Verifier Agent

The **Verifier Agent** ([`.muse/agents/verifier.md`](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/.muse/agents/verifier.md)) acts as the gatekeeper across three core workstream areas:

### Task A: Genomic Normalization & Liftover Safety
1. **VEP Parsing & Indel Anchoring**: Verifies the Tan et al. (2015) parsimonious left-alignment algorithm, ensuring seed positions for insertions/deletions are anchored with GRCh38 bases and immune to spurious 3'-homopolymer shifting.
2. **GRCh38 FASTA `REF` Base Check**: Verifies strict rejection of variants whose reported `REF` base mismatches the human genome *before* sidecar dispatch or MongoDB cache persistence, preventing silent hallucinated score contamination.
3. **cBioPortal UI Data View Spinner**: Verifies that in-flight asynchronous variant requests render an active `loaderIcon('pull-left')` instead of an empty 22px slot.

### Task B: Sidecar Logic & Canonical Gene Tidy
1. **Receptive Interval Bounds**: Verifies symmetric 1 Mb context window centering ($\pm 524,288\text{ bp}$) with chromosome boundary guarding (`start \ge 0`).
2. **OpenAPI 3.0 Contract Conformance**: Validates Pydantic schemas for `ScoreRequest` and `ScoreResponse` against `contracts/sidecar_openapi.yaml`.
3. **Canonical Gene Tidy Filtering**: Verifies reduction of 35,000 raw tensor rows down to canonical gene tracks (~150–250 rows, $< 80\text{ KB}$), protecting against MongoDB 16 MB BSON document limits.
4. **Merged Splicing Score**: Verifies mathematical composite formula:
   $$\max(\text{SPLICE\_SITES}) + \max(\text{USAGE}) + \frac{\max(\text{JUNCTIONS})}{5}$$
5. **UBERON Ontology Mapping**: Validates OncoTree-to-UBERON tissue crosswalks against `oncotree_to_uberon.json`.

### Task C: Scaling Strategy, Concurrency & Caching
1. **Sidecar Async I/O**: Verifies FastAPI `/score` non-blocking event loop execution via `await asyncio.to_thread` and persistent gRPC channel reuse via `@lru_cache(maxsize=1)`.
2. **Genome Nexus 16-Worker Concurrency**: Verifies `CachedAlphaGenomeFetcher` parallel thread pool and `@PreDestroy` graceful shutdown handler.
3. **Client Decoupled Trigger & Background Queue**: Verifies instant initial table load ($< 300\text{ ms}$), toolbar action `[ ⚡ Score AlphaGenome ]`, and progressive 16-variant chunk dispatch.
4. **DOM Stability & Tooltip Integrity**: Asserts pinned 22px `.annotation-item` width, zero horizontal layout jitter, locked row positions, and unperturbed tooltip hovers.

---

## 4. Benchmark Cohort & SLA Specifications

The Verifier Agent runs an automated performance audit on the canonical benchmark cohort:
- **Study**: TCGA Pancreatic Adenocarcinoma (`paad_tcga_pan_can_atlas_2018`)
- **Genes**: `KRAS`, `TP53`, `SMAD4`, `CDKN2A`
- **Total Rows**: 301 mutation rows
- **Unique Genomic Variants**: **158 unique variants**
- **Tissue Context**: `UBERON:0001264` (`pancreas`) + tissue-agnostic `SPLICE_SITES`

### Performance SLAs Evaluated by Verifier
1. **Cold Cache-Miss Stress Test**:
   - Total 158-variant cohort duration: $\le 25.0\text{ s}$ across 16 concurrent workers (vs. ~240s sequential baseline).
   - Throughput: $\ge 6.0\text{ variants/second}$.
   - Batch Latency: $p50 \le 2.0\text{ s}$, $p95 \le 3.5\text{ s}$.
   - Error Rate: $0.0\%$ unhandled exceptions or 504 timeouts.
2. **Warm Cache-Hit SLA**:
   - Total cohort re-query: $< 300\text{ ms}$ ($< 10\text{ ms}$ per 16-variant batch).
   - Cache hit rate: $100.0\%$ in MongoDB `annotator.alphagenome.annotation`.

---

## 5. Ready-to-Run Muse Tooling Suite

| CLI Command | Purpose | Target Agent |
| :--- | :--- | :--- |
| `agentic-setup/bin/muse` | Core interactive / headless multi-agent harness | Planner, Implementer, Tester, Reviewer |
| `agentic-setup/bin/muse-debugger` | Live trace log tailing and Phase 1–7 diagnosis | Standing Debugger Agent |
| `agentic-setup/bin/muse-verify` | Critical section verification, cohort benchmark, and report generation | Standing Verifier Agent |
| `agentic-setup/bin/muse-pr` | Commit history analysis, squashing, style alignment, and PR staging | PR Agent |

---

## 6. Explanatory Verification Report Mandate

The Verifier Agent outputs a formal markdown report to `workspace/workstreams/reports/verification_report_<timestamp>.md` containing:
1. Executive Certification Status (`CERTIFIED PASS`, `CONDITIONAL PASS`, `BLOCKED`).
2. Audit Matrix for Tasks A, B, and C with exact pass/fail and empirical evidence.
3. Cohort Performance Metrics ($p50, p95, p99$, throughput, cache hit rate).
4. Dual-Gate Clinical Evaluation Results.
5. Concrete remediation steps for any failing section before PR approval.
