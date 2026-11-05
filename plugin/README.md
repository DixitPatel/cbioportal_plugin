# plugin — install and run

Everything here is needed to run the demo. Nothing here is a record of how it
was built; that is in [`../hackathon-evidence/`](../hackathon-evidence/).

## Prerequisites

`git`, `curl`, Docker, Maven, JDK 11, Python 3.13. On macOS:

```bash
brew install maven openjdk@11 python@3.13
```

The `gn-mongo` image is amd64 only. On Apple Silicon, Docker runs it emulated, so
its first-start data import takes longer (up to ~15 min).

Node 22.18.0, pnpm and yarn are installed into the project by `bootstrap.sh`;
your system versions are left alone.

`bootstrap.sh --check` lists what is missing and changes nothing.

## Keys

The AlphaGenome key ships in `judges.env`. You supply only your Meta key:

```bash
./set_meta_key.sh    # input is hidden; stored in ../../agentic-setup/.env
```

`bootstrap.sh` asks for it too if it is missing. Verify it before you build:

```bash
./check_muse.sh      # expects OK for muse-wonder-1.0 and muse-spark-1.3
```

## Setup and run

The **Setup Agent** automates the build, service startup, and verification in the background, and can debug any issues that arise until the demo is ready.

### 1. Set Project Root and Prerequisites

First, set `PROJECT_ROOT` to define where `workspace/` and `agentic-setup/` will reside:

```bash
export PROJECT_ROOT="$(pwd)"
```

- **Meta Model API Key**: Set your Meta Model API key (AlphaGenome key is already in `judges.env`):
  ```bash
  ./set_meta_key.sh       # input is hidden; stored in $PROJECT_ROOT/agentic-setup/.env
  ./install_skills.sh     # registers setup-agent and demo-recovery skills
  ```
- **Muse Code CLI**: Ensure `muse` is in your `PATH` (e.g. `export PATH="$HOME/.local/bin:$PATH"`).

### 2. Start Muse Code and run the setup agent

```bash
# Interactive TUI (Recommended):
muse --provider meta --contributor-mode off --reasoning-effort high --trust-workspace
# In Muse Code prompt: "use the setup-agent skill to install the stack"

# Or one-shot headless execution:
muse exec --provider meta --contributor-mode off --reasoning-effort high --trust-workspace \
  "use the setup-agent skill to install the stack"
```

The agent runs the installation, builds, startup, and verification in the background, and debugs failures autonomously in a loop using `demo-recovery`. Once complete, it hands over the verified links:
- **cBioPortal Patient View**: `https://localhost:3000/patient?studyId=paad_tcga_pan_can_atlas_2018&caseId=TCGA-IB-AAUO`
- **Genome Nexus Variant Page**: `http://localhost:3088/variant/7:g.140453136A>T`
- **Genome Nexus API**: `http://localhost:38080/annotation/7:g.140453136A%3ET?fields=alpha_genome`

`start_all.sh` starts each service only after the previous one is healthy,
because Genome Nexus calls the sidecar on a cache miss. Logs go to
`workspace/logs/`.

## Layout

| Path | What |
|---|---|
| `bootstrap.sh` | one-time setup: clone, toolchain, dependencies |
| `start_all.sh` | ordered startup with health gates |
| `verify.sh` | six health checks, one exit code, each failure names its fix |
| `check_muse.sh` | Meta API key and endpoint smoke test |
| `install_skills.sh` | copy the skills to where Muse Code finds them |
| `set_meta_key.sh` | store your Meta key, input hidden, outside the repository |
| `judges.env` | environment with the AlphaGenome key; Meta key left blank |
| `run_tests.sh` | optional test run; advisory, never a gate |
| `contracts/` | the OncoTree→UBERON map, which is in no repository |
| `prebuilt/` | prebuilt Genome Nexus WAR (`web-4a86895-SNAPSHOT.war`), eliminating 15–25 min build |
| `repos.tsv` | the repositories and exact branches; the only source of truth |
| `lib/env.sh` | shared paths; detects platform, Homebrew prefix and JDK |
| `services/` | one script per service, each runnable on its own |
| `skills/setup-agent/` | Muse Code skill: install and bring up the stack |
| `skills/demo-recovery/` | Muse Code skill: diagnose a failing stack |
| `docs/BUILD_CONTEXT.md` | the whole picture, read first by the setup agent |
| `docs/DEMO.md` | the walkthrough |
| `docs/SERVICE_PORTS_AND_URLS.md` | every port, endpoint and sample URL |
| `docs/SETUP_COMMANDS.md` | the manual commands behind `bootstrap.sh` |

Nothing is hardcoded to one machine: `PROJECT_ROOT` is derived from the script
location, the Node tarball is chosen from `uname`, and the JDK is resolved
through `JAVA11_HOME`, Homebrew, or `/usr/libexec/java_home`.

## Branches

`repos.tsv` holds the exact branch per repository. Apart from the upstream
AlphaGenome SDK on `main`, nothing is on `main` or `master`:

| Repository | Branch |
|---|---|
| `alphagenome` | `main` (upstream SDK) |
| `alphagenome-sidecar` | `w6-muse-copilot` |
| `cbioportal-frontend` | `w6-muse-copilot` |
| `genome-nexus` | `w3-enricher` |
| `genome-nexus-frontend` | `w5-variant-page` |

`bootstrap.sh` asserts the branch after each clone and refuses to continue on an
existing checkout that is on the wrong one.

The forks also carry `feat/*` branches used for upstream pull requests. They are
squashed snapshots from 2026-11-02 and are 3 to 21 commits behind. Building from
one gives a stack where every service starts, `verify.sh` passes, and Ask Muse
is missing.

## Tests never block the demo

`run_tests.sh` is advisory and exits 0 even when a suite fails. Neither
`bootstrap.sh` nor `start_all.sh` calls it. `verify.sh` is the check that
decides whether the demo works.

```bash
./run_tests.sh             # offline suites
./run_tests.sh --network   # also the five tests that call GitHub and NCBI
```

Those five are deselected by default: an unauthenticated or proxied host gets a
403 or a rate limit, and the test then fails for a reason unrelated to this
code. `docs/BUILD_CONTEXT.md` section 7 lists the known test behaviour.

## When something breaks

`./verify.sh` names the failing service and its fix. For anything it cannot
place, ask Muse Code: *"verify.sh says the GN backend has no alpha_genome — use
the demo-recovery skill."*

## Known limits

- Happy paths first. A failed model call falls back to an offline answer, labelled as such.
- The cBioPortal dev server uses a self-signed certificate: accept it once per browser.
- AlphaGenome Atlas (precomputed AVI scores) is researched but not wired in.
- `--with-pipeline` clones and builds the Genome Nexus annotation pipeline. It is not needed for the demo and is slow.
