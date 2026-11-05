# PR Finalization Reference — AlphaGenome workstream → cbioportal repos

How to take our four work branches to merge-ready PRs against the
cBioPortal / genome-nexus upstreams, modeled on
[apache/datafusion-comet#7289](https://github.com/apache/datafusion-comet/pull/7289)
(structure + content quality), fitted to each repo's own gates.

Scope: 3 upstream PRs — `cbioportal-frontend` (`w4-annotation-cell`),
`genome-nexus` (`w3-enricher`), `genome-nexus-frontend` (`w5-variant-page`).
`alphagenome-sidecar` is ours (no upstream PR); it is a stack dependency, not a deliverable here.

## 1. What the reference PR does (replicate this shape)

- **Title as conventional commit:** `feat: prototype Comet Native Executors`.
  Ours: `feat: AlphaGenome annotation column (patient view)` /
  `feat: AlphaGenome variant normalization + sidecar scoring` /
  `feat: AlphaGenome variant page view`.
- **Honest status line:** Draft + "not meant to merge as is". Ours are meant
  to merge — say so, and say what is deliberately deferred instead.
- **Issue link + stack plan up front:** closes-issue link, stacked PR link,
  rebase plan ("first N commits belong to #X; will rebase once it merges").
  Ours is a 4-deep stack: sidecar → genome-nexus → cbioportal-frontend +
  genome-nexus-frontend. Each upstream PR body names its parent and the
  rebase plan.
- **Sections, in order:** Rationale → What changes (numbered areas, bulleted
  detail) → What works → Not yet (each item a linked sub-issue) →
  Defaults-unchanged statement → Testing (per area: suite name, coverage
  list, pass counts, data scale, both modes, exact run command).
- **Scale honesty:** 28 commits disclosed, not hidden. Ours: 7 / 9 / 3
  commits pre-squash (see §3).
- **CI named in body:** clippy + fmt lint job + dedicated CI job. Ours: name
  the exact gate commands from §4 in the body.

## 2. PR body template (cbioportal's template + reference sections)

`.github/PULL_REQUEST_TEMPLATE.md` (cbioportal-frontend; genome-nexus(-frontend)
have none — use this shape for all three):

1. `Related to cBioPortal/cbioportal#<n>` or `Related to
   genome-nexus/genome-nexus#<n>` (file the tracking issue first if none
   exists). Never use `Fix` / closing keywords — house rule, avoids
   auto-closing issues.
2. `Describe changes proposed in this pull request:` → the reference
   Rationale / What-changes / What-works / Not-yet sections.
3. `## Checks` — all four boxes must be closable:
   - tests included, or a separate issue describing the tests to create
     (if no test: say explicitly why not);
   - comprehensible log: single squashed commit, no merge commits (rebase);
   - clinical-attribute logic → backend validation + File-Formats docs
     (our work adds no clinical attributes — state that);
   - screenshots/GIFs for visual features (both frontend PRs are visual:
     before/after required).
4. `## Notify reviewers` — `git blame` the touched files, assign prior
   authors. Do this per PR, not once globally.
5. Replicate "Defaults-unchanged": our flags default off
   (`show_alphagenome` gating), cold tables render as before until the user
   triggers scoring. Say it in one line.
6. Replicate "Not yet → sub-issues": file our TBDs as issues and link them —
   TBD-33 (test seam in production), TBD-48 (drop HTTP-range resolver?),
   TBD-83-code (descending tissue ranking), TBD-84 (model-shim re-review),
   score-button spec vs flag-off null.

## 3. Commit squash plan (you run these; history rewrites are yours)

Template rule: single commit per PR, no merge commits, rebase only.
Squash point is `origin/master` in all three repos (verify with
`git log --oneline origin/master..HEAD` before starting).

- **cbioportal-frontend** — 7 commits → 1 (`867ca64b8` … `69c1c6a4c`):
  `git rebase -i origin/master` → squash into one `feat:` commit.
- **genome-nexus** — 9 commits → 1 (`79661b1` … `0403d54`, includes
  whitespace-only `ac751b6` which vanishes into the squash).
- **genome-nexus-frontend** — 3 commits → 1 (`feda527`, `e9c598b`, `cfd48a0`).
- Message follows §1 title + a `why` body (reference skill:
  `docs:`/`feat:` type, short description, intent not mechanics).
- Never mix the squash with the concurrent Task-C code still landing in
  `genome-nexus` — squash only when that tree is quiet, or the squash
  will swallow someone else's work.

## 4. Formatting + test verification (exact gates, run pre-PR)

- **cbioportal-frontend**
  - `pnpm exec prettier -c $(git diff origin/master...HEAD --name-only --diff-filter=d)`
    (repo's own `prettierCheckCircleCI` shape; fix with `prettier --write`).
  - `pnpm run typecheck` (`tsc --noEmit`).
  - `jest` for touched areas (`react-mutation-mapper` AlphaGenome specs,
    patient-view and results-view suites).
  - Generated-client diff (`packages/genome-nexus-ts-api-client/.../GenomeNexusAPI.ts`)
    must be regenerable via `pnpm run updateGenomeNexusAPI` — never hand-edit;
    say in the PR body that it is regenerated output.
- **genome-nexus**
  - `mvn -DskipTests clean install`, then `mvn test` (CircleCI shape;
    tests need Mongo — `dockerize -wait tcp://localhost:27017` per
    `.circleci/config.yml`; Travis shape is `mvn clean install`).
  - No formatter plugin in `pom.xml` — match surrounding style by eye
    (4-space Javadoc, sentence case); the hygiene pass already did this.
- **genome-nexus-frontend**
  - `pnpm run test-prettier` (`prettier -c './src/**'`; fix with `pnpm run prettier`).
  - Component tests (`react-scripts test`) + production `build`.
- Record each gate's result in the PR body under Testing (reference style:
  suite, coverage, counts, scale, run command) — not "CI will tell us".

## 5. Order of operations

1. Land or freeze the concurrent Task-C code in `genome-nexus`.
2. Run §4 gates per repo; fix, don't waive.
3. Squash per §3; re-verify `git log origin/master..HEAD` shows one commit.
4. File tracking + TBD sub-issues; write bodies per §2.
5. Open PRs bottom-up (genome-nexus → frontends), each naming its parent
   and rebase plan per the reference stacking pattern.
6. Assign reviewers from `git blame` per the template's notify rule.
