# Workstreams — Guided Step-by-Step Execution Order

Muse executes **one workstream at a time**, and within each workstream executes **one sub-step at a time with mandatory user approval gates**.
Detailed specifications live in `workstreams/*.md`.

---

## `W1`: Liftover and REF Check (`workstreams/W1_liftover_refcheck.md`) — **CURRENT FOCUS**
- **Repository**: `genome-nexus/` (`http://localhost:38080` live backend running)
- **Skill**: `liftover-refcheck`, `codebase-analysis`, `tdd`, `code-review`
- **End Goal**: Lift `GRCh37` variants to `GRCh38` using `htsjdk LiftOver` (`hg19ToHg38.over.chain.gz`), normalize MAF indels (`-`) to left-aligned VCF anchor-base form with `chr` prefix, verify `REF` against the `GRCh38` reference sequence, extract canonical `geneId` + `geneSymbol` via `CanonicalTranscriptResolver`, and reject invalid/mismatched variants before scoring or caching.
- **Approval-Gated Sub-Steps**:
  - **`W1.1` (Discovery & Design)**: Inspect `VariantAnnotation.java`, `NotationConverter.java`, `CanonicalTranscriptResolver.java`, `component/pom.xml`. Present class & FASTA resolver design $\rightarrow$ **Wait for User Approval**.
  - **`W1.2` (Dependencies & Chain File)**: Add `com.github.samtools:htsjdk` to `component/pom.xml` and `hg19ToHg38.over.chain.gz` resource; run `mvn test-compile -pl model,component -B` $\rightarrow$ **Wait for User Approval**.
  - **`W1.3` (Pre-Filter & Liftover)**: Implement `NormalizedAlphaGenomeVariant` and `AlphaGenomeVariantNormalizer` (Steps 1–2: filter `MT`/invalid alleles/errors + `GRCh37 -> GRCh38` liftover) $\rightarrow$ **Wait for User Approval**.
  - **`W1.4` (Indel Anchoring, Left-Alignment & `REF` Check)**: Implement MAF `-` indel anchor-base lookup (`pos = start - 1` for `R/-`, `pos = end` for `-/A`), left-alignment, GRCh38 FASTA `REF` verification, and `CanonicalTranscriptResolver` integration $\rightarrow$ **Wait for User Approval**.
  - **`W1.5` (Unit Tests)**: Verify `DDX41` (`5:g.176940011C>T` $\rightarrow$ `chr5:177513010:C>T`), `BRAF` (`7:g.140453136A>T` $\rightarrow$ `chr7:140753336:A>T`), `SMAD4` (`18:g.48604697_48604698del` `AA/-` $\rightarrow$ `GAA>G`), insertions, and `REF` mismatch rejection via `mvn test -pl model,component,service -B` $\rightarrow$ **Wait for User Approval**.
  - **`W1.6` (Review & Sign-Off)**: Reviewer diff check, update `.muse/state.json` $\rightarrow$ **Wait for User Approval**.

---

## `W2`: AlphaGenome Sidecar (`workstreams/W2_alphagenome_sidecar.md`)
- **Status**: Blocked until `W1` is approved.

## `W3`: Genome Nexus Enricher (`workstreams/W3_genome_nexus_enricher.md`)
- **Status**: Blocked until `W1` and `W2` are approved.

## `W4`: cBioPortal Annotation Cell (`workstreams/W4_cbioportal_annotation_cell.md`)
- **Status**: Blocked until `W3` is approved.

## `W5`: Variant Page View (`workstreams/W5_variant_page_view.md`)
- **Status**: Blocked until `W3` is approved.

## `verify-pipeline`: End-to-End Verification (`workstreams/Verify_pipeline.md`)
- **Status**: Blocked until `W1`–`W5` are approved.
