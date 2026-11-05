---
name: liftover-refcheck
description: Lift GRCh37 variants to GRCh38, normalize MAF indels to left-aligned VCF anchor-base form, verify REF against GRCh38 FASTA, and extract the canonical gene.
---

# Liftover and REF Check (`W1`)

Use this skill when implementing or testing coordinate liftover (`GRCh37` to `GRCh38`), MAF-to-VCF indel normalization, GRCh38 reference-allele verification, and canonical transcript gene extraction in `genome-nexus` or `alphagenome-sidecar`.

## Ordered Normalization Pipeline

Build the AlphaGenome query from `VariantAnnotation` fields (`seqRegionName`, `start`, `end`, `alleleString`, `assemblyName`), never from `getHgvsg()` (which is 3'-shifted by VEP):

1. **Filter**:
   - Skip the variant if `!isSuccessfullyAnnotated()`, if `errorMessage != null`, if `alleleString == null`, if the chromosome is `MT` / `chrM`, or if an allele contains a character other than `A`, `C`, `G`, `T`, or `-`.
2. **Liftover (`GRCh37` -> `GRCh38`)**:
   - When `assemblyName` is `GRCh37` (or unset default), lift coordinates using `htsjdk` `LiftOver` (`hg19ToHg38.over.chain.gz`) in Java or `pyliftover` / chain liftover in Python.
   - Drop the variant if liftover fails or maps to a different chromosome.
3. **VCF Indel Anchoring & Left-Alignment**:
   - Genome Nexus stores MAF alleles where `-` denotes an empty allele.
   - **SNV / MNV / delins**: `pos = start`, `REF = ref`, `ALT = alt`.
   - **Deletion (`R/-`)**: `pos = start - 1`, `REF = base(pos) + R`, `ALT = base(pos)`.
   - **Insertion (`-/A`)**: `pos = end` (left flank), `REF = base(pos)`, `ALT = base(pos) + A`.
   - **Left-align**: While the last base of `REF` and `ALT` match and `pos > 1`, rotate right-to-left using the preceding GRCh38 reference base.
   - **Chromosome prefix**: Prepend `chr` (`17` -> `chr17`, `23` -> `chrX`, `24` -> `chrY`).
4. **GRCh38 `REF` Check**:
   - Compare the normalized `REF` allele against the GRCh38 reference sequence at `chr:pos`.
   - Drop the variant immediately on mismatch. AlphaGenome silently scores mismatched `REF` alleles without error, so this check is mandatory.
5. **Canonical Gene Selection**:
   - Extract `geneId` (Ensembl `ENSG...`, version stripped) and `geneSymbol` (Hugo symbol) from the canonical transcript (`TranscriptConsequence` used by `annotation_summary`).
   - Skip the variant if no canonical transcript exists.

## Rejection Policy

Rejected or skipped variants must **not** be sent to AlphaGenome and must **not** be cached as valid score documents.

## Acceptance Criteria

- `DDX41` `5:g.176940011C>T` (`GRCh37`) lifts to `chr5:177513010:C>T` (`GRCh38`) with matching `REF`.
- `SMAD4` `c.1520_1521del` (`18:g.48604696_48604697del`) normalizes to left-aligned VCF anchor-base form (`GAA>G`).
- Any synthetic variant with an intentionally mutated `REF` base is rejected before scoring.
