# Comment Hygiene Catalog — AlphaGenome workstream (W1–W5, Task C, 546da921c)

Survey of every comment added by the work-branch diffs, each with a shorter,
crisp, exact-purpose replacement. Nothing applied yet — this is the review copy.
Conventions kept per repo: `//` lowercase + JSDoc in TS, `//` in Java, `#` +
`"""` in Python.

Scope: `55ec2bc50..HEAD` (cbioportal-frontend, generated client excluded),
`42b80a2..w3-enricher` (genome-nexus, whitespace-only ac751b6 skipped),
`origin/master..w5-variant-page` (genome-nexus-frontend),
`origin/main..w2-sidecar` (alphagenome-sidecar, app/ + tests/ only).
Out of scope: `alphagenome@559431d` docstring touch-up (mainline, not a work branch),
annotation-pipeline (no local work commits), uncommitted local dev config.

## 1. cbioportal-frontend (31 comments, 6 KEEP)

### packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.spec.tsx

- L104
  - was: `// react-table v6 reuses the cell instance by position on sort, so the mounted tissue selection can belong to the previous row's mutation. The cell must fall back to the new annotation's tissues, not blank.`
  - use: `// Cells persist across sorts; stale tissue must fall back.`
- L151
  - was: `// The tooltip tissue selector must not write back into the cell: picking a failing tissue blanked the icon, removing the only way to reopen the tooltip.`
  - use: `// Tooltip selection must not blank the reopening icon.`

### packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.tsx

- L27
  - was: `/** Dual-gate UI label (project-defined thresholds): a score only counts when |quantile_score| >= 0.99 AND the raw score passes its minimum ... */`
  - use: `/** Strong/moderate label needs |quantile| >= 0.99 plus raw-score threshold. */`
- L62 — KEEP (already purpose-based: what `alphaGenomeLabel` computes).
- L230
  - was: `// Tissue exploration is local to the open tooltip and never writes back to the table cell: picking a tissue with no passing score must not blank the row's icon (the only way to reopen the tooltip).`
  - use: `// Tooltip tissue choice stays local; never blanks the cell icon.`
- L236
  - was: `// Derive the effective tissue at render time: after a table sort the same component instance can receive a different mutation, so a stored selection that is no longer in this annotation must fall back instead of yielding an empty label/tooltip.`
  - use: `// Fall back when a stored tissue is absent post-sort.`
- L364
  - was: `// The icon label is stable: it follows the study tissue (or the best tissue overall), never the tooltip's transient exploration selection, so exploring a tissue with no passing score cannot blank the row.`
  - use: `// Icon follows study tissue, never transient tooltip selection.`
- L371
  - was: `// While a background scoring queue is in flight, hold the pinned 22px slot with an in-place spinner instead of an empty placeholder.`
  - use: `// Hold the 22px slot with a spinner while scoring.`

### packages/react-mutation-mapper/src/component/alphagenome/oncotreeToUberon.ts

- L1 — KEEP (contract provenance: mirrors `workstreams/contracts/oncotree_to_uberon.json`).

### packages/react-mutation-mapper/src/component/column/Annotation.retrigger.spec.ts

- L84
  - was: `// Same mutation, retriggered fetch with cache clear (e.g. fresh Mongo cache content refetched). The column picks up the new payload.`
  - use: `// Refetch after cache clear surfaces the fresh payload.`
- L155
  - was: `// First trigger resolves from the Mongo cache: same mutation must now read the fresh payload instead of the idle undefined.`
  - use: `// Post-trigger fetch must reread, not reuse idle undefined.`

### src/pages/patientView/clinicalInformation/PatientViewPageStore.ts

- L317
  - was: `// AlphaGenome variants are dispatched to Genome Nexus in chunks of this size so cold-cache scoring never blocks page load with one monolithic request.`
  - use: `// Score in chunks so cold caches never stall page load.`
