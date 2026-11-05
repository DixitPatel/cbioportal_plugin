---
name: toolchain_and_services
description: Exact paths to Node v22.18.0, OpenJDK 11, OpenJDK 21, Python 3.13 venv, and local service ports.
type: reference
---

# Toolchain Paths & Service Ports

## Pinned Binaries
- **Node.js v22.18.0 (`node`, `npm`, `pnpm` 10.33.0, `yarn` 1.22.22)**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin`
- **Python 3.13 Virtual Environment (`python`, `pip`, `pytest`, `uvicorn`)**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin`
- **OpenJDK 11 (`genome-nexus`)**:
  `/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home`
- **OpenJDK 21 (`genome-nexus-annotation-pipeline`)**:
  `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`
- **Muse Code CLI (v1.4.13)**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/bin/muse`

## Active Service Ports
- **cBioPortal Frontend**: `https://localhost:3000`
- **Genome Nexus Frontend**: `http://localhost:3088`
- **Genome Nexus Backend (Docker/Local)**: `http://localhost:38080`
- **Genome Nexus MongoDB (`gn-mongo`)**: `mongodb://127.0.0.1:27017/annotator`
- **AlphaGenome Scoring Sidecar**: `http://localhost:8000`
