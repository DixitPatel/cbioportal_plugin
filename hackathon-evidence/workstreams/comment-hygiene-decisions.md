# Comment Hygiene Decisions (96 entries — status: pending/decided)

Legend: A = accept suggestion, K = keep existing, N = new text (recorded inline).
Global rule (user, entry 6): NO trailing period on any comment — strip `.` before
line end / `*/` when applying, including KEEP entries.
Global rule (user, entry 10): SKIP all test/spec files entirely — no changes to
*.spec.*, *Test.java, tests/. This also voids the earlier decisions on entries 1-2.
Applied at the end in one pass. Catalog: workstreams/comment-hygiene-catalog.md

## cbioportal-frontend
1. AlphaGenome.spec.tsx:104 — SKIP (test file, voids earlier ACCEPT)
2. AlphaGenome.spec.tsx:151 — SKIP (test file, voids earlier REMOVE)
3. AlphaGenome.tsx:27 — ACCEPT (`/** Strong/moderate label needs |quantile| >= 0.99 plus raw-score threshold */`)
4. AlphaGenome.tsx:62 — KEEP existing (strip trailing period per global rule)
5. AlphaGenome.tsx:230 — NEW (`// Picking a tissue with no passing score must not blank the row's icon`)
6. AlphaGenome.tsx:236 — ACCEPT (`// Fall back when a stored tissue is absent post-sort`)
7. AlphaGenome.tsx:364 — REMOVE entirely (no replacement)
8. AlphaGenome.tsx:371 — ACCEPT (`// Hold the 22px slot with a spinner while scoring`)
9. oncotreeToUberon.ts:1 — SKIP FILE entirely (no changes to oncotreeToUberon.ts)
10. Annotation.retrigger.spec.ts:84 — SKIP (test file)
11. Annotation.retrigger.spec.ts:155 — SKIP (test file)
12. PatientViewPageStore.ts:317 — NEW (`// Score in chunks to not stall page load`)
13. PatientViewPageStore.ts:1954 — NEW (`// Click triggers batched scoring for variants`)
14. PatientViewPageStore.ts:1970 — ACCEPT + TBD (`// Gate on serverConfig, defaulting on for local dev — TBD to remove before PR merge`)
15. PatientViewPageStore.ts:1978 — REMOVE entirely (no replacement)
16. PatientViewPageStore.ts:2033 — REMOVE entirely (no replacement)
17. PatientViewPageStore.ts:2053 — KEEP existing (no trailing period present)
18. AlphaGenomeScoreButton.spec.tsx:25 — SKIP (test file)
19. MutationTableWrapper.tsx:173 — NEW (`// Rendered in the table toolbar below the mutation count`)
20. MutationTableWrapper.tsx:268 — KEEP + TBD (`// Local dev only: Match existing pattern via serverConfig (show_alphagenome). Defaults to true in serverConfigDefaults.ts for local AlphaGenome development — TBD to reverify`)
21. PatientViewMutationsTab.tsx:54 — REUSE #13 (`// Click triggers batched scoring for variants`)
22. PatientViewMutationsTab.tsx:64 — ACCEPT (`// Gate on serverConfig, defaulting on for local dev`)
23. PatientViewMutationsTab.tsx:300 — NEW (`// Rendered in the table toolbar below the mutation count, alongside the filter and download`)
24. PatientViewMutationsTab.tsx:398 — KEEP + TBD, 20-style (`// Local dev only: Match existing pattern via serverConfig (show_alphagenome). Defaults to true in serverConfigDefaults.ts for local AlphaGenome development — TBD to reverify`)
25. ResultsViewPageStore.ts:438 — NEW (`// Background AlphaGenome scoring queue: variants are dispatched to Genome Nexus in chunks of this size`)
26. ResultsViewPageStore.ts:5484 — REGENERATED 4x1 (`// User started background scoring via toolbar` / `// Scoring fetch currently in flight` / `// Hydrated annotations by genomic location` / `// Scored-vs-total count for progress display`)
27. ResultsViewPageStore.ts:5506 — REMOVE entirely (no replacement)
28. ResultsViewPageStore.ts:5520 — NEW (`// Variants are dispatched sequentially in chunks of 16, merging each chunk into streamingAlphaGenomeAnnotations for progress tracking`)
29. ResultsViewPageStore.ts:5572 — REMOVE entirely (no replacement)
30. ResultsViewPageStore.ts:5592 — KEEP existing (no trailing period present)
31. ResultsViewMutationMapperStore.ts:63 — REMOVE entirely (no replacement)

