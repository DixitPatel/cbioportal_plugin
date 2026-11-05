---
name: variant-page-view
description: Add interactive AlphaGenome regulatory predictions and curated literature rows to the Genome Nexus Variant Page in genome-nexus-frontend.
---

# Genome Nexus Variant Page View (`W5`)

Use this skill when adding the `AlphaGenome` prediction view and curated literature panel to `genome-nexus-frontend`.

## Implementation Steps

1. **Default Query Fields (`src/config/configDefaults.ts`)**:
   - Add `'alpha_genome'` to `DEFAULT_ANNOTATION_QUERY_FIELDS` so `VariantStore` fetches `alpha_genome` alongside existing annotations.
2. **Variant Page Component (`src/component/variantPage/AlphaGenome.tsx` or `functionalPrediction/AlphaGenome.tsx`)**:
   - Render one row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) displaying `raw_score`, `quantile_score`, and the affected canonical gene.
   - Render a bar chart across tissues for the selected tissue-aware output type (`RNA_SEQ`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`).
   - Provide a tissue selector listing the `ontology_curie` values present in the response. Because the Variant Page has no study context, default to the tissue with the strongest effect.
   - Display the non-clinical notice `"Model prediction, not experimental evidence."` and, when literature synthesis is present, render the curated papers (`PMID`, `claim`, verified `quote`), excluded PMIDs, and `source_query`.
3. **FunctionalGroups Wiring (`src/component/variantPage/FunctionalGroups.tsx`)**:
   - Add the `AlphaGenome` row to the `FunctionalGroups` table.

## Build & Test Commands (Node v22.18.0 + Yarn 1.22.22)

```bash
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus-frontend
CI=true yarn test --watchAll=false
yarn build
```
