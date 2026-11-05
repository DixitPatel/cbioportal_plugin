---
name: tdd
description: Drive workstream implementation with red-green-refactor unit and contract tests across Python, Java, and TypeScript.
---

# Test-Driven Development (`.muse/skills/tdd.md`)

Use this skill during the **Implementer** and **Tester** phases.

## Red -> Green -> Refactor Loop
1. **Red (Write Failing Test First)**:
   - Write a unit or contract test encoding the workstream's acceptance criteria (e.g., `DDX41` liftover, `SMAD4` indel normalization, `REF` mismatch rejection, canonical gene row filtering, `CachedAlphaGenomeFetcher` cache hit, or `AlphaGenomeCell` dual-gate rendering).
   - Run the test runner to confirm the test fails for the expected reason.
2. **Green (Minimal Implementation)**:
   - Write the smallest clean code change that satisfies the test and adheres to `workstreams/contracts/`.
   - Re-run the test suite using the pinned toolchain (`pytest`, `mvn test`, `yarn test`, or `pnpm run testPackages`).
3. **Refactor**:
   - Clean up duplication, imports, and formatting while keeping all existing and new tests green.