- L1954
  - was: `// Click-to-score trigger state for AlphaGenome. The mutations table renders cold (empty 22px placeholders, one spinner per row while scoring) until the user starts background scoring from the mutations tab; rows then hydrate chunk by chunk without a page load stall.`
  - use: `// Cold table hydrates chunk by chunk after user-triggered scoring.`
- L1970
  - was: `// Local dev only: Match existing pattern via serverConfig (show_alphagenome). Defaults to true in serverConfigDefaults.ts for local AlphaGenome development.`
  - use: `// Gate on serverConfig, defaulting on for local dev.`
- L1978
  - was: `// All pre-fetch writes happen here in the action: the remoteData invoke below must stay read-only until its first await so MobX never sees an observable write inside a derivation.`
  - use: `// Prefetch writes stay in the action, never in derivations.`
- L2033
  - was: `// Re-armed here (in addition to the trigger action) so a mutations refetch that re-invokes this fetch also reports scoring in flight. This observable is never read above, so the write cannot re-trigger the fetch.`
  - use: `// Re-report scoring on refetch; this flag can't retrigger it.`
- L2053 — KEEP (repo-standard `onError` fail-silently convention, verbatim).

### src/pages/patientView/mutation/AlphaGenomeScoreButton.spec.tsx

- L25
  - was: `// Sample-first: the button renders even when the backend flag is off or absent.`
  - use: `// Button must render with the backend flag off.`

### src/pages/patientView/mutation/MutationTableWrapper.tsx

- L173 — KEEP (crisp toolbar-placement note).
- L268
  - was: `// Local dev only: Match existing pattern via serverConfig (show_alphagenome). Defaults to true in serverConfigDefaults.ts for local AlphaGenome development.`
  - use: `// Gate on serverConfig, defaulting on for local dev.`

### src/pages/patientView/mutation/PatientViewMutationsTab.tsx

- L54
  - was: `// Click-to-score control for AlphaGenome: the table renders cold with empty 22px annotation slots (one spinner per row while scoring), and scoring only starts when the user clicks through here. Variants are dispatched in background chunks while rows hydrate in place.`
  - use: `// Cold table with user-triggered background chunked scoring.`
- L64
  - was: `// Local dev only: Match existing pattern via serverConfig (show_alphagenome).`
  - use: `// Gate on serverConfig, defaulting on for local dev.`
- L300 — KEEP (crisp toolbar-placement note).
- L398
  - was: `// Local dev only: Match existing pattern via serverConfig (show_alphagenome). Defaults to true in serverConfigDefaults.ts for local AlphaGenome development.`
  - use: `// Gate on serverConfig, defaulting on for local dev.`

### src/pages/resultsView/ResultsViewPageStore.ts

- L438
  - was: `// Background AlphaGenome scoring queue: variants are dispatched to Genome Nexus in chunks of this size so cold-cache cohorts never block page load.`
  - use: `// Score in chunks so cold caches never stall page load.`
- L5484
  - was: `// Decoupled AlphaGenome trigger state. The mutations table renders cold (empty 22px placeholders) until the user starts background scoring via the toolbar control; rows then hydrate chunk by chunk without a page load stall or 504 from one monolithic request.`
  - use: `// Cold table hydrates per chunk after toolbar-triggered scoring.`
- L5506
  - was: `// All pre-fetch writes happen here in the action: the remoteData invoke below must stay read-only until its first await so MobX never sees an observable write inside a derivation.`
  - use: `// Prefetch writes stay in the action, never in derivations.`
- L5520
  - was: `// AlphaGenome annotations are fetched separately so cold-cache scoring does not delay the shared Genome Nexus fields above. The invoke stays idle (result undefined) until triggerAlphaGenomeScoring flips isAlphaGenomeTriggered; MobX re-invokes because the flag is read here. Variants are dispatched sequentially in chunks of 16, merging each chunk into streamingAlphaGenomeAnnotations for progress tracking.`
  - use: `// Separate idle-until-triggered fetch; chunks merge with progress.`
- L5572
  - was: `// Re-armed here (in addition to the trigger action) so a mutations refetch that re-invokes this fetch also reports scoring in flight. This observable is never read above, so the write cannot re-trigger the fetch.`
  - use: `// Re-report scoring on refetch; this flag can't retrigger it.`
