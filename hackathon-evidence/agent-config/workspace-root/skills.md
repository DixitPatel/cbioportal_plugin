# Skills

Agents must only use skills listed here. Each skill has a markdown definition in `.muse/skills/` and a validated Muse Code project skill package in `.agents/skills/<skill-id>/SKILL.md`.

---

## Core Engineering Skills (`.muse/skills/`)

### `codebase-analysis` - `.muse/skills/codebase-analysis.md`
Explore repository structure, entry points, build manifests (`pom.xml`, `package.json`, `pyproject.toml`), and existing precedents (such as `MyVariantInfo` in `genome-nexus` or `RevueCell` in `cbioportal-frontend`) before planning or coding.

### `tdd` - `.muse/skills/tdd.md`
Write or update failing unit/contract tests first $\rightarrow$ implement minimal code to pass $\rightarrow$ refactor while keeping all tests green.

### `debugging` - `.muse/skills/debugging.md`
Reproduce test or build failure verbatim $\rightarrow$ isolate root cause $\rightarrow$ apply minimal fix $\rightarrow$ verify with regression test.

### `code-review` - `.muse/skills/code-review.md`
Review `git status` and `git diff` against `workstreams/contracts/`, static type-checkers, linters, and security/compliance checklists.

---

## Workstream Domain Skills (`.muse/skills/` & `.agents/skills/`)

### `liftover-refcheck` - `.muse/skills/liftover-refcheck.md` | `.agents/skills/liftover-refcheck/SKILL.md`
Lift GRCh37 variants to GRCh38 (`htsjdk LiftOver` with `hg19ToHg38.over.chain.gz`), normalize MAF indels (`-`) to left-aligned VCF anchor-base form, verify `REF` against the GRCh38 FASTA, extract the canonical transcript gene (`geneId`, `geneSymbol`), and reject failed variants without scoring or caching (`WS-01` / `W1`).

### `alphagenome-sidecar` - `.muse/skills/alphagenome-sidecar.md` | `.agents/skills/alphagenome-sidecar/SKILL.md`
Wrap `dna_client.score_variant()` in FastAPI `POST /score` with a 1 Mb (`1,048,576` bp) window and the four recommended scorers (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`), run `tidy_scores` locally, filter to the canonical gene, compute the per-gene merged splicing score, and curate variant literature (`WS-02` / `W2`).

### `genome-nexus-enricher` - `.muse/skills/genome-nexus-enricher.md` | `.agents/skills/genome-nexus-enricher/SKILL.md`
Implement the 8-file `alpha_genome` post-enricher and `CachedAlphaGenomeFetcher` (`alphagenome.annotation` collection, `max_page_size=1`, `extractId` overrides) in `genome-nexus` following `MyVariantInfo` (`WS-03` / `W3`).

### `cbioportal-annotation-cell` - `.muse/skills/cbioportal-annotation-cell.md` | `.agents/skills/cbioportal-annotation-cell/SKILL.md`
Add `ALPHA_GENOME = 'alpha_genome'` and a separate `alphaGenomeAnnotations` fetch, then implement `AlphaGenomeCell` and `AlphaGenomeTooltipContent` after `reVUE`, gated by `show_alphagenome` (`WS-04` / `W4`).

### `variant-page-view` - `.muse/skills/variant-page-view.md` | `.agents/skills/variant-page-view/SKILL.md`
Add `alpha_genome` to `DEFAULT_ANNOTATION_QUERY_FIELDS` and add an interactive `AlphaGenome` row with a tissue selector and bar chart to `FunctionalGroups` in `genome-nexus-frontend` (`WS-05` / `W5`).

### `verify-pipeline` - `.muse/skills/verify-pipeline.md` | `.agents/skills/verify-pipeline/SKILL.md`
Run end-to-end acceptance tests across Python, Java, and TypeScript repositories, verify cache hits and `REF` mismatch rejection, and export deterministic session trajectories (`WS-06` / `Verify`).

### `ncbi-etiquette` - `.agents/skills/ncbi-etiquette/SKILL.md`
Enforce NCBI E-Utilities / LitVar 2.0 rate limits, required query parameters (`tool`, `email`), `efetch` PMID verification, and verbatim substring quote verification.

### `alphagenome-terms` - `.agents/skills/alphagenome-terms/SKILL.md`
Enforce Meta Muse Standard mode (`--contributor-mode off`), non-training rules on AlphaGenome outputs, and the UI disclaimer `"Model prediction, not experimental evidence."`

---

## PR Agent Skills (`.muse/skills/` & `.agents/skills/`)

### `pr-squash-commits` - `.muse/skills/pr-squash-commits.md` | `.agents/skills/pr-squash-commits/SKILL.md`
Analyze branch commit history against base (`master`/`main`), generate a structured candidate stub message adhering to the 7 rules of great commit messages, prompt the user for direction and custom editing, and squash cleanly into a single commit with safety backup.

### `code-convention-aligner` - `.muse/skills/code-convention-aligner.md` | `.agents/skills/code-convention-aligner/SKILL.md`
Audit and align code conventions, comment styles, and formatting across repositories (Prettier, `.editorconfig`, LF endings, 4-space indent). Enforce comments explaining current code intent rather than historical change logs, and eliminate dead commented-out code and stray debug statements.

### `pr-description-generator` - `.muse/skills/pr-description-generator.md` | `.agents/skills/pr-description-generator/SKILL.md`
Review sample PRs from target repository git history and `.github/PULL_REQUEST_TEMPLATE.md`, analyze git diffs to isolate only the additions made in this PR, and generate structured descriptions with Problem, Solution, precise Implementation Details, Verification commands, and Compliance Checklists.

