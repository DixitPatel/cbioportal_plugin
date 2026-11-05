# W1 Retrospective — Liftover and REF Check (2026-10-27/28)

Workstream: `WS-01` (`workstreams/W1_liftover_refcheck.md`) · Status: **complete, approved, PR on fork**
Branch `w1-liftover-refcheck` @ `79661b1` · [PR #1](https://github.com/DixitPatel/genome-nexus/pull/1) (base `master` @ `42b80a2`)

## What worked
- Approval-gated sub-steps (W1.1–W1.6) caught real bugs before sign-off; the two
  most valuable finds (gzipped-chain constructor, SNV/`-` length collision) both
  surfaced from tests, not review.
- Probing the live algorithm first paid off: a jshell/`LiftOver` probe pinned
  real lifted coordinates, and a throwaway SDK oracle (`/tmp/sdk_oracle_probe.py`,
  kept out of the repo) verified the Java port against `genome.normalize_variant`
  including its 9 `genome_test.py` regression rows.
- Final: `mvn test -pl model,component,service` green — new class 10/10,
  service summary 96/96, zero regressions.

## Corrections to the spec narrative (algorithm unaffected)
- The spec's SMAD4 note says the G anchor is at GRCh38 `chr18:51078327`. The real
  lift maps `18:48604697-48604698` → `chr18:51078327-51078328`, so G is at
  `51078326` = `liftedStart - 1`. The prescribed algorithm (anchor at
  `start - 1`, expect `GAA>G`) was correct; only the narrative coordinate was
  off by one. Test asserts `pos 51078326, GAA>G`.
- `min(alleles)` in the SDK prefix cap is lexicographic, but it is provably
  equivalent to shortest-length here (a proper-prefix string is always the
  lexicographic min), so the Java port's length-based cap is exact.

## Bugs the tests caught
1. `new LiftOver(InputStream, String)` cannot parse the gzipped chain
   (`SAM chain line has wrong number of fields`). Production now stages the
   classpath resource to a temp file and uses the probe-verified `LiftOver(File)`
   path; the test exercises that exact loader.
2. The SNV fast path checked `ref.length() == 1 && alt.length() == 1`, which is
   also true for MAF `-`/`T` — every indel failed REF-check. Now gated on
   non-`-` alleles; `-` always enters the normalization loop.

## Environment lessons (sandbox-specific, not repo problems)
- `~/.m2` is read-locked in-sandbox (lock-dir writes fail). Workaround used for
  every build: `-Dmaven.repo.local=/tmp/gn-m2-main
  -Dmaven.repo.local.tail=/Users/dixitpatel/.m2/repository`. Outside the
  sandbox the spec's plain commands work (user verified `mvn install`).
- The JVM could not resolve some Maven hosts (jitpack) while curl reached
  Central fine; htsjdk was seeded into `~/.m2` outside the sandbox. UCSC chain
  download timed out once, succeeded on retry — prefer retry before workaround.
- No git identity existed anywhere; set repo-local in `genome-nexus` only.
  `gh` token was invalid; user re-authenticated, then push + PR succeeded.

## Deliberate simplifications
- `IndexedFastaGrch38ReferenceSequenceResolver` N-pads negative starts (SDK
  parity) but lets reads past contig end throw instead of N-padding.
- The W1.1 remote-GCS-slice-FASTA option was designed but not implemented; only
  local indexed FASTA + in-memory stub exist.
- The default Spring constructor leaves the reference resolver `null` and fails
  fast — W3 must inject the real one.