- L5592 — KEEP (repo-standard `onError` fail-silently convention, verbatim).

### src/pages/resultsView/mutation/ResultsViewMutationMapperStore.ts

- L63
  - was: `// Decoupled AlphaGenome background-scoring state, owned by ResultsViewPageStore and passed in so the per-gene mapper store (and its toolbar control) can trigger scoring and observe chunk progress without a direct page-store reference. The closures read page-store observables, so MobX tracks them when called inside reactions or observer renders.`
  - use: `// Scoring state bridged via closures to avoid page-store coupling.`

## 2. genome-nexus (51 comments, 12 KEEP)

### component/.../annotation/AlphaGenomeVariantNormalizer.java

- L24
  - was: `W1: normalizes VariantAnnotation into GRCh38 AlphaGenome-ready coordinates (+hgvsg/steps detail)`
  - use: `Normalizes VariantAnnotation to GRCh38 VCF form for scoring.`
- L64
  - was: `Package-visible for tests; null resolver fails fast without GRCh38 sequence`
  - use: `Test seam; null resolver fails fast without sequence.`
- L83
  - was: `Applies pre-filtering and liftover; empty must not reach scoring/caching`
  - use: `Pre-filters and lifts over; empty skips scoring.`
- L89
  - was: `---- Step 1: pre-filter ----`
  - use: `Reject unscorable variants before liftover.`
- L173
  - was: `---- Step 2: GRCh37 -> GRCh38 liftover ----`
  - use: `Lift GRCh37 coordinates to GRCh38.`
- L190
  - was: `Insertions may be stored with start/end swapped; lift covered span`
  - use: `Insertions may store start/end swapped.`
- L230
  - was: `---- Step 3 + verbatim SDK normalize_variant port note ----`
  - use: `Left-align indels to VCF anchor-base form.`
- L249
  - was: `Deletions seed at first deleted base; insertions at right flank + why`
  - use: `Deletions seed at deleted base; insertions at right flank.`
- L269
  - was: `---- Step 4 + AlphaGenome does not reject wrong REF ----`
  - use: `Reject variants whose REF mismatches GRCh38.`
- L315
  - was: `Ports alphagenome normalize_variant; returns [position, ref, alt]`
  - use: `Left-aligns alleles to anchored VCF form.`
- L360 — KEEP (`Mirrors the SDK _prefix_length helper (stops at shortest input).`)
- L379
  - was: `Strips any Ensembl version suffix`
  - use: `Drops Ensembl version suffix from gene IDs.`
- L389
  - was: `Inverse of chromosomeNormalizer plus gating; strips chr, maps 23/24, rejects MT`
  - use: `Normalizes contigs to 1-22/X/Y; rejects others.`
- L416
  - was: `Loads bundled chain file; staged to temp for file-backed htsjdk ctor`
  - use: `Loads bundled hg19-to-hg38 chain file.`

### component/.../annotation/Grch38ReferenceSequenceResolver.java

- L3
  - was: `W1: abstraction over GRCh38 sequence for anchoring + REF check`
  - use: `GRCh38 slice reader for anchoring and REF checks.`
- L14 — KEEP (`Returns uppercase bases; out-of-range N-padded like SDK FastaExtractor`).

### component/.../annotation/HttpRangeGrch38ReferenceSequenceResolver.java

- L13
  - was: `W3: resolver fetching slices over HTTP Range via .fai; GCS defaults`
  - use: `Fetches GRCh38 slices via HTTP Range plus .fai.`
- L97
  - was: `Override point for tests: fetch raw bytes [firstByte, lastByte].`
  - use: `Test hook: raw byte-range fetch.`
- L121
  - was: `Override point for tests: fetch the raw .fai text.`
  - use: `Test hook: raw .fai fetch.`

### component/.../annotation/InMemoryGrch38ReferenceSequenceResolver.java

- L6
  - was: `W1: deterministic in-memory resolver for unit tests`
  - use: `In-memory GRCh38 sequences for unit tests.`

