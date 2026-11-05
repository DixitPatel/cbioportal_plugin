---
name: debugging
description: Reproduce build or test failures verbatim, isolate the root cause, apply a targeted fix, and verify with a regression test.
---

# Debugging (`.muse/skills/debugging.md`)

Use this skill when a build, type-check, or unit test fails during the **Tester <-> Implementer** loop.

## Workflow
1. **Reproduce Verbatim**:
   - Run the exact failing command with the pinned toolchain (`OpenJDK 11` for `genome-nexus`, `Node v22.18.0` for frontends, `Python 3.13 .venv` for `alphagenome-sidecar`) and capture the stack trace or compiler error.
2. **Isolate Root Cause**:
   - Trace the failing line, missing import, type mismatch, or serialization discrepancy against `workstreams/contracts/alpha_genome_schema.json`.
   - Do not guess or silence tests.
3. **Fix & Regression Check**:
   - Apply the minimal fix at the root cause.
   - Re-run the specific failing test first, then the full module test suite.
