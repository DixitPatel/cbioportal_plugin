# Workstream W5: Variant Page View (`variant-page-view`)

- **Workstream ID**: `W5`
- **Skill**: `variant-page-view`
- **Target Repository**: `genome-nexus-frontend` (`workspace/genome-nexus-frontend`)
- **Language / Stack**: TypeScript / React / MobX

---

## 1. Workstream Summary (As-Is from Proposal)

- **`W5` — `variant-page-view` (`genome-nexus-frontend` · TypeScript)**:
  Add `alpha_genome` to `DEFAULT_ANNOTATION_QUERY_FIELDS` and add an `AlphaGenome` row with a tissue selector to `FunctionalGroups`.

---

## 2. Architecture and Implementation Details (As-Is from Proposal §2.5)

### 2.5 Genome Nexus Frontend (`genome-nexus-frontend`)

**Goal**: Add an interactive view of AlphaGenome predictions to the Genome Nexus Variant Page (`genome-nexus-frontend`).

- **Fetch**:
  Add `alpha_genome` to `DEFAULT_ANNOTATION_QUERY_FIELDS` (`src/config/configDefaults.ts`) and bump `genome-nexus-ts-api-client`, so `fetchVariantAnnotationGET` returns the typed field with the other annotations.
- **Component**:
  Add `AlphaGenome.tsx` under `src/component/variantPage/` and a row for it in the `FunctionalGroups` table.
- **Interactive view**:
  One row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score` and the affected gene, plus a bar chart across tissues for the selected output type. A tissue selector lists the `ontology_curie` values in the response. The page has no study context, so the default is the tissue with the strongest effect.

---

## 3. Deliverables & Technical Context (As-Is from Proposal §3, §4.1)

- **Deliverable**:
  - Upstream PR to `genome-nexus-frontend` implementing §2.5.
- **Tissue context**:
  - Genome Nexus has no study or cancer-type context, so scores are stored per `ontology_curie`, and each UI chooses the tissue when it renders them.

---

## 4. Additional Instructions for Muse

### Skill & Contracts to Load
- **Skills**: `.agents/skills/variant-page-view/SKILL.md` (`variant-page-view`) and `.agents/skills/alphagenome-terms/SKILL.md` (`alphagenome-terms`)
- **Contract**: `workstreams/contracts/alpha_genome_schema.json`

### Target Files in `workspace/genome-nexus-frontend`
1. `src/config/configDefaults.ts`: Add `'alpha_genome'` to `DEFAULT_ANNOTATION_QUERY_FIELDS`.
2. `src/component/variantPage/AlphaGenome.tsx`: Create interactive view displaying one row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score`, and the affected gene, a bar chart across tissues for the selected output type, an `ontology_curie` tissue selector defaulting to the tissue with the strongest effect, the disclaimer `"Model prediction, not experimental evidence."`, and curated literature rows when present.
3. `src/component/variantPage/FunctionalGroups.tsx`: Add the `AlphaGenome` row to the `FunctionalGroups` table.

### Build & Acceptance Test Commands (Node v22.18.0 + Yarn 1.22.22)
```bash
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus-frontend
CI=true yarn test --watchAll=false
yarn build
```