### component/.../annotation/IndexedFastaGrch38ReferenceSequenceResolver.java

- L9
  - was: `W1: production resolver backed by local indexed FASTA ...`
  - use: `Local indexed-FASTA GRCh38 resolver.`
- L35
  - was: `Mirror the SDK FastaExtractor: pad leading out-of-range bases with N.`
  - use: `N-pad leading out-of-range bases.`
- L45
  - was: `getSubsequenceAt takes 1-based inclusive coordinates.`
  - use: `htsjdk takes 1-based inclusive coordinates.`

### component/.../annotation/NormalizedAlphaGenomeVariant.java

- L7
  - was: `W1: normalized AlphaGenome-ready view; coordinates, VCF alleles, gene provenance`
  - use: `GRCh38 VCF-form variant with verified REF.`
- L50 — KEEP (`GRCh38 contig with chr prefix`).
- L56 — KEEP (`GRCh38 1-based position (anchor-base for indels)`).
- L62 — KEEP (`VCF-style reference allele (includes anchor base for indels)`).
- L68 — KEEP (`VCF-style alternate allele (includes anchor base for indels)`).
- L74
  - was: `Canonical gene id, null until W1.4`
  - use: `Canonical gene ID, null if unavailable.`
- L81
  - was: `Canonical gene symbol, null until W1.4`
  - use: `Canonical gene symbol, null if unavailable.`
- L88 — KEEP (`Rendered chr:pos:REF>ALT string`).

### component/.../util/AlphaGenomePipelineDebugLogger.java

- L12 — KEEP (`Common pipeline debug logger; commons-logging plus file output`).
- L43
  - was: `Safe fallback: never disrupt application flow`
  - use: `Never break the app on logging failure.`

### model/.../model/AlphaGenome.java

- L11
  - was: `W3: AlphaGenome annotation mirroring sidecar alpha_genome JSON contract`
  - use: `One variant's AlphaGenome scores per sidecar contract.`

### model/.../model/AlphaGenomeScore.java

- L7
  - was: `W3: one gene-filtered scorer x track row from tidy_scores`
  - use: `One gene-filtered scorer-by-track score row.`

### service/.../cached/CachedAlphaGenomeFetcher.java

- L29
  - was: `W3: cached sidecar fetcher; one variant per call, concurrent pool`
  - use: `Caches sidecar scores; fetches misses concurrently.`
- L75
  - was: `Fetches variants using staged sidecar request body per cache miss`
  - use: `Fetches variants using staged per-call request bodies.`
- L124
  - was: `Bounded-pool replacement for base sequential loop; concurrent fetch, sequential writes`
  - use: `Concurrent fetch; sequential transform and cache writes.`

### service/.../config/AlphaGenomeConfiguration.java

- L14
  - was: `W3: exposes GRCh38 resolver; local FASTA path or remote Range slices`
  - use: `Selects local-FASTA or remote-slice GRCh38 resolver.`

### service/.../enricher/AlphaGenomeAnnotationEnricher.java

- L22
  - was: `Provenance of the annotation payload: the model and SDK it was scored with.`
  - use: `AlphaGenome model/SDK provenance URL.`

### service/.../internal/AlphaGenomeServiceImpl.java

- L27
  - was: `W3: resolves cached AlphaGenome annotation; normalization runs first`
  - use: `Normalizes, then returns cached AlphaGenome annotation.`

### service/.../remote/AlphaGenomeDataFetcher.java

- L18
  - was: `W3: POSTs one normalized variant per call to sidecar POST /score`
  - use: `POSTs one variant per sidecar /score call.`

### component/.../annotation/AlphaGenomeVariantNormalizerTest.java

- L40 — KEEP (`Exercises the exact production chain-loading path.`)
- L81
  - was: `Real liftover maps 18:48604697-48604698; VCF form is GAA>G.`
  - use: `SMAD4 deletion left-aligns to GAA>G.`
- L130
  - was: `GRCh38 carries C at chr5:177513010, so REF G must be rejected.`
  - use: `Mismatched REF must be rejected.`
