# Workstream Task C: Scaling Strategy, Lazy Caching & Concurrency (`scaling-performance-caching`)

- **Task ID**: `Task-C` (Approval-gated sub-steps `C.1` – `C.5`)
- **Skill**: `genome-nexus-enricher`, `cbioportal-annotation-cell`, `alphagenome-sidecar`, `tdd`, `code-review`
- **Target Repositories**:
  - `workspace/genome-nexus` (Lazy Cache Lookup & 16-Worker Concurrency)
  - `workspace/alphagenome-sidecar` (Async I/O & Singleton gRPC Channel)
  - `workspace/cbioportal-frontend` (Single-Trigger Batch Ingestion & Progressive UI Hydration)
- **Live Ports**: Genome Nexus Backend (`:38080`), MongoDB (`:27017`), AlphaGenome Sidecar (`:8000`), cBioPortal Frontend (`:3000`)
- **Language / Stack**: Java 11 / Spring Boot / MongoDB / Python 3.13 / FastAPI / TypeScript / React / MobX

---

## 1. Executive Summary & Precise Objectives

AlphaGenome transformer inference over a 1 Mb sequence context requires $500\text{ ms}$ to $2.5\text{ s}$ per variant. Sequential cold scoring for clinical cohorts (e.g. 158 variants in TCGA PAAD) would stall page loads for ~4 minutes and trigger 504 gateway timeouts.

To achieve production scale without the operational complexity and synchronization overhead of multi-tier in-memory caches, this plan implements a streamlined, high-throughput architecture:
1. **Sidecar Async I/O (Approach A) & Singleton `DnaClient`**: FastAPI `async def` with `asyncio.to_thread` and persistent gRPC channel reuse.
2. **Backend Concurrency Scaled to 16 Threads**: Increase `CachedAlphaGenomeFetcher` thread pool from 4 to 16 parallel workers with `@PreDestroy` shutdown handler.
3. **Client-Side Single Trigger & Progressive Background Queue**: Zero compute on initial page load; user clicks `[ ⚡ Score AlphaGenome ]` to pace background batches of 16 variants into MobX, maintaining strict DOM and tooltip stability.
4. **Dedicated Debugger Agent**: Standing monitor (`.muse/agents/debugger.md`) diagnosing Phase 1–7 logs in real time.
*(Note: Lazy normalization bypassing liftover on cache hits has been deferred/removed for now per project direction).*

---

## 2. Architecture Blueprint

```mermaid
flowchart TD
    subgraph Frontend ["1. cBioPortal Frontend (:3000)"]
        Load["Page Load: Table Renders in < 300 ms<br/>(AlphaGenome Column Shows 22px Placeholders)"]
        Trigger["User Clicks '[ ⚡ Score AlphaGenome ]'"]
        Queue["Default Background Batch Queue<br/>(Paces 16 Variants / Request)"]
        Hydrate["Incremental MobX Hydration<br/>(In-Place 22px Spinner -> αG Badge)"]
        Load --> Trigger --> Queue --> Hydrate
    end

    subgraph Backend ["2. Genome Nexus Backend (:38080)"]
        MongoFirst{"1. Check MongoDB<br/>alphagenome.annotation"}
        MongoHit["Cache Hit (< 1 ms)<br/>Return Cached Document"]
        MongoMiss["Cache Miss:<br/>Run Liftover & FASTA RefCheck"]
        Pool["CachedAlphaGenomeFetcher<br/>16-Worker Thread Pool"]
        MongoFirst -- Hit --> MongoHit
        MongoFirst -- Miss --> MongoMiss --> Pool
    end

    subgraph Sidecar ["3. AlphaGenome Sidecar (:8000)"]
        AsyncEP["async def score_variant (Approach A)<br/>await asyncio.to_thread"]
        Singleton["Singleton DnaClient (@lru_cache)<br/>Warm gRPC Channel Multiplexed over HTTP/2"]
        Model["AlphaGenome Model Inference (DeepMind)"]
        AsyncEP --> Singleton --> Model
    end

    Queue -->|POST /annotation/genomic (Batch of 16)| MongoFirst
    Pool -->|16 Concurrent POSTs /score| AsyncEP
    Hydrate -.->|Hover Badge| Tooltip["DefaultTooltip Overlay (RC-Portal)<br/>100% Isolated & Uninterrupted"]
```

---

## 3. Core Architectural Components

### 3.1 Sidecar Async I/O (Approach A) & Singleton `DnaClient`
- **Singleton Channel Reuse**:
  - Wrap `get_client()` in `app/main.py` with `@lru_cache(maxsize=1)`.
  - Reuses a single `grpc.secure_channel` across all requests, eliminating 150–300 ms of TLS connection setup per variant.
- **Non-Blocking Event Loop**:
  - `POST /score` is declared `async def score_variant`.
  - The blocking gRPC network call and Pandas post-processing are delegated via `await asyncio.to_thread(scoring.score_with_client, request, client)`.
  - FastAPI’s event loop stays non-blocking, accepting incoming requests without connection starvation.

### 3.2 Backend Concurrency Scaled to 16 Worker Threads
- In `CachedAlphaGenomeFetcher.java`, set `@Value("${alphagenome.sidecar.max_concurrency:16}")`.
- In `web/src/main/resources/application.properties`, configure `alphagenome.sidecar.max_concurrency=16`.
- Add `@PreDestroy public void shutdown()` to ensure the thread pool cleanly terminates on Spring shutdown.
- Sizing the fetch pool to 16 allows Genome Nexus to process uncached batches in parallel, matching the sidecar's asynchronous capacity.

