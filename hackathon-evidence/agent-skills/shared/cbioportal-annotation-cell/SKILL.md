---
name: cbioportal-annotation-cell
description: Implement the AlphaGenome annotation column icon, dual-gate label, tissue-aware hover tooltip, and separate store fetch in cbioportal-frontend.
---

# cBioPortal Annotation Cell & Hover View (`W4`)

Use this skill when adding the `AlphaGenome` annotation column icon, tooltip, and separate Genome Nexus fetch in `cbioportal-frontend`.

## Implementation Steps

1. **Separate Genome Nexus Fetch**:
   - Add `ALPHA_GENOME = 'alpha_genome'` to `GENOME_NEXUS_ARG_FIELD_ENUM` in `src/shared/constants.ts` and update `packages/genome-nexus-ts-api-client`.
   - Add an `alphaGenomeAnnotations` `remoteData` promise in `ResultsViewPageStore` and `PatientViewPageStore` requesting `[ALPHA_GENOME]` separately so cold-cache scoring does not delay `reVUE` or shared Genome Nexus annotations (`annotation_summary`, `hotspots`, `clinvar`, `signal`).
2. **Annotation Data Wiring**:
   - Add `alphaGenome?: AlphaGenomeAnnotation` to `IAnnotation` in `packages/react-mutation-mapper/src/component/column/Annotation.tsx`.
   - Add an `alphaGenomeAnnotations` parameter to `getAnnotationData()` and include `alphaGenomeAnnotations.isComplete` in the memoize condition.
3. **Cell & Hover Tooltip (`packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.tsx`)**:
   - Model `AlphaGenomeCell` and `AlphaGenomeTooltipContent` on `RevueCell` (`component/revue/Revue.tsx`) and render `AlphaGenomeCell` immediately after `reVUE` in `GenericAnnotation`.
   - **Dual-Gate UI Label**: Show a `strong` or `moderate` label only when both `|quantile_score| >= 0.99` AND the raw score passes its minimum (`|LFC| >= 0.5` strong / `>= 0.1` moderate for `RNA_SEQ`; delta `>= 0.5` strong / `>= 0.2` moderate for `SPLICE_SITES` and `SPLICE_SITE_USAGE`).
   - **Hover View**: Render one summary row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score`, `gene`, and `track`, plus a cross-tissue bar chart (for tissue-specific scorers) and a tissue selector defaulting to the study's OncoTree-mapped UBERON tissue (e.g., `PAAD` -> `UBERON:0001264`, pancreas).
   - Always display the disclaimer `"Model prediction, not experimental evidence."` and render curated literature rows (`Lit N` badge with PubMed link, claim, and verified quote) when present.
4. **Table & Config Gate**:
   - Add `enableAlphaGenome` prop to `MutationTable`, legend entry to `AnnotationHeader`, and sort/download handlers to `AnnotationColumnFormatter.tsx`.
   - Gate behind `show_alphagenome` in `IAppConfig.ts` and `serverConfigDefaults.ts`.

## Build & Test Commands (Node v22.18.0 + pnpm 10.33.0)

```bash
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/cbioportal-frontend
pnpm --filter genome-nexus-ts-api-client run build
pnpm --filter react-mutation-mapper run build
pnpm run testPackages
```
