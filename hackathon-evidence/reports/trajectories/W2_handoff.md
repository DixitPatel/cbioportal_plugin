# Handoff — From W1 to W2 and Beyond

## Where things stand
- **W1 (`WS-01`) is done**: approved, committed (`79661b1` on
  `w1-liftover-refcheck`), PR open as
  [DixitPatel/genome-nexus#1](https://github.com/DixitPatel/genome-nexus/pull/1).
  `.muse/state.json`: `WS-01 = complete/approved`, `activeWorkstream = null`.
  Provenance: `workstreams/trajectories/event_log.jsonl`.
- **W2–W5, Verify are pending** and blocked until their predecessors are
  approved, per `workstreams.md`. Next up: W2 (`alphagenome-sidecar`,
  skill `alphagenome-sidecar`, spec `workstreams/W2_alphagenome_sidecar.md`).

## W1 contract for downstream consumers
- Entry point: `AlphaGenomeVariantNormalizer.normalize(VariantAnnotation)`
  (`component/.../annotation/`) → `Optional<NormalizedAlphaGenomeVariant>`.
- Guarantees: GRCh38 `chr`-prefixed coords, VCF anchor-base left-aligned alleles
  (SDK `normalize_variant` semantics), `REF` verified against GRCh38
  (`Optional.empty()` = do-not-score/do-not-cache), canonical `geneId`
  (version stripped) + `geneSymbol`, `variantStr` as `chr:pos:REF>ALT`.
  Never reads `getHgvsg()`.
- W3 needs to inject a real `Grch38ReferenceSequenceResolver` (local indexed
  FASTA path or the designed-but-unbuilt GCS slice fetcher); the default bean
  fails fast without one. The in-memory stub is test-only.

## Environment notes for the next session
- OpenJDK 11 (`/opt/homebrew/opt/openjdk@11/...`) for `genome-nexus`;
  Python 3.13 venv at `agentic-setup/.venv/bin/python` for the sidecar.
- In-sandbox Maven builds need the writable-repo overlay flags (see
  retrospective); plain spec commands work outside the sandbox.
- Git identity is repo-local in `genome-nexus`; fork remote is named `fork`;
  `gh` auth is currently valid.

## Suggested W2 kickoff (when asked)
1. Read `muse.config.json`, `agents.md`, `skills.md`, `workstreams.md`,
   `.muse/state.json`, and `workstreams/W2_alphagenome_sidecar.md` (not yet read
   this session — do not assume its contents).
2. Run W2.1 as Planner with the `alphagenome-sidecar` skill, read-only, and
   present the design for approval before any implementation — same gate
   discipline as W1.
