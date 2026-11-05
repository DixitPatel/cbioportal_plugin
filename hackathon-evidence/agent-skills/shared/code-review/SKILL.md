---
name: code-review
description: Review git diff, static types, contract conformance, and compliance rules before completing a workstream.
---

# Code Review (`.muse/skills/code-review.md`)

Use this skill during the **Reviewer** phase before marking any workstream complete in `.muse/state.json`.

## Review Checklist
1. **Diff & Scope Check (`git status --short && git diff`)**:
   - Only files belonging to the active workstream's target repository are modified.
   - `.env`, credentials, and unrelated files are untouched.
2. **Contract & Schema Conformance**:
   - JSON field names (`alpha_genome`, `variant`, `hg38_variant`, `merged_splicing_score`, `scores`, `literature`) match `workstreams/contracts/alpha_genome_schema.json`.
3. **Domain & Compliance Guards**:
   - `W1`: `REF` is verified against GRCh38 FASTA before scoring; rejected variants are neither scored nor cached.
   - `W2`: `tidy_scores` rows are filtered to the canonical gene; every literature quote is verified as a whitespace-normalized verbatim substring.
   - `W3`: `CachedAlphaGenomeFetcher` overrides `extractId(DBObject)` and `extractId(AlphaGenome)` to key `_id = variant`.
   - `W4` & `W5`: UI displays `"Model prediction, not experimental evidence."` and gates cBioPortal behind `show_alphagenome`.
4. **Tests & Build Green**:
   - Confirm the **Tester** ran the native build and unit tests with `exit_code == 0`.