### 3.3 Client-Side Single Trigger & Progressive Background Queue
- **Decoupled Page Load**:
  - `indexedAlphaGenomeAnnotations` does not auto-fire on page load. The mutations table, protein lollipop plot, and OncoKB badges render in $< 300\text{ ms}$.
- **Single User Trigger**:
  - Toolbar button: `[ ⚡ Score AlphaGenome ]`.
  - On click, transitions to `[ ⟳ Scoring AlphaGenome (16/158)... ]`.
- **Default Background Batch Queue**:
  - Client partitions the cohort into batches of 16 variants.
  - Sequentially dispatches batches to Genome Nexus, updating MobX incrementally.
- **In-Place Loading Spinner**:
  - `AlphaGenomeCell` renders `loaderIcon('pull-left')` for in-flight variants.
- **Page Stability Guarantees**:
  - **Zero Layout Shifts**: `.annotation-item` is pinned to `width: 22px`. Cells hydrate in-place without column jitter.
  - **Locked Row Order**: Row positions stay locked during streaming; rows do not jump under the user's cursor.
  - **Tooltip Integrity**: `DefaultTooltip` mounts via an isolated portal on `document.body`. Hovering over one variant is never closed or interrupted when background batches land.

### 3.4 Standing Debugger Agent & Live Log Monitoring
- Dedicated agent (`.muse/agents/debugger.md`) monitors `alphagenome_pipeline_debug.log`, `genome_nexus_backend.log`, and `alphagenome_sidecar.log` concurrently.
- Uses `agentic-setup/bin/pipeline_monitor.py` (`--status`, `--test`, `--cbio`, `--watch`, `--tail`) to provide instant root-cause diagnostics to collaborating agents.

---

## 4. Approval-Gated Implementation Plan

### Step `C.1`: Sidecar Async I/O (Approach A) & Singleton Channel
- **Target**: `workspace/alphagenome-sidecar` (`app/main.py`)
- **Action**:
  1. Apply `@lru_cache(maxsize=1)` to `get_client()` for persistent gRPC channel reuse.
  2. Define `@app.post("/score")` as `async def score_variant(...)` wrapping execution in `await asyncio.to_thread(...)`.
  3. Run sidecar pytest test suite.
- **Done When**: All 23 tests pass in `workspace/alphagenome-sidecar` (`pytest -v`).

### Step `C.2`: Configure 16-Worker Concurrency Pool & Clean Shutdown
- **Target**: `workspace/genome-nexus` (`CachedAlphaGenomeFetcher.java`, `application.properties`)
- **Action**:
  1. Set `alphagenome.sidecar.max_concurrency=16` in `application.properties`.
  2. Set `@Value("${alphagenome.sidecar.max_concurrency:16}")` in `CachedAlphaGenomeFetcher.java`.
  3. Add `@PreDestroy public void shutdown()` to ensure the thread pool cleanly terminates on Spring shutdown.
- **Done When**: Unit tests verify 16 concurrent worker tasks dispatch cleanly.

### Step `C.3`: Frontend Decoupled Trigger & Background Batch Queue
- **Target**: `workspace/cbioportal-frontend` (`ResultsViewPageStore.ts`, `Annotation.tsx`, `AlphaGenome.tsx`, `ResultsViewMutationMapper.tsx`)
- **Action**:
  1. Add observable `isAlphaGenomeTriggered`, `isAlphaGenomeScoring`, and `triggerAlphaGenomeScoring()` action in `ResultsViewPageStore.ts`.
  2. Update `indexedAlphaGenomeAnnotations` to be decoupled from initial page load.
  3. Implement client background batch queue (dispatching 16 variants per chunk).
  4. Render `[ ⚡ Score AlphaGenome ]` action button in the mutation table toolbar (`customControls`).
  5. Add `status` prop to `AlphaGenomeCell` to render `loaderIcon('pull-left')` during in-flight chunks.
- **Done When**: Table loads instantly on cold start; clicking the trigger hydrates rows progressively without layout shifts.

### Step `C.4`: Debugger Agent Live Monitoring & Triage
- **Target**: `workspace/.muse/agents/debugger.md`, `agentic-setup/bin/pipeline_monitor.py`
- **Action**:
  1. Register Debugger Agent in `.muse/agents/debugger.md` and `workspace/AGENTS.md`.
  2. Support real-time queries from Planner, Implementer, and Tester regarding Phase 1–7 execution and dual-gate evaluation.
- **Done When**: Debugger diagnoses any test failure or empty visual cell with phase-specific root cause.

### Step `C.5`: End-to-End Benchmark & Verification
- **Target**: Stack verification across `:38080`, `:8000`, `:3000` via `pipeline_monitor.py`
- **Action**:
  1. Verify daemon health: `pipeline_monitor.py --status`.
  2. Test cold & warm scoring: `pipeline_monitor.py --test "7:g.140453136A>T"`.
  3. Verify dual-gate cell evaluation: `pipeline_monitor.py --cbio "7:g.140453136A>T" --cancer-type PAAD`.
  4. Audit pipeline debug trace: `pipeline_monitor.py --tail 50` (assert 0 unhandled errors).
- **Done When**: End-to-end trace log confirms 0 errors and benchmark achieves $>95\%$ warm latency reduction.

---

## 5. Verification & Benchmark Commands

```bash
# 1. Run Sidecar Unit Tests (Approach A Async I/O)
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar
/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v

# 2. Run Genome Nexus Service Tests
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus
mvn test -pl service -Dtest=CachedAlphaGenomeFetcherTest,AlphaGenomeServiceImplTest -B

# 3. Test 16-Worker Live Concurrency via Sidecar
curl -s http://localhost:8000/health | jq .
curl -s "http://localhost:38080/annotation/7:g.140453136A%3ET?fields=alpha_genome" | jq .
```
