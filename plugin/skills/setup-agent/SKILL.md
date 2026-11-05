---
name: setup-agent
description: Install, bring up, and debug the cBioPortal Ask Muse demo stack from scratch in an autonomous loop until verified. Use when asked to set up, install, bootstrap, start, or repair the stack.
---

# Setup agent

You install the stack and hand back a working demo. You do not write product
code, you do NOT run or add test suites (skip `pytest`, `tests/test_copilot.py`, and `run_tests.sh`), and you do not edit any cloned repository. The only verification required is `./verify.sh`.

## Step 0 — read the context first

Read `plugin/docs/BUILD_CONTEXT.md` (or `docs/BUILD_CONTEXT.md` if already inside `plugin/`) end to end before running anything. It
holds the service order, the repository and branch list, the two keys, the
paths the sidecar resolves outside its own repo, the model protocol, the
first-run timings and the stop conditions. Everything below assumes you have
read it.

Ensure `PROJECT_ROOT` is set:
```bash
export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
```

Do not skip this because the commands look obvious. The traps in that document
are the ones that have already cost time, and most of them fail silently.

## Step 1 — keys before build

The AlphaGenome key ships in `plugin/judges.env`. The Meta key does not: it is
personal and you must ask the user for it. Nothing else proceeds until it is in.

Ask the user, in these words or close to them:

> Ask Muse needs your Meta Model API key. The
> safest way is to run this yourself in a terminal — the input is hidden and
> the key never passes through this chat:
>
> `cd plugin && ./set_meta_key.sh`   # or simply `./set_meta_key.sh` if already in plugin/
>
> Tell me when it is done.

`set_meta_key.sh` creates `agentic-setup/.env` from `judges.env` on first run
and stores the key there, outside the repository.

If the user pastes the key into the chat instead, store it without echoing:

```bash
[[ -d plugin ]] && cd plugin
printf '%s' '<the key>' | ./set_meta_key.sh --stdin
```

Then never repeat it — not in a message, a summary, a command you show, or a
log. Refer to it only as "your Meta key".

Then confirm it works before building anything:

```bash
./check_muse.sh
```

Both models must return OK. A 401 is a bad key. A 404 means the wrong path —
only `{base}/chat/completions` exists. Do not build before this passes: a bad
key wastes the entire build.

Never print a key value, in a message or a log.

## Step 2 — preflight

```bash
./bootstrap.sh --check
```

Changes nothing; lists what is missing. Report the list. On macOS the usual fix
is `brew install maven openjdk@11 python@3.13`. Node, pnpm and yarn are
installed into the project by `bootstrap.sh`, so do not touch the system ones.

## Step 3 — install

```bash
./bootstrap.sh
```

Clones the five repositories listed in `plugin/repos.tsv`, then installs the
toolchain and every dependency. 10–20 minutes.

The exact branches, none of which is `main` or `master` except the upstream SDK:

| Repository | Branch |
|---|---|
| `alphagenome` | `main` (unmodified upstream SDK) |
| `alphagenome-sidecar` | `w6-muse-copilot` |
| `cbioportal-frontend` | `w6-muse-copilot` |
| `genome-nexus` | `w3-enricher` |
| `genome-nexus-frontend` | `w5-variant-page` |

`bootstrap.sh` reads `repos.tsv` and asserts the checked-out branch after every
clone, so it cannot drift.

If a clone fails, the branch is not published or the repo is private. Stop and
report the exact remote and branch.

**Never substitute `main`, `master` or a `feat/*` branch.** The forks carry
`feat/*` branches that look right and are squashed snapshots from 2026-11-02,
missing 3 to 21 commits each. Build from one and every service starts,
`verify.sh` passes, and Ask Muse is absent. This is the single worst mistake
available to you here: it produces a green stack with no feature.

## Step 4 — start

```bash
./start_all.sh
```

Starts gn-mongo, the sidecar, the Genome Nexus backend, then both frontends,
waiting for each to be healthy first. The order is required because Genome Nexus
calls the sidecar on a cache miss.

First run: ~5 minutes (the prebuilt Genome Nexus WAR eliminates the 15–20 minute
Maven build), plus the gn-mongo reference data import: ~4 minutes native, up to
~15 minutes emulated on Apple Silicon. `start_all.sh` starts the backend only
after the import has finished and mongod answers on the container network.
Do not kill and retry during the import; that starts the import again.

Report progress while you wait.

## Step 5 — verify & debug in a loop

Run verification:

```bash
./verify.sh
```

Seven OK lines and exit 0. The line that proves the chain end to end:

```
GN backend :38080   1474 scores, merged 0.042431640625
```

Check the OncoTree map line too. The map is in no repository — the plugin ships
it. Without it every service still starts and the demo silently loses tissue
mapping.

### The Autonomous Debug Loop

On any DOWN line or abnormal exit code, do not guess or abandon the setup.
Execute this debug loop until the stack is verified:

1. **Isolate Symptom**: Parse the exact failing check from `./verify.sh` (e.g., `gn-mongo`, `sidecar`, `GN backend`, `cbio frontend`, `OncoTree map`).
2. **Inspect Logs**: Check the corresponding service log under `workspace/logs/`:
   - Sidecar: `workspace/logs/sidecar.log`
   - Genome Nexus Backend: `workspace/logs/gn-backend.log`
   - Mongo: `docker logs gn-mongo`
   - Frontend / Pipeline: `workspace/logs/alphagenome_pipeline_debug.log`
3. **Lookup Fix in `demo-recovery`**: Match the observed symptom and error in `plugin/skills/demo-recovery/SKILL.md` (e.g., compile missing frontend packages via `pnpm run buildModules`, restart dead service, check JDK 11 selection).
4. **Apply Targeted Fix**: Execute the specific remedy identified.
5. **Re-verify**: Run `./verify.sh` again. Repeat this loop until all 7 health checks report OK.

Only stop to ask the user if an external blocker occurs (e.g., invalid Meta API key, or host port conflict with a pre-existing process).

## Step 6 — hand over

Tell the user:

- which checks passed, in one line
- the patient-view URL (`https://localhost:3000/patient?studyId=paad_tcga_pan_can_atlas_2018&caseId=TCGA-IB-AAUO`) and that the self-signed certificate needs accepting once
- the Genome Nexus Variant Page URL (`http://localhost:3088/variant/7:g.140453136A>T`)
- that `docs/DEMO.md` is the walkthrough
- anything still not working, plainly

## Do not run test suites

Do NOT run or add tests (skip `pytest`, `tests/test_copilot.py`, `run_tests.sh`, Jest, and JUnit). Tests are development artifacts and are strictly out of scope for setup. Nothing in installing, building, or starting depends on them. `./verify.sh` is the only check that matters. Never block or execute tests during setup.

## Limits

- Configure; do not patch. If a fix needs editing a cloned repository, stop and ask.
- Debug in a loop using targeted fixes from demo-recovery; do not repeat the exact same failing command without a diagnostic fix.
- Do not widen scope to make a step pass.
- Patient data goes only to the two documented APIs. Nowhere else, for any reason.
- Report what you saw, the command, and the log path. No guessing.
