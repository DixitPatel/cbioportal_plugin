---
name: codebase-analysis
description: Explore repository structure, entry points, build manifests, and existing implementation precedents before planning or coding.
---

# Codebase Analysis (`.muse/skills/codebase-analysis.md`)

Use this skill during the **Planner** phase before modifying any files in a repository.

## Workflow
1. **Read Repository Manifests & Rules**:
   - Inspect `AGENTS.md`, `BUILD_SETUP.md`, and the build manifest (`pom.xml`, `package.json`, or `pyproject.toml`).
2. **Locate Precedent Implementations**:
   - In `genome-nexus`: inspect `MyVariantInfo` and `ClinVar` classes (`AnnotationField`, `VariantAnnotation`, `VariantAnnotationMixin`, `CachedMyVariantInfoFetcher`, `ClinvarVariantAnnotationEnricher`, `VariantAnnotationService`).
   - In `cbioportal-frontend`: inspect `RevueCell` (`packages/react-mutation-mapper/src/component/revue/Revue.tsx`), `Annotation.tsx`, `ResultsViewPageStore.ts`, and `PatientViewPageStore.ts`.
   - In `genome-nexus-frontend`: inspect `src/config/configDefaults.ts` and `src/component/variantPage/FunctionalGroups.tsx`.
   - In `alphagenome-sidecar`: inspect `app/main.py` and `tests/test_health.py`.
3. **Map Contract to Code**:
   - Cross-check field names and types against `workstreams/contracts/alpha_genome_schema.json` and `workstreams/contracts/sidecar_openapi.yaml`.
