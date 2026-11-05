---
name: alpha_genome_contract
description: JSON contract for sidecar POST /score, MongoDB alphagenome.annotation cache, and Genome Nexus VariantAnnotation.alpha_genome field.
type: project
---

# AlphaGenome Data Contract (`alpha_genome`)

## 1. Sidecar `POST /score` Request (from Genome Nexus to `alphagenome-sidecar:8000`)

```json
{
  "variant": "7:g.140453136A>T",
  "chromosome": "chr7",
  "position": 140753336,
  "reference_allele": "A",
  "alternate_allele": "T",
  "canonical_gene_id": "ENSG00000157764",
  "canonical_gene": "BRAF",
  "include_literature": false
}
```

## 2. Sidecar `POST /score` Response & MongoDB `alphagenome.annotation` Document

```json
{
  "variant": "7:g.140453136A>T",
  "hg38_variant": "chr7:140753336:A>T",
  "scored_interval": "chr7:140229048-141277624",
  "model_version": "alphagenome-v1",
  "canonical_gene_id": "ENSG00000157764",
  "canonical_gene": "BRAF",
  "merged_splicing_score": 0.142,
  "scores": [
    {
      "output_type": "RNA_SEQ",
      "variant_scorer": "GeneMaskLFCScorer",
      "gene_id": "ENSG00000157764",
      "gene_name": "BRAF",
      "track_name": "pancreas_rna_seq_plus",
      "ontology_curie": "UBERON:0001264",
      "biosample_name": "pancreas",
      "raw_score": 0.612,
      "quantile_score": 0.994
    },
    {
      "output_type": "SPLICE_SITES",
      "variant_scorer": "GeneMaskSplicingScorer",
      "gene_id": "ENSG00000157764",
      "gene_name": "BRAF",
      "track_name": "donor_plus",
      "ontology_curie": null,
      "biosample_name": null,
      "raw_score": 0.08,
      "quantile_score": 0.62
    }
  ],
  "literature": null
}
```

## 3. UI Dual-Gate Thresholds (Applied in `cbioportal-frontend` and `genome-nexus-frontend`)

- **Quantile Gate**: `|quantile_score| >= 0.99`
- **Raw Magnitude Gate**:
  - `RNA_SEQ`: `|raw_score| >= 0.5` (`strong`), `>= 0.1` (`moderate`)
  - `SPLICE_SITES` & `SPLICE_SITE_USAGE`: `raw_score >= 0.5` (`strong`), `>= 0.2` (`moderate`)
- **Default Tissue Mapping**:
  - `PAAD` -> `UBERON:0001264` (pancreas), alternate `UBERON:0001150` (body of pancreas)
  - `PANET` -> `UBERON:0000016` (endocrine pancreas)
