# Service Restart Reference (AlphaGenome W1–W5 stack)

**Scope**: local demo stack only. Canonical ports doc stays at
`Meta_hackathon/SERVICE_PORTS_AND_URLS.md` (§2–§6); this file is the
corrected **§7 startup sequence** with verified ports/hosts.

## Port / host map

| Service | URL | Backend it calls | Notes |
| :--- | :--- | :--- | :--- |
| AlphaGenome sidecar | `http://localhost:8000` | DeepMind API (live key) | Start **first**; GN backend calls it on cache miss |
| Genome Nexus backend (W3) | `http://localhost:38080` | Sidecar `:8000`, GCS GRCh38 slices, MongoDB `annotator` | No local FASTA needed; `alpha_genome` live here |
| Genome Nexus frontend (W5) | `http://localhost:3088` | `http://localhost:38080` via `--local-gn` | **AlphaGenome data renders here** (same-scheme HTTP, direct) |
| cBioPortal frontend (W4) | `https://localhost:3000` | public GN (see caveat) | Self-signed cert: Advanced → Proceed |

## Restart sequence (in order)

Run each in its own terminal. Stop old instances first:
`Ctrl-C` in each service terminal, or `lsof -ti :3000,:3088,:38080,:8000 | xargs kill`
(only kills whatever holds these four ports).

```bash
# 1. Sidecar (:8000) — first, so the backend never hits a cold cache with no scorer
workspace/startup_scripts/start_alphagenome_sidecar.sh
curl -s http://localhost:8000/health   # expect {"status":"ok",...}

# 2. Genome Nexus backend (:38080) — reuses web/target/web-*.war; add --rebuild
#    only if Java sources changed since the war was built
workspace/startup_scripts/start_genome_nexus_backend.sh
curl -s "http://localhost:38080/annotation/7:g.140453136A>T?fields=alpha_genome" \
  | python3 -c "import json,sys; a=json.load(sys.stdin)['alpha_genome']['annotation']; print(len(a['scores']), a['merged_splicing_score'])"
# expect: 1474 0.042431640625

# 3. Genome Nexus frontend (:3088) — --local-gn is REQUIRED for alpha_genome
workspace/startup_scripts/start_genome_nexus_frontend.sh --local-gn
# open: http://localhost:3088/variant/7:g.140453136A>T

# 4. cBioPortal frontend (:3000)
workspace/startup_scripts/start_cbioportal_frontend.sh --public-gn
# open: https://localhost:3000/results/mutations?cancer_study_list=msk_impact_2017&case_set_id=msk_impact_2017_all&gene_list=TP53
```

## cBioPortal + localhost GN caveat (read before changing flags)

- `--public-gn` (recommended for now): GN calls go direct to
  `https://www.genomenexus.org`. Standard annotations work; `alpha_genome`
  requests 404 (public host has no W3 code) and `AlphaGenome.tsx` renders blank.
- Default (no flag): `GENOME_NEXUS_URL=http://localhost:38080`. The frontend
  rewrites `http://` GN URLs through the **cBioPortal backend proxy**
  (`/api/proxy/...`), so this only works with a local cBioPortal backend on
  `:8080` — none is running in this stack. Without it, ALL GN annotation in
  cBioPortal breaks (worse than the single-field 404 above).
- `show_alphagenome=true` (current default) fires the `alpha_genome` fetch in
  cBioPortal. With `--public-gn` that fetch 404s (console noise, blank cell);
  the data itself is verified live on `:38080` and renders in the `:3088 app.
```

