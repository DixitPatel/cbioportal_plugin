# Onco-Muse: Meta Muse for Cancer genomics
_Built for the Meta hackathon, Nov 2026_

This repository builds:<br> 
a. AlphaGenome variant-effect scoring pipeline with liftover and other references for genome-nexus annotation pipeline<br>
b. An **Ask Muse** co-pilot inside the cBioPortal patient view. Muse Wonder answers
questions about cancer study data: citation-ranked PubMed evidence, OncoTree→UBERON tissue mapping, and a
ready-to-run AlphaGenome Colab notebook built for the variant on screen.

_Query Pubmed takes some time due to rate limit on NCBI_

PR raised on Genome Nexus: https://github.com/DixitPatel/genome-nexus/pull/3


| Folder | For whom |
|---|---|
| **[`plugin/`](plugin/)** | Judges and researchers. Everything needed to install and run the stack locally. |
| **[`hackathon-evidence/`](hackathon-evidence/)** |How the work was done: workstream specs, agent configuration, verification reports, command references |

## Setup


### 1. Set Project Root and Prerequisites

First, set `PROJECT_ROOT` in your current working directory where cloned repositories, setup, and logs will reside:

```bash
export PROJECT_ROOT="$(pwd)"
```
Clone Repo
```bash
git clone https://github.com/DixitPatel/cbioportal_plugin
```
- **Meta Model API Key**: Ask Muse requires your personal Meta Model API key. The AlphaGenome API key is already provided in `plugin/judges.env`.
- **Muse Code CLI**: Ensure `muse` is in your `PATH` (e.g. `export PATH="$HOME/.local/bin:$PATH"`).

### 2. Configure key and install skills

```bash
git clone https://github.com/DixitPatel/cbioportal_plugin.git
cd cbioportal_plugin/plugin
./set_meta_key.sh       # input is hidden; stored in $PROJECT_ROOT/agentic-setup/.env
./install_skills.sh     # registers setup-agent and demo-recovery skills
```

### 3. Start Muse Code and run the setup agent
_First run takes ~3–5 minutes (prebuilt Genome Nexus WAR included; only gn-mongo reference data initializes); subsequent runs take ~3 minutes._

Run Muse Code either interactively in TUI mode or headless as a one-shot command:

**Option A — Interactive TUI (Recommended):**
```bash
muse \
  --provider meta \
  --contributor-mode off \
  --reasoning-effort high \
  --trust-workspace
```
Prompt the agent:
> *"use the setup-agent skill to install the stack. Skill file at: cbioportal_plugin/plugin/skills/setup-agent/SKILL.md"*

**Option B — Headless Execution (One-shot command):**
```bash
muse exec \
  --provider meta \
  --contributor-mode off \
  --reasoning-effort high \
  --trust-workspace \
  "use the setup-agent skill to install the stack"
```


```
cBioPortal page view: https://localhost:3000/patient?studyId=paad_tcga_pan_can_atlas_2018&caseId=TCGA-IB-AAUO
```
```
Genome Nexus Variant Page: http://localhost:3088/variant/7:g.140453136A>T (interactive AlphaGenome functional group card)
Genome Nexus Backend API: http://localhost:38080/annotation/7:g.140453136A>T?fields=alpha_genome
```

## After Installation

Run in Browser:
1. `https://localhost:3000/patient/summary?sampleId=SP55711&studyId=pancan_pcawg_2020`
2. Click on score variants
3. Click Ask Muse
4. Then follow [`plugin/docs/DEMO.md`](plugin/docs/DEMO.md) for the walkthrough.

## What it is made of

| Service | Port | Role |
|---|---|---|
| gn-mongo | 27017 | annotation cache |
| AlphaGenome sidecar | 8000 | variant scoring, Ask Muse routes, Colab parameters |
| Genome Nexus backend | 38080 | annotation API, serves the `alpha_genome` field |
| Genome Nexus frontend | 3088 | variant page |
| cBioPortal frontend | 3000 | patient view, Ask Muse window |



| Repository | Branch |
|---|---|
| `google-deepmind/alphagenome` | `main` (unmodified upstream SDK) |
| `DixitPatel/alphagenome_sidecar` | `w6-muse-copilot` |
| `DixitPatel/cbioportal-frontend` | `w6-muse-copilot` |
| `DixitPatel/genome-nexus` | `w3-enricher` |
| `DixitPatel/genome-nexus-frontend` | `w5-variant-page` |

## Backup commands

```bash
git clone https://github.com/DixitPatel/cbioportal_plugin.git
cd cbioportal_plugin/plugin
./set_meta_key.sh                             # your Meta key; input hidden
./check_muse.sh                               # confirm the Meta key first
./bootstrap.sh --check                        # what is missing, changes nothing
./bootstrap.sh                                # clone repos, install everything
./start_all.sh                                # start the stack, health-gated
./verify.sh                                   # exit 0 means the demo works
```

Then follow [`plugin/docs/DEMO.md`](plugin/docs/DEMO.md).
