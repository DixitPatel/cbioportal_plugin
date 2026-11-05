# Handoff Plan 6 — Pipeline Debugger: Failed-Only Default Logging

## Goal
Reduce log volume in `workspace/logs/alphagenome_pipeline_debug.log` (and stdout/SLF4J) by making verbose Phase 1–6 trace logging opt-in (`DEBUG_ENABLED = false` by default) while keeping regular failure logging always active for failed variants across all phases for post-mortem debugging.

---

## 1. Genome Nexus Backend (`workspace/genome-nexus`)

### A. Logger Utility
- **File**: [AlphaGenomePipelineDebugLogger.java](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus/component/src/main/java/org/cbioportal/genome_nexus/util/AlphaGenomePipelineDebugLogger.java)
- **Changes**:
  - Add `DEBUG_ENABLED` controlled by environment variable `ALPHAGENOME_DEBUG_LOGS=true` or JVM property `-Dalphagenome.debug.logs=true` (**default `false`**):
    ```java
    private static final boolean DEBUG_ENABLED =
        Boolean.parseBoolean(System.getProperty("alphagenome.debug.logs",
            System.getenv().getOrDefault("ALPHAGENOME_DEBUG_LOGS", "false")));
    ```
  - Gate `log(String phase, String message)` so it returns immediately when `!DEBUG_ENABLED`.
  - Add `logFailure(String phase, String message)` which always writes to `LOG.warn(...)`, `System.out.println(...)`, and `alphagenome_pipeline_debug.log` regardless of `DEBUG_ENABLED`.

### B. Failed-Variant Call Sites to Switch to `logFailure(...)`
All non-failure trace call sites remain on `AlphaGenomePipelineDebugLogger.log(...)`. Only the following failed-variant paths switch to `AlphaGenomePipelineDebugLogger.logFailure(...)`:

1. **[AlphaGenomeVariantNormalizer.java](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus/component/src/main/java/org/cbioportal/genome_nexus/component/annotation/AlphaGenomeVariantNormalizer.java)**:
   - Line 81 (`PHASE 1: PRE-FILTER`): `annotation is null -> REJECTED`
   - Line 102 (`PHASE 1: PRE-FILTER REJECTED`): `!isSuccessfullyAnnotated || errorMessage != null`
   - Line 112 (`PHASE 1: PRE-FILTER REJECTED`): null or empty coordinate field
   - Line 119 (`PHASE 1: PRE-FILTER REJECTED`): invalid or unmapped chromosome
   - Line 127 (`PHASE 1: PRE-FILTER REJECTED`): `alleleString` does not have 2 parts
   - Line 139 (`PHASE 1: PRE-FILTER REJECTED`): invalid `ref` or `alt`
   - Line 171 (`PHASE 2: LIFTOVER REJECTED`): unsupported assembly
   - Line 187 (`PHASE 2: LIFTOVER REJECTED`): low coordinate `< 1`
   - Line 193 (`PHASE 2: LIFTOVER REJECTED`): `liftOver` returned `null` or contig mismatch
   - Line 214 (`PHASE 2: GRCH38 REF CHECK`): `Grch38ReferenceSequenceResolver is null`
   - Line 268 (`PHASE 2: GRCH38 REF CHECK REJECTED`): GRCh38 REF check mismatch (`expectedRef != vcfRef`)
2. **[AlphaGenomeServiceImpl.java](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus/service/src/main/java/org/cbioportal/genome_nexus/service/internal/AlphaGenomeServiceImpl.java)**:
   - Line 72 (`PHASE 5: RESPONSE FROM ALPHAGENOME SIDECAR`): empty results list for variant
   - Lines 84, 88, 93, 133, 137, 142 (`PHASE 5: RESPONSE ERROR`): `ResourceMappingException`, `HttpClientErrorException`, and `ResourceAccessException` catches (single and batch)
3. **[CachedAlphaGenomeFetcher.java](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus/service/src/main/java/org/cbioportal/genome_nexus/service/cached/CachedAlphaGenomeFetcher.java)**:
   - Line 151 (`PHASE 5: RESPONSE ERROR`): sidecar chunk future exception
   - Line 157 (`PHASE 5: RESPONSE ERROR`): `rawValue` is `null` for chunk
   - Line 175 (`PHASE 5: RESPONSE ERROR`): transform / MongoDB cache write exception
4. **[AlphaGenomeAnnotationEnricher.java](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus/service/src/main/java/org/cbioportal/genome_nexus/service/enricher/AlphaGenomeAnnotationEnricher.java)**:
   - Lines 50, 76 (`PHASE 6: ENRICHER ERROR`): `AlphaGenomeWebServiceException` catches
   - Line 54 (`PHASE 6: ENRICHER`): `AlphaGenomeNotFoundException` catch

---

## 2. AlphaGenome Sidecar (`workspace/alphagenome-sidecar`)

### A. Logger Module
- **File**: [logger.py](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar/app/logger.py)
- **Changes**:
  - Add `DEBUG_ENABLED = os.environ.get("ALPHAGENOME_DEBUG_LOGS", "false").lower() in ("1", "true", "yes")` (**default `False`**).
  - Gate `log_debug(phase: str, message: str)` so it returns immediately when `not DEBUG_ENABLED`.
  - Add `log_failure(phase: str, message: str)` which always writes to `logger.warning(...)`, stdout, and `alphagenome_pipeline_debug.log`.

### B. Failed-Variant Call Sites to Switch to `log_failure(...)`
All other trace calls remain on `log_debug(...)`:
1. **[scoring.py](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar/app/scoring.py)**:
   - Line 96 (`PHASE 4: API KEY CHECK`): `ALPHA_GENOME_API_KEY is NOT set in environment!`
   - Lines 134, 138 (`PHASE 4: SIDECAR ERROR`): upstream and client exceptions during `score_variant`
2. **[main.py](file:///Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar/app/main.py)**:
   - Line 43 (`PHASE 4: SIDECAR RATE LIMITED`): HTTP 429 rate-limit error
   - Line 46 (`PHASE 4: SIDECAR UPSTREAM UNAVAILABLE`): HTTP 503 upstream error
   - Line 49 (`PHASE 4: SIDECAR UNEXPECTED ERROR`): HTTP 500 unexpected error
