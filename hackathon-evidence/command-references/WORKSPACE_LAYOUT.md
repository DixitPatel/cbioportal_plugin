# Project Workspace Layout Reference

**Root Directory**: `$PROJECT_ROOT`  
**Node.js Runtime**: v22.18.0 (`agentic-setup/bin/node-v22.18.0-darwin-arm64/bin`)  
**Package Managers**: pnpm 10.33.0 (cBioPortal monorepo), yarn 1.22.22 (Genome Nexus)  

---

## Directory Tree

```text
$PROJECT_ROOT
├── .DS_Store
├── .idea/                                  # IDE workspace settings
├── .venv/                                  # Root Python virtual environment
├── docs/                                   # All project documentation, brainstorms, and command guides
│   ├── brainstorm/                         # North Star Proposal & Agentic Architecture docs
│   ├── build_and_execution_commands.txt    # Full end-to-end multi-repo build and execution guide
│   ├── final/                              # Final deliverables & milestones documentation
│   ├── frontend_compilation_and_execution_commands.txt # Dedicated frontend compilation & dev guide
│   ├── old/                                # Archived planning and reference notes
│   ├── SERVICE_PORTS_AND_URLS.md           # Mirror of master service ports and sample URLs
│   └── workstreams/                        # Mirror of Muse workstream markdown specifications (W1–W5, Verify)
├── setup_commands.txt                      # Central system setup, dependency install & API key configuration
├── SERVICE_PORTS_AND_URLS.md               # Master reference for all ports, services and sample URLs
├── WORKSPACE_LAYOUT.md                     # This layout reference file
└── workspace/                              # Source code repositories, Muse workstreams & startup utilities
    ├── startup_scripts/                    # Dedicated service and dev-server startup scripts
    │   ├── start_alphagenome_sidecar.sh    # AlphaGenome FastAPI sidecar launcher (:8000)
    │   ├── start_cbioportal_frontend.sh    # cBioPortal frontend local dev launcher (https://localhost:3000)
    │   ├── start_genome_nexus_backend.sh   # Genome Nexus Spring Boot backend launcher (:38080)
    │   └── start_genome_nexus_frontend.sh  # Genome Nexus frontend local dev launcher (:3088)
    ├── workstreams/                        # Individual workstream markdown files for Muse orchestration
    │   ├── README.md                       # Orchestration overview & end-to-end sequence diagram
    │   ├── W1_liftover_refcheck.md         # W1: GRCh37->GRCh38 liftover & REF check (genome-nexus)
    │   ├── W2_alphagenome_sidecar.md       # W2: AlphaGenome variant scoring sidecar (alphagenome-sidecar)
    │   ├── W3_genome_nexus_enricher.md     # W3: alpha_genome field, MongoDB cache & enricher (genome-nexus)
    │   ├── W4_cbioportal_annotation_cell.md# W4: AlphaGenomeCell & hover view (cbioportal-frontend)
    │   ├── W5_variant_page_view.md         # W5: Variant Page AlphaGenome row (genome-nexus-frontend)
    │   └── Verify_pipeline.md              # Verify: End-to-end acceptance tests (verify-pipeline)
    ├── alphagenome/                        # Official Google DeepMind AlphaGenome Python SDK
    ├── alphagenome-sidecar/                # FastAPI scoring & tidy_scores summarization service (:8000)
    ├── cbioportal-frontend/                # cBioPortal Web Frontend monorepo (TypeScript / React / MobX / Rspack)
    ├── genome-nexus/                       # Genome Nexus Backend Engine (Java / Spring Boot / MongoDB, :38080)
    ├── genome-nexus-annotation-pipeline/   # Annotation Pipeline CLI (Java / Spring Batch / VCF)
    └── genome-nexus-frontend/              # Genome Nexus Web Frontend (TypeScript / React / MobX, :3088)
```

---

## Key Directories & Roles

| Path | Purpose |
| :--- | :--- |
| **`docs/`** | Central archive for all specifications, architectural proposals, command guides, and reference documents. |
| **`workspace/`** | Contains all cloned git repositories, Muse workstream definitions, and project-specific execution scripts. |
| **`workspace/workstreams/`** | Individual workstream `.md` specifications (`W1`–`W5`, `Verify`) located inside Muse's sandbox workspace root for direct orchestration access. |
| **`workspace/startup_scripts/`** | Convenience executable scripts for launching local frontend and backend dev services. |

---

## Service Ports Quick Reference

| Service | Host Port | Directory |
| :--- | :--- | :--- |
| **cBioPortal Frontend** | `https://localhost:3000` | `workspace/cbioportal-frontend` |
| **Genome Nexus Frontend** | `http://localhost:3088` | `workspace/genome-nexus-frontend` |
| **Genome Nexus Backend** | `http://localhost:38080` | `workspace/genome-nexus` |
| **Genome Nexus MongoDB** | `localhost:27017` | Docker (`gn-mongo`) |
| **AlphaGenome Sidecar** | `http://localhost:8000` | `workspace/alphagenome-sidecar` |
| **Muse / Repo Bridge** | `http://localhost:8005` | `agentic-setup/` |
| **n8n Automation** | `http://localhost:5678` | `agentic-setup/` |
| **AnythingLLM Desktop** | `http://localhost:3001` (`:8888` collector) | `/Applications/AnythingLLM.app` |