## genome-nexus
32. AlphaGenomeVariantNormalizer.java:24 — SKIP (modified separately; excluded from this pass)
33. AlphaGenomeVariantNormalizer.java:64 — TBD REVIEW (`Why is test seam in production code` — leave comment untouched pending review)
34. AlphaGenomeVariantNormalizer.java:83 — NEW (`Applies pre-filtering and liftover` — already satisfied by concurrent edit; verified in place, no change made)
35. AlphaGenomeVariantNormalizer.java:89 — KEEP existing
36. AlphaGenomeVariantNormalizer.java:173 — KEEP existing
37. AlphaGenomeVariantNormalizer.java:190 — KEEP existing
38. AlphaGenomeVariantNormalizer.java:230 — KEEP existing
39. AlphaGenomeVariantNormalizer.java:249 — KEEP existing (strip trailing period per global rule)
40. AlphaGenomeVariantNormalizer.java:269 — NEW (keep banner + one-liner: `// ---- Step 4: GRCh38 REF check & canonical transcript extraction ---- Reject variants whose REF mismatches GRCh38`)
41. AlphaGenomeVariantNormalizer.java:315 — KEEP existing
42. AlphaGenomeVariantNormalizer.java:360 — KEEP existing (strip trailing period per global rule)
43. AlphaGenomeVariantNormalizer.java:379 — ACCEPT (`Drops Ensembl version suffix from gene IDs`)
44. AlphaGenomeVariantNormalizer.java:389 — ACCEPT (`Normalizes contigs to 1-22/X/Y; rejects others`)
45. AlphaGenomeVariantNormalizer.java:416 — SKIP (already modified; excluded from this pass)
46. Grch38ReferenceSequenceResolver.java:3 — NEW (drop W1 tag only: `* Abstraction over the GRCh38 reference sequence used for indel` / `* anchoring / left-alignment and {@code REF} check.` — rest of block untouched)
47. Grch38ReferenceSequenceResolver.java:14 — KEEP existing (trailing period stripped per global rule)
48. HttpRangeGrch38ReferenceSequenceResolver.java:13 — SKIP FILE (voids earlier ACCEPT; no comment changes to this file) — FILE TBD: `Can this be removed and kept only the liftover chain file`
49. HttpRangeGrch38ReferenceSequenceResolver.java:97 — SKIP (file skipped; TBD carried at entry 48)
50. HttpRangeGrch38ReferenceSequenceResolver.java:121 — SKIP (file skipped; TBD carried at entry 48)
51. InMemoryGrch38ReferenceSequenceResolver.java:6 — SKIP FILE (no comment changes to this file)
52. IndexedFastaGrch38ReferenceSequenceResolver.java:9 — ACCEPT (`Local indexed-FASTA GRCh38 resolver`)
53. IndexedFastaGrch38ReferenceSequenceResolver.java:35 — KEEP existing (strip trailing period per global rule)
54. IndexedFastaGrch38ReferenceSequenceResolver.java:45 — ACCEPT (`htsjdk takes 1-based inclusive coordinates`)
55. NormalizedAlphaGenomeVariant.java:7 — NEW (drop W1 tag only: `* Normalized AlphaGenome-ready view of a {@code VariantAnnotation};` — rest of block untouched)
56. NormalizedAlphaGenomeVariant.java:50 — KEEP existing (trailing period stripped per global rule)
57. NormalizedAlphaGenomeVariant.java:56 — KEEP existing (trailing period stripped per global rule)
58. NormalizedAlphaGenomeVariant.java:62 — KEEP existing (trailing period stripped per global rule)
59. NormalizedAlphaGenomeVariant.java:68 — KEEP existing (trailing period stripped per global rule)
60. NormalizedAlphaGenomeVariant.java:74 — ACCEPT (`Canonical gene ID, null if unavailable`)
61. NormalizedAlphaGenomeVariant.java:81 — ACCEPT (`Canonical gene symbol, null if unavailable`)
62. NormalizedAlphaGenomeVariant.java:88 — KEEP existing (trailing period stripped per global rule)
63. AlphaGenomePipelineDebugLogger.java:12 — KEEP existing (no trailing period present)
64. AlphaGenomePipelineDebugLogger.java:43 — SKIP FILE (no comment changes to this file; entry 63 KEEP stands as no-op)
65. AlphaGenome.java:11 — NEW (drop W3 + contract/literature lines: `* AlphaGenome annotation for one normalized GRCh38 variant and its` / `* canonical gene`)
66. AlphaGenomeScore.java:7 — ACCEPT (`One gene-filtered scorer-by-track score row`)
67. CachedAlphaGenomeFetcher.java:29 — ACCEPT alt (`One variant per call; concurrent pool backed by cache`)
68. CachedAlphaGenomeFetcher.java:75 — KEEP existing (no trailing period present)
69. CachedAlphaGenomeFetcher.java:124 — ACCEPT sentence (`Variants are fetched concurrently and written sequentially`)
70. AlphaGenomeConfiguration.java:14 — ACCEPT (`Selects local-FASTA or remote-slice GRCh38 resolver`)
71. AlphaGenomeAnnotationEnricher.java:22 — ACCEPT (`AlphaGenome model/SDK provenance URL`)
72. AlphaGenomeServiceImpl.java:27 — ACCEPT (`Normalizes, then returns cached AlphaGenome annotation`)
73. AlphaGenomeDataFetcher.java:18 — NEW (first line minus W3: `POSTs one normalized variant per call to the AlphaGenome sidecar` — rest of block untouched)
74. AlphaGenomeVariantNormalizerTest.java:40 — SKIP (test file)
75. AlphaGenomeVariantNormalizerTest.java:81 — SKIP (test file)
76. AlphaGenomeVariantNormalizerTest.java:130 — SKIP (test file)
77. AlphaGenomeVariantNormalizerTest.java:191 — SKIP (test file)
78. HttpRangeGrch38ReferenceSequenceResolverTest.java:13 — SKIP (test file)
79. HttpRangeGrch38ReferenceSequenceResolverTest.java:40 — SKIP (test file)
80. HttpRangeGrch38ReferenceSequenceResolverTest.java:47 — SKIP (test file)
81. HttpRangeGrch38ReferenceSequenceResolverTest.java:65 — SKIP (test file)
82. CachedAlphaGenomeFetcherTest.java:109 — SKIP (test file)

