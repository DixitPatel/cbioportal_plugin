# Workstream Verify: Pipeline Acceptance Tests (`verify-pipeline`)

- **Workstream ID**: `Verify`
- **Skill**: `verify-pipeline`
- **Target Repositories**: `alphagenome-sidecar`, `genome-nexus`, `cbioportal-frontend`, `genome-nexus-frontend`

---

## 1. Workstream Summary (As-Is from Proposal)

- **`Verify` — `verify-pipeline` (Acceptance Tests)**:
  Start the stack and check cache hits, `REF` rejection, and icon rendering before each PR.

---

## 2. Deliverables & Verification Criteria (As-Is from Proposal §3, §4)

### 3. Deliverables

1. Upstream PRs to `genome-nexus`, `cbioportal-frontend` and `genome-nexus-frontend` that implement §2.2, §2.4 and §2.5. In cBioPortal the feature is gated behind `show_alphagenome`. Genome Nexus returns the field only when `fields=alpha_genome` is requested.
2. The AlphaGenome scoring sidecar (`alphagenome-sidecar`), with its OpenAPI contract and a Docker Compose entry.
3. Build provenance: `AGENTS.md`, skills, plan and event log, with commit references for each workstream.

### 4. Technical & Engineering Verification Points

- **Wrong REF accepted**: The AlphaGenome API scores a variant even when its `REF` does not match GRCh38. Therefore, Genome Nexus checks each `REF` against the GRCh38 FASTA before scoring and rejects mismatches.
- **GRCh37 studies and indels**: AlphaGenome accepts GRCh38 only. §2.2 lifts each variant in memory with `htsjdk`, anchors indels, and rejects variants that do not map.
- **Tissue context**: Genome Nexus has no study or cancer-type context, so scores are stored per `ontology_curie`, and each UI chooses the tissue when it renders them.
- **API cost and latency**: Each unique variant needs one AlphaGenome call. A four-gene TCGA PAAD query (`KRAS`, `TP53`, `SMAD4`, `CDKN2A`) has 301 mutation rows and 158 unique variants. With a cold cache, the AlphaGenome icons render only after 158 calls. The MongoDB cache in §2.2 addresses this.
- **Public API feasibility (GSoC #139, goal 4)**: Measure call latency, cache hit rate and API usage on a TCGA PAAD study to compare the public API with self-hosting.

---

## 3. Additional Instructions for Muse

### Skill to Load
- **Skill**: `.agents/skills/verify-pipeline/SKILL.md` (`verify-pipeline`)

### End-to-End Verification & Provenance Export Commands
1. **Sidecar (`W1`/`W2`)**:
   ```bash
   cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar
   /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v
   ```
2. **Genome Nexus (`W1`/`W3`)**:
   ```bash
   export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
   export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
   cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus
   mvn test -pl model,component,service -B
   ```
3. **cBioPortal Frontend (`W4`)**:
   ```bash
   export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
   cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/cbioportal-frontend
   pnpm --filter react-mutation-mapper run build && pnpm run testPackages
   ```
4. **Genome Nexus Frontend (`W5`)**:
   ```bash
   export PATH="/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
   cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus-frontend
   CI=true yarn test --watchAll=false && yarn build
   ```
5. **Deterministic Session Export (`Deliverable 3`)**:
   ```bash
   /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/muse export \
     --last --redacted \
     --out "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/workstreams/trajectories/session_$(date +%Y%m%d).json"
   ```
