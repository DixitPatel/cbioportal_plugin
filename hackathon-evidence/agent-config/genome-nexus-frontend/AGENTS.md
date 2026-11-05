# AGENTS.md — Genome Nexus Frontend (`genome-nexus-frontend`)

Muse Code reads this file as project rules when running in `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus-frontend`.

## 1. Purpose & Workstream (`W5`)

React 16 / MobX 6 / TypeScript 4.3 web frontend (`:3088`) for the Genome Nexus Variant Page.
- **Skill to load**: `variant-page-view`, `alphagenome-terms`, `verify-pipeline`.
- **Goal (`W5`)**:
  1. Add `'alpha_genome'` to `DEFAULT_ANNOTATION_QUERY_FIELDS` in `src/config/configDefaults.ts`.
  2. Add `AlphaGenome.tsx` under `src/component/variantPage/` (and/or `functionalPrediction/AlphaGenome.tsx`) displaying one row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score`, and the affected gene, plus a cross-tissue bar chart and an `ontology_curie` tissue selector defaulting to the tissue with the strongest effect.
  3. Wire the `AlphaGenome` row into `src/component/variantPage/FunctionalGroups.tsx`.
  4. Display the non-clinical disclaimer `"Model prediction, not experimental evidence."`

## 2. Node v22.18.0 & Yarn Commands

Always prepend Node v22.18.0 to `PATH`:

```bash
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
```

- **Install Dependencies**: `yarn install --non-interactive`
- **Run Unit Tests**: `CI=true yarn test --watchAll=false`
- **Build Production Bundle**: `yarn build`
- **Start Dev Server (`:3088`)**: `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/startup_scripts/start_genome_nexus_frontend.sh`