## genome-nexus-frontend
83. variantPage/AlphaGenome.tsx:17 — NEW + TBD (`Default tissue: the ontology_curie of the row with the strongest absolute raw_score` — TBD: `revise the ranking - sort descending`)
84. model/AlphaGenome.ts:3 — TBD REVIEW (`I don't recall this, review again` — leave comment untouched pending review)

## alphagenome-sidecar
85. app/schemas.py:1 — NEW (`"""Request and response models for the variant scoring API"""`)
86. app/schemas.py:15 — NEW (`# Reject unsupported sequence lengths`)
87. app/schemas.py:19 — NEW (`# List of recommended scorers currently implemented`)
88. app/scoring.py:1 — KEEP existing (no trailing period present)
89. app/scoring.py:36 — KEEP existing (strip trailing period per global rule)
90. app/scoring.py:40 — KEEP existing (strip trailing period per global rule)
91. app/scoring.py:53 — KEEP existing (no trailing period present)
92. app/scoring.py:105 — KEEP existing (strip trailing period per global rule)
93. app/scoring.py:204 — KEEP existing (strip trailing period per global rule)
94. tests/test_score.py:1 — SKIP (test file)
95. tests/test_score.py:97 — SKIP (test file)
96. tests/test_score.py:289 — SKIP (test file)

## CHECKPOINT — interview complete, pre-apply
- 96/96 decided: 24 ACCEPT, 15 NEW/alt wording, 26 KEEP, 6 REMOVE, 23 SKIP, 4 TBD held back untouched (33 test-seam question; 48 file-level HTTP-range question; 83 code ranking TBD; 84 needs re-review).
- Global rules in force: no trailing period on any applied comment; all test/spec files skipped.
- Open flag (not a comment edit): score-button spec L25 vs flag-off null render in PatientViewMutationsTab — owner to confirm.

## APPLY RECORD
- Applied, cbioportal-frontend: 3,4,5,6,7,8,12,13,14,15,16,19,20,21,22,23,24,25,26,27,28,29,31 (17,30 no-op keeps).
- Applied, genome-nexus: 39,40,42,43,44,46,52,53,54,55,56,57,58,59,60,61,62,65,66,67,68,69,70,71,72,73 (34 already satisfied by concurrent edit; 35,36,37,38,41,47 no-op keeps).
- Applied, genome-nexus-frontend: 83 (comment only; code-ranking TBD stays open).
- Applied, alphagenome-sidecar: 85,86,87,88,89,90,91,92,93.
- Untouched: test/spec skips, file skips (9,48-51,64), separately-modified (32,45), TBD holds (33,48-file,83-code,84).
- Verification: `py_compile` clean on both sidecar files; `git diff` scan across all 4 repos shows zero code-line changes; no orphaned Javadoc openers. Full jest/maven suites not run — comment-only edits, disproportionate cost.
- Open: TBDs 33, 48, 83-code, 84; score-button spec flag.
- Apply authorized by user ("Next apply"): all non-TBD decisions, one pass, then verification.