- L191
  - was: `Query strand -1: C/A -> on strand +1 becomes G/T.`
  - use: `Minus-strand alleles are reverse-complemented.`

### component/.../annotation/HttpRangeGrch38ReferenceSequenceResolverTest.java

- L13
  - was: `chrT: ACGTACGT wrapped at 4 bases per line, data at offset 10.`
  - use: `Tiny 4-bases-per-line test FASTA fixture.`
- L40 — KEEP (`0-based [0,4) -> file bytes [10,13] -> ACGT.` — pins offset math).
- L47
  - was: `0-based [2,6) spans the newline: bytes [12,16] -> GTAC.`
  - use: `Cross-line slice skips the newline.`
- L65 — KEEP (`// expected (empty IllegalArgumentException catch)` — standard marker).

### service/.../cached/CachedAlphaGenomeFetcherTest.java

- L109
  - was: `@Value injection does not run in unit tests; enable caching explicitly.`
  - use: `Unit tests set the caching flag directly.`

## 3. genome-nexus-frontend (2 comments, 0 KEEP)

### src/component/variantPage/AlphaGenome.tsx

- L17
  - was: `Default tissue: the ontology_curie of the row with the strongest absolute raw_score. The Variant Page has no study context, so effect size decides.`
  - use: `Initial tissue: ontology_curie with max absolute raw_score.`

### src/model/AlphaGenome.ts

- L3
  - was: `AlphaGenome payload shapes mirroring workstreams/contracts/alpha_genome_schema.json. Declared locally because the pinned client (1.1.40) predates alpha_genome; remove shim once client is regenerated.`
  - use: `Temporary AlphaGenome types; remove once API client supports alpha_genome.`

## 4. alphagenome-sidecar (12 comments, 5 KEEP)

### app/schemas.py

- L1
  - was: `"""Request/response shapes for POST /score. Mirrors yaml..."""`
  - use: `"""POST /score shapes; mirrors sidecar_openapi.yaml, no literature."""`
- L15
  - was: `# Sidecar-side allowlist (no SDK constant exists in 0.10.0; ...)`
  - use: `# Pre-reject lengths the server would reject (no SDK constant).`
- L19
  - was: `# Addressable scorers: keys of RECOMMENDED_VARIANT_SCORERS (...) ... out of scope.`
  - use: `# String-addressable scorers only; custom scorers out of scope.`

### app/scoring.py

- L1
  - was: `"""AlphaGenome scoring pipeline for POST /score. Wraps dna_client..."""`
  - use: `"""POST /score pipeline: score, tidy, filter, assemble payload."""`
- L36 — KEEP (`"""AlphaGenome API is unreachable, unconfigured, or returned an error."""` — 503 marker).
- L40 — KEEP (`"""AlphaGenome API rate limit exceeded."""` — 429 marker).
- L53
  - was: `"""Window of sequence_length centered on the variant. Uses resize... Future iteration..."""`
  - use: `"""Centered window; right-shifts if start goes negative."""`
- L105
  - was: `"""Run the full pipeline with an injected client (no env access)."""`
  - use: `"""Score request with injected client; reads no env."""`
- L204 — KEEP (merged-splicing formula; the formula is the comment).

### tests/test_score.py

- L1 — KEEP (`"""Unit tests for POST /score (no network, no API key)."""` — hermetic constraint).
- L97
  - was: `"""Every TestClient test gets a dependency-injected client, so ... without needing an API key."""`
  - use: `"""Inject fake client so 422s need no API key."""`
- L289 — KEEP (`# Only the tissue-agnostic SPLICE_SITES row survives a non-matching curie.` — pins the assertion).

## Flagged (not a comment edit — needs your call)

- `cbioportal-frontend/.../AlphaGenomeScoreButton.spec.tsx` L25 claims the button renders with the backend flag off, but `PatientViewMutationsTab.tsx` returns null when the flag is off. Either the button should render flag-off or the spec setup is stale. Unverified — confirm before touching.
