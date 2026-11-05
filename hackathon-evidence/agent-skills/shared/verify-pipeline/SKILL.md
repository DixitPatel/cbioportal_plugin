---
name: verify-pipeline
description: Run end-to-end acceptance tests across alphagenome-sidecar, genome-nexus, genome-nexus-frontend, and cbioportal-frontend and export deterministic Muse trajectories.
---

# Verify Pipeline (`Verify`)

Use this skill to verify acceptance criteria across all workstreams (`W1`–`W5`) before merging worktrees or opening draft PRs.

## Verification Checklist

1. **W1 & W2 (`alphagenome-sidecar`)**:
   - Run `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v` in `alphagenome-sidecar`.
   - Verify `DDX41` (`5:176940011:C>T` -> `chr5:177513010:C>T`), `SMAD4` (`c.1520_1521del` -> `GAA>G`), `REF` mismatch rejection, canonical gene filtering, merged splicing score calculation, and verbatim quote verification.
2. **W3 (`genome-nexus`)**:
   - Run `JAVA_HOME=/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home mvn test -pl model,component,service -B` in `genome-nexus`.
   - Verify `?fields=alpha_genome` serialization, `CachedAlphaGenomeFetcher` MongoDB cache hit on second call, and `extractId` behavior.
3. **W4 (`cbioportal-frontend`)**:
   - Run `pnpm --filter react-mutation-mapper run build` and Jest unit tests for `AlphaGenomeCell` and `AlphaGenomeTooltipContent`.
4. **W5 (`genome-nexus-frontend`)**:
   - Run `CI=true yarn test --watchAll=false` and `yarn build` in `genome-nexus-frontend`.
5. **Provenance Export**:
   - Export deterministic session trajectories with `muse export --last --redacted --out <trajectory.json>` and record SHA-256 digests.
