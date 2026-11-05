---
name: demo-recovery
description: Diagnose and fix a failing cBioPortal Ask Muse stack. Use when verify.sh reports DOWN, a service will not start, Ask Muse always answers from the offline fallback, the AlphaGenome cell stays blank, or the Colab notebook fails.
---

# Demo recovery

Work from evidence. Run `./verify.sh` first and read the named log under
`workspace/logs/`. Do not guess, and do not restart everything blindly.

## Rule

Report the cause and the one command that fixes it. If a check needs a key or
a decision the user must make, stop and ask. Never print `META_API_KEY` or
`ALPHA_GENOME_API_KEY` into the transcript or a log.

## Symptom table

| Symptom | Cause | Fix |
|---|---|---|
| `gn-mongo :27017` DOWN, `docker logs gn-mongo` still shows the import | First start imports reference data inside Bitnami `/setup.sh` (~4 min native, up to ~15 min emulated) | Wait. Do not kill and retry; that restarts the import. |
| `gn-mongo` DOWN, or backend log shows `Connection reset` / `MongoTimeoutException` | Container created without `--bind_ip_all`: under Rosetta the config render crashes and mongod listens on loopback only | `./start_all.sh` recreates it. By hand: `docker rm -f gn-mongo && docker run --platform linux/amd64 --name=gn-mongo --restart=always -p 27017:27017 -e MONGODB_EXTRA_FLAGS="--dbpath /bitnami/mongodb/data/db --bind_ip_all" -d genomenexus/gn-mongo:latest` |
| `gn-mongo` crash-looping (exit 100), log shows `Data directory /data/db not found` | Rosetta template render crash leaves a 0-byte config | Same recreate command; `--dbpath` fixes it |
| `GN backend :38080` DOWN, log shows `cannot resolve model:jar` / parent POM absent | Multi-module build requires root POM installed in `~/.m2` first | `cd workspace/genome-nexus && mvn install -N -DskipTests -B && mvn clean install -DskipTests -B` |
| `sidecar :8000` DOWN, log shows `ModuleNotFoundError` | venv missing the editable installs | `./bootstrap.sh` |
| `sidecar` up, scoring raises on every variant | `ALPHA_GENOME_API_KEY` absent or rejected | Check `agentic-setup/.env`. The sidecar reads it at start, so restart after editing. |
| `GN backend :38080` DOWN, log shows `UnsupportedClassVersionError` | Built or run with the wrong JDK | Needs JDK 11. `java_home_for 11` in `lib/env.sh` resolves it; set `JAVA11_HOME` to override. |
| `GN backend` up, **`no alpha_genome`** | Backend cannot reach the sidecar | Confirm `curl localhost:8000/health`. Start order matters: sidecar before backend. |
| `cbio frontend :3000` DOWN, log shows a missing `dist/index.js` | Workspace packages not built | `cd workspace/cbioportal-frontend && pnpm run buildModules` |
| Browser warns about the certificate | Dev server is https with a self-signed cert | Advanced → Proceed to localhost. Expected. |
| AlphaGenome column blank in cBioPortal, console 404s on `alpha_genome` | `GENOME_NEXUS_URL` points at the public host, which has no AlphaGenome field | It must be `http://localhost:38080`. `services/start_cbio_frontend.sh` sets this; do not override it with a public URL. |
| Ask Muse replies, but every reply says offline demo / `source: "fallback"` | The model call failed, or `META_API_KEY` never reached the sidecar | `./check_muse.sh`. A 401 means a bad key; 404 means the wrong path — only `{base}/chat/completions` exists, never `{base}/chat`. If the key is fine, the env file was probably loaded with bash `source`, which splits `LLM\|id\|secret` on the pipes and leaves it unset. Start services through `start_all.sh`, which parses the file literally. |
| `command not found` lines naming digits or a secret, on startup | Same cause: something ran `source agentic-setup/.env` | Use the plugin scripts. Re-store the key with `./set_meta_key.sh`, which writes it quoted. |
| Ask Muse hangs, then HTTP 504 `gateway_timeout` | A long non-streaming call at `reasoning_effort: high` | Use the streaming route `/copilot/chat/stream`. Expect ~9 s to the first delta. |
| Reply truncated mid-sentence | Reasoning tokens count against the output cap | Raise `max_completion_tokens`. Check `usage.completion_tokens_details.reasoning_tokens`. |
| HTTP 400 from the model | An unsupported field was sent | `stop`, `n>1`, `logprobs`, `logit_bias`, `max_output_tokens` and `tool_choice` other than `auto` all return 400. Use `max_completion_tokens`. |
| Colab card empty, "Score variants first" | No scored variant in Mongo for that patient | Click **AlphaGenome Score Variants** in the Mutations tab first. |
| `/copilot/colab-params` returns 422 | No OncoTree→UBERON mapping for the cancer type | Use **Map OncoTree** first. An empty ontology list would request every tissue. |
| `/copilot/colab-params` returns 404 | No Mongo record for that variant | Score it first. |
| `/copilot/colab-params` returns 502 / Colab fails | `COLAB_NOTEBOOK_REF` branch unreachable, rate-limited, or token missing | Set `COLAB_NOTEBOOK_REF=w6-muse-copilot` in `agentic-setup/.env`. The sidecar falls back to raw GitHub and `main`. |
| Colab notebook cell fails on import | Notebook pins a different `alphagenome` than the sidecar | Both must be `0.10.0`. |

## Port already in use

```bash
lsof -i :3000 -i :3088 -i :8000 -i :38080 -i :27017
./start_all.sh --stop          # stops only what this plugin started
```

## Clean restart

```bash
./start_all.sh --stop
docker restart gn-mongo
./start_all.sh
```

A full restart costs about 3 minutes once the war is built. Do not rebuild the
war unless the Java sources changed.

## When the stack is green but the demo is wrong

Check the numbers, not the service. The score in the Colab parameter cell must
equal the Mutations table tooltip for the same variant — both read
`score_level` and `merged_splicing_score` from the same Mongo record. If they
differ, the record was rescored between the two reads; reload the patient view.
