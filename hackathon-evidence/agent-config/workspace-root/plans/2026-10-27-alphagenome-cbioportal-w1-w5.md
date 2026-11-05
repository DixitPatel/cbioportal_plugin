# Implementation Plan: AlphaGenome + Muse Spark Integration Across Genome Nexus & cBioPortal (`W1`–`W5`)

## Goal
Deliver the end-to-end integration of **Google DeepMind AlphaGenome** variant-effect predictions (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) and **Muse Spark 1.3** literature synthesis into **Genome Nexus** and **cBioPortal** (GSoC issue #139).

## Workstreams

1. **`W1` — Liftover & REF Check (`skill: liftover-refcheck`)**:
   - Lift `GRCh37` variants to `GRCh38` (`hg19ToHg38.over.chain.gz`).
   - Normalize MAF indels (`-`) to left-aligned VCF anchor-base form with `chr` prefix.
   - Verify `REF` against the `GRCh38` reference sequence and extract canonical transcript `geneId` + `geneSymbol`.
   - Reject failed variants before scoring or caching.
2. **`W2` — AlphaGenome Scoring Sidecar (`skill: alphagenome-sidecar`)**:
   - Implement `POST /score` in `alphagenome-sidecar` (`app/main.py` and submodules).
   - Call `dna_client.score_variant()` with `SEQUENCE_LENGTH_1MB` and the 4 recommended scorers (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`).
   - Run `tidy_scores` locally, filter to the canonical gene, compute `merged_splicing_score`, and echo `variant`.
3. **`W3` — Genome Nexus `alpha_genome` Field & Cache (`skill: genome-nexus-enricher`)**:
   - Add `AnnotationField.ALPHA_GENOME`, `AlphaGenome` (`@Document(collection = "alphagenome.annotation")`), `AlphaGenomeAnnotation`, `VariantAnnotation` field, `VariantAnnotationMixin` (`@JsonProperty("alpha_genome")`), `AlphaGenomeRepository`, `CachedAlphaGenomeFetcher` (`max_page_size=1`, `extractId` overrides), and `AlphaGenomeAnnotationEnricher`.
4. **`W4` — cBioPortal Mutations Table Annotation Cell (`skill: cbioportal-annotation-cell`)**:
   - Add `ALPHA_GENOME = 'alpha_genome'` and separate `alphaGenomeAnnotations` fetch in `ResultsViewPageStore` and `PatientViewPageStore`.
   - Implement `AlphaGenomeCell` and `AlphaGenomeTooltipContent` (`packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.tsx`) after `reVUE`, gated by `show_alphagenome`.
5. **`W5` — Genome Nexus Variant Page View (`skill: variant-page-view`)**:
   - Add `alpha_genome` to `DEFAULT_ANNOTATION_QUERY_FIELDS` (`src/config/configDefaults.ts`).
   - Add `AlphaGenome.tsx` under `src/component/variantPage/` and wire into `FunctionalGroups.tsx`.
6. **`Verify` — End-to-End Acceptance Verification (`skill: verify-pipeline`)**:
   - Execute pytest, Maven, and Jest test suites across all repositories and export deterministic session trajectories (`muse export`).
