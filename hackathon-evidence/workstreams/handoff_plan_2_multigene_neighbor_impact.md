# Handoff Plan 2: Multi-Gene Receptive Field & Neighbor Collateral Impact (TBD)

**Status**: TBD / Architectural Option for Advanced Staged Rollout  
**Target Repositories**:
- `workspace/alphagenome-sidecar` (W2)
- `workspace/genome-nexus` (W3)
- `workspace/cbioportal-frontend` (W4)  
**Assigned Agent**: Muse Code (Planner / Reviewer / Implementer)

---

## 1. Problem Statement & Motivation
AlphaGenome evaluates a **1 Mb context window** ($1{,}048{,}576$ bp). In human chromosomes, a 1 Mb region routinely contains **20 to 50+ genes**.
- Currently, `_filter_to_canonical_gene` discards all non-canonical genes.
- **The Biological Risk**: Variants in non-coding or intronic sequences often act as long-range enhancers or disrupt shared regulatory architecture (e.g. *CDKN2A*/*CDKN2B*, *TP53*/*WRAP53*, *IRX3*/*FTO*), directly dysregulating neighbor genes.
- **The UI Dilemma**: cBioPortal's Mutation Table is organized 1-row-per-mutation in the queried gene (e.g. querying *BRAF*). Injecting 40 neighbor gene rows or badges directly into a 20px table cell causes unacceptable visual clutter and cognitive overload for clinicians.

---

## 2. Architectural Solution: Dual-Tier Neighbor Impact Detection

Instead of an all-or-nothing approach, introduce **`gene_filter_mode`**:

```json
{
  "variant": "7:g.140453136A>T",
  "canonical_gene": "BRAF",
  "gene_filter_mode": "significant_neighbors"
}
```

### Supported Modes:
1. **`canonical_only`** *(Default / Stable)*:
   - Preserves current behavior: returns only canonical gene tracks. Zero changes to downstream payloads.
2. **`all_genes`** *(Bioinformatic Discovery Mode)*:
   - Returns all scored rows in the 1 Mb window without gene filtering (suitable for offline analysis).
3. **`significant_neighbors`** *(Expert Recommended Option)*:
   - Full track scores returned for **canonical gene**.
   - Sidecar scans neighbor genes in `tidy_scores` for high-impact alterations:
     $$|\text{quantile\_score}| \ge 0.99 \quad \text{OR} \quad |\text{raw\_score}| \ge 0.5$$
   - Emits a lightweight summary block `significant_neighbor_impacts` (avoiding payload bloat).

---

## 3. Contract Schema Additions (`alpha_genome_schema.json`)

```json
{
  "type": "object",
  "properties": {
    "variant": { "type": "string" },
    "canonical_gene": { "type": "string" },
    "merged_splicing_score": { "type": ["number", "null"] },
    "scores": { "type": "array", "description": "Canonical gene track scores" },
    "significant_neighbor_impacts": {
      "type": "array",
      "description": "High-confidence collateral disruptions detected on neighboring genes within 1 Mb",
      "items": {
        "type": "object",
        "properties": {
          "gene_name": { "type": "string", "example": "AGAP3" },
          "gene_id": { "type": "string", "example": "ENSG00000157766" },
          "distance_from_variant_bp": { "type": "integer", "example": 124500 },
          "disrupted_output_types": {
            "type": "array",
            "items": { "type": "string" },
            "example": ["RNA_SEQ", "SPLICE_SITES"]
          },
          "max_quantile_score": { "type": "number", "example": 0.995 },
          "max_raw_score": { "type": "number", "example": 0.62 }
        },
        "required": ["gene_name", "max_quantile_score"]
      }
    }
  }
}
```

---

## 4. cBioPortal UI Mapping: Zero-Clutter Display Strategy

To maintain cBioPortal's clean UI paradigm in `packages/react-mutation-mapper`:

```
┌────────────────────────────────────────────────────────┐
│ Mutations Table (Query: BRAF)                          │
├──────────────┬──────────────┬─────────────┬────────────┤
│ Mutation     │ Protein      │ Cancer Type │ Annotation │
├──────────────┼──────────────┼─────────────┼────────────┤
│ chr7:1407... │ V600E        │ PAAD        │ [OncoKB]   │
│              │              │             │ [αG •] <───┤ (Single compact badge:
└──────────────┴──────────────┴─────────────┴────────────┘  αG badge for BRAF
                                                            + alert dot '•' for collateral
                                                              neighbor disruption)
                      │ (Hover/Click)
                      ▼
┌────────────────────────────────────────────────────────┐
│ AlphaGenome Tooltip (`AlphaGenomeTooltipContent`)      │
├────────────────────────────────────────────────────────┤
│ Gene: BRAF | Model: alphagenome-v1                     │
│ Matched Tissue: Pancreas (UBERON:0001264)              │
│                                                        │
│ Output Type        Raw Score    Quantile    Dual-Gate  │
│ RNA_SEQ            0.0000       0.2167      -          │
│ SPLICE_SITES       0.0424       0.9912      Strong     │
├────────────────────────────────────────────────────────┤
│ ⚠ Collateral Neighbor Gene Impact (1 Mb Window)       │
│ • AGAP3 (124 kb upstream):                             │
│   - Significant RNA_SEQ dysregulation (Quantile: 0.995)│
│   - Splice site emergence (Raw: 0.52)                  │
└────────────────────────────────────────────────────────┘
```

1. **Table Cell (`AlphaGenomeCell.tsx`)**:
   - Maintains the single, compact `αG` badge.
   - If `significant_neighbor_impacts` is non-empty, adds an unobtrusive indicator (e.g. `αG⁺` or a colored accent dot).
   - Keeps table row height and column widths identical.
2. **Tooltip (`AlphaGenomeTooltipContent.tsx`)**:
   - Primary section displays canonical gene scores in the matched patient tissue.
   - Secondary collapsible section renders detected collateral neighbor impacts without crowding the table.

---

## 5. Phased Rollout Plan

- [ ] **Phase 1 (Sidecar)**: Implement `_scan_significant_neighbors(tidy, canonical_gene)` in `alphagenome-sidecar/app/scoring.py`.
- [ ] **Phase 2 (Backend)**: Add `significant_neighbor_impacts` to `AlphaGenome.java` model in `genome-nexus`.
- [ ] **Phase 3 (Frontend)**: Update `genome-nexus-ts-api-client` and wire tooltip rendering in `cbioportal-frontend`.
