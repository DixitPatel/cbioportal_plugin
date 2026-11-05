# Workstream W4: Annotation Cell and Hover View (`cbioportal-annotation-cell`)

- **Workstream ID**: `W4`
- **Skill**: `cbioportal-annotation-cell`
- **Target Repository**: `cbioportal-frontend` (`workspace/cbioportal-frontend`)
- **Language / Stack**: TypeScript / React / MobX

---

## 1. Workstream Summary (As-Is from Proposal)

- **`W4` — `cbioportal-annotation-cell` (`cbioportal-frontend` · TypeScript)**:
  Add the `ALPHA_GENOME` field and a separate fetch, then `AlphaGenomeCell` and its hover view, placed after the `reVUE` icon, gated by `show_alphagenome`.

---

## 2. Architecture and Implementation Details (As-Is from Proposal §2.4)

### 2.4 cBioPortal Frontend (`cbioportal-frontend`)

**Goal**: Add an AlphaGenome icon to the Annotation column of the Mutations Table, with a hover view of the predictions (`cbioportal-frontend`).

- **Separate fetch**:
  Add `ALPHA_GENOME = 'alpha_genome'` to `GENOME_NEXUS_ARG_FIELD_ENUM` and regenerate `genome-nexus-ts-api-client`. Add an `alphaGenomeAnnotations` promise in `ResultsViewPageStore` and `PatientViewPageStore` that requests `[ALPHA_GENOME]` only. This keeps cold-cache scoring out of the existing Genome Nexus request (`annotation_summary`, `hotspots`, `clinvar`, `signal`), so Hotspot and other annotation icons are not delayed. The patient view already fetches `MY_VARIANT_INFO` this way.
- **Annotation column icon**:
  Add `alphaGenome` to `IAnnotation` and fill it in `getAnnotationData()` from `alpha_genome`. Add `alphaGenomeAnnotations.isComplete` to the memoize condition. Add `AlphaGenomeCell` (`packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.tsx`), modeled on `RevueCell`, and render it after `reVUE` in `GenericAnnotation`. The icon shows `strong` or `moderate` when a score for the selected tissue (or a tissue-independent `SPLICE_SITES` score) passes both the quantile and raw-score gates. An unscored variant shows an empty slot.
- **Dual-gate label (project-defined, applied in the UI)**:
  `strong` or `moderate` only when both `|quantile_score| >= 0.99` and the raw score passes a minimum (`|LFC| >= 0.5` strong / `>= 0.1` moderate for `RNA_SEQ`; splice delta `>= 0.5` strong / `>= 0.2` moderate).
- **Hover view**:
  `AlphaGenomeTooltipContent` in `DefaultTooltip` shows one row per output type (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score`, `gene` and `track`. It also shows a bar chart across tissues for the selected output type (not for `SPLICE_SITES`, which has no tissue tracks) and a tissue selector. The default is the study's tissue, mapped from cancer type to UBERON (for example, `PAAD → UBERON:0001264`, pancreas), with the note *"Model prediction, not experimental evidence."*
- **Wiring and gate**:
  Add an `enableAlphaGenome` prop to `MutationTable` next to `enableRevue`. Add a legend entry to `AnnotationHeader`, and add sort and download support to `AnnotationColumnFormatter`. The feature is hidden by default. The `show_alphagenome` server property enables it, and the results view, `PatientViewMutationsTab` and `MutationTableWrapper` pass it through.

---

## 3. Deliverables & Technical Context (As-Is from Proposal §3, §4.1)

- **Deliverable**:
  - Upstream PR to `cbioportal-frontend` implementing §2.4. In cBioPortal the feature is gated behind `show_alphagenome`.
- **Tissue context**:
  - Genome Nexus has no study or cancer-type context, so scores are stored per `ontology_curie`, and each UI chooses the tissue when it renders them.

---

## 4. Additional Instructions for Muse

### Skill & Contracts to Load
- **Skills**: `.agents/skills/cbioportal-annotation-cell/SKILL.md` (`cbioportal-annotation-cell`) and `.agents/skills/alphagenome-terms/SKILL.md` (`alphagenome-terms`)
- **Contracts**: `workstreams/contracts/alpha_genome_schema.json` and `workstreams/contracts/oncotree_to_uberon.json`

### Target Files in `workspace/cbioportal-frontend`
1. `src/shared/constants.ts` & `packages/genome-nexus-ts-api-client`: Add `ALPHA_GENOME = 'alpha_genome'` to `GENOME_NEXUS_ARG_FIELD_ENUM` and update API client types.
2. `src/pages/resultsView/ResultsViewPageStore.ts` & `src/pages/patientView/PatientViewPageStore.ts`: Add separate `alphaGenomeAnnotations` `remoteData` promise requesting `[ALPHA_GENOME]` so cold-cache calls do not delay `reVUE` or shared Genome Nexus fields.
3. `packages/react-mutation-mapper/src/component/column/Annotation.tsx`: Add `alphaGenome` to `IAnnotation`, add `alphaGenomeAnnotations` parameter to `getAnnotationData()`, include `alphaGenomeAnnotations.isComplete` in the memoize condition, and render `AlphaGenomeCell` after `reVUE` in `GenericAnnotation`.
4. `packages/react-mutation-mapper/src/component/alphagenome/AlphaGenome.tsx`: Implement `AlphaGenomeCell` and `AlphaGenomeTooltipContent` modeled on `RevueCell` (`component/revue/Revue.tsx`), applying the dual-gate UI label, cross-tissue bar chart, OncoTree -> UBERON tissue selector (`PAAD` -> `UBERON:0001264`), `"Model prediction, not experimental evidence."` disclaimer, and `Lit N` literature badge/rows.
5. `src/shared/components/mutationTable/MutationTable.tsx`, `AnnotationColumnFormatter.tsx`, `column/annotation/AnnotationHeader.tsx`, `src/config/IAppConfig.ts`, and `src/config/serverConfigDefaults.ts`: Wire `enableAlphaGenome` and `show_alphagenome`.

### Build & Acceptance Test Commands (Node v22.18.0 + pnpm 10.33.0)
```bash
export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/cbioportal-frontend
pnpm --filter genome-nexus-ts-api-client run build
pnpm --filter react-mutation-mapper run build
pnpm run testPackages
```
