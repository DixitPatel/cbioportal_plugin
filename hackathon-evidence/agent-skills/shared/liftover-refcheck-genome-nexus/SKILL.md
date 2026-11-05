---
name: liftover-refcheck
description: Lift GRCh37 variants to GRCh38 with htsjdk LiftOver, normalize MAF indels to left-aligned VCF anchor-base form, and verify REF against GRCh38 FASTA in genome-nexus.
---

# Skill: `liftover-refcheck` (`W1` — `genome-nexus`)

## When to Use
Invoke this skill when working on **Workstream `W1`** in `genome-nexus` (`workspace/genome-nexus`) to filter, lift (`GRCh37` $\rightarrow$ `GRCh38`), anchor/left-align MAF indels (`-`), and verify `REF` alleles against the GRCh38 reference FASTA before AlphaGenome scoring.

## Guided Step-by-Step Execution Requirement
Always follow the 6 approval-gated sub-steps defined in `workstreams/W1_liftover_refcheck.md`:
- **`W1.1`**: Discovery & Design Alignment (`Planner` — inspect `VariantAnnotation.java`, `NotationConverter.java`, `CanonicalTranscriptResolver.java`, `component/pom.xml`; present design and wait for approval).
- **`W1.2`**: Add `com.github.samtools:htsjdk` to `component/pom.xml` and `hg19ToHg38.over.chain.gz` resource; verify `mvn test-compile -pl model,component -B` and wait for approval.
- **`W1.3`**: Implement `NormalizedAlphaGenomeVariant` and `AlphaGenomeVariantNormalizer` Steps 1–2 (pre-filter + `htsjdk LiftOver`); verify unit tests and wait for approval.
- **`W1.4`**: Implement Steps 3–4 (MAF `-` indel anchor-base lookup at `pos = start - 1` for deletions / `pos = end` for insertions, left-alignment in GRCh38, GRCh38 FASTA `REF` verification, and `CanonicalTranscriptResolver` `geneId`/`geneSymbol` extraction); wait for approval.
- **`W1.5`**: Complete `AlphaGenomeVariantNormalizerTest` covering `DDX41` (`5:g.176940011C>T` $\rightarrow$ `chr5:177513010:C>T`), `BRAF` (`7:g.140453136A>T` $\rightarrow$ `chr7:140753336:A>T`), `SMAD4` (`18:g.48604697_48604698del` `AA/-` $\rightarrow$ `GAA>G`), insertions, and `REF` mismatch rejections; run `mvn test -pl model,component,service -B` and wait for approval.
- **`W1.6`**: Diff review, state update (`.muse/state.json`), and final `W1` sign-off.

## Core Technical Rules (`workstreams/W1_liftover_refcheck.md`)
1. **Reference Existing `alphagenome` SDK (`workspace/alphagenome`) & Remote Reference URLs**:
   - Inspect `workspace/alphagenome/src/alphagenome/data/genome.py` (`Variant` lines 645–815 and `normalize_variant` lines 965–1024), `io/fasta.py`, and `colabs/v1/haplotype_workaround.ipynb` (lines 162–166).
   - Remote GRCh38 FASTA URL: `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/GRCh38.p13.genome.fa`
   - Remote GRCh38 FAI Index URL: `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/GRCh38.p13.genome.fa.fai` (supports HTTP `Range: bytes=...` byte-offset lookups or local `IndexedFastaSequenceFile`)
   - Remote UCSC Chain URL: `https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz`
   - Port the exact `normalize_variant` left-alignment & anchor-base algorithm (Tan et al., 2015) and `VariantFormat.DEFAULT` (`chr:pos:REF>ALT`) into `genome-nexus`.
2. **Never use `VariantAnnotation.getHgvsg()`**: VEP 3'-shifts `hgvsg` on repetitive indels (such as `SMAD4` `c.1520_1521del`). Always read `seqRegionName`, `start`, `end`, `alleleString`, `assemblyName`, and `strand` from `VariantAnnotation`.
3. **Pre-Filter**: Reject (`Optional.empty()`) if `!Boolean.TRUE.equals(annotation.getSuccessfullyAnnotated())`, `annotation.getErrorMessage() != null`, chromosome is `MT`/`M`, or `alleleString` contains characters outside `A`, `C`, `G`, `T`, `-`.
4. **Liftover (`GRCh37` $\rightarrow$ `GRCh38`)**: Use `htsjdk.samtools.liftover.LiftOver` with `hg19ToHg38.over.chain.gz`. Reject if liftover returns `null` or changes chromosome. Prepend `chr` (`1..22`, `X`, `Y`).
5. **VCF Indel Anchor Base & Left-Alignment**: Convert MAF `-` alleles to empty strings `""` and apply the `alphagenome.data.genome.normalize_variant` loop (`pos = start - 1` for deletions `R/-`, `pos = end` or `min(start, end)` for insertions `-/A`), left-aligned against GRCh38.
6. **Mandatory GRCh38 `REF` Check**: AlphaGenome does not reject wrong `REF` bases. Compare `vcfRef` against the GRCh38 reference sequence and return `Optional.empty()` on mismatch so rejected variants are never scored or cached.
