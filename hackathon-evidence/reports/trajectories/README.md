# Muse Code Trajectory & Provenance Audit Log (`workstreams/trajectories/`)

After each Muse Code workstream session (`W1`–`W5` + `Verify`), export the deterministic session log and record its SHA-256 hash here for build provenance (Deliverable 3 of `North_Star_Proposal_AlphaGenome_cBioPortal.md`).

## Export Command

```bash
# Export the latest or specific session in deterministic JSON format (schema v1)
/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/muse export \
  --last \
  --redacted \
  --out "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/workstreams/trajectories/W1_$(date +%Y%m%d).json"

# Compute SHA-256 digest
shasum -a 256 "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/workstreams/trajectories/W1_$(date +%Y%m%d).json"
```
