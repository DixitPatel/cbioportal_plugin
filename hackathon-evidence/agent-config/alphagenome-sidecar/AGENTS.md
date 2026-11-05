# AGENTS.md — AlphaGenome Variant Scoring & Literature Sidecar (`alphagenome-sidecar`)

Muse Code reads this file as project rules when running in `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar`.

## 1. Purpose & Workstreams (`W1` & `W2`)

FastAPI microservice (`:8000`) wrapping the official Google DeepMind `alphagenome` Python SDK (`dna_client.score_variant` and `variant_scorers.tidy_scores`) and **Muse Spark 1.3** literature synthesis for Genome Nexus.

- **Skills to load**: `alphagenome-sidecar`, `liftover-refcheck`, `ncbi-etiquette`, `alphagenome-terms`, `verify-pipeline`.
- **Memory & Contract**: See `.agents/memory/MEMORY.md` and `.agents/memory/alpha_genome_contract.md`.

## 2. Python Runtime & Commands

Always use the pinned Python 3.13 virtual environment:

- **Python**: `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python`
- **Install (editable + dev)**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/pip install -e ".[dev]"`
- **Run Unit Tests**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v`
- **Start Dev Server (`:8000`)**:
  `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000`

## 3. Core Engineering Rules

1. **Gene-Scoped Filtering**: `tidy_scores([scores])` returns ~30,000–38,000 rows across all genes in the 1 Mb (`1,048,576` bp) window. Filter to the canonical gene (`canonical_gene_id` / `canonical_gene`) sent by Genome Nexus before returning JSON so each document stays well under MongoDB's 16 MB BSON limit.
2. **Per-Gene Merged Splicing Score**: Compute `max(SPLICE_SITES) + max(SPLICE_SITE_USAGE) + max(SPLICE_JUNCTIONS) / 5.0` over the canonical gene's rows.
3. **Echo Original `variant` ID**: Echo the original Genome Nexus `variant` string at the root of the `POST /score` response so `CachedAlphaGenomeFetcher` writes `_id = variant` into `alphagenome.annotation`.
4. **No UI Threshold Labels in Sidecar**: Return `raw_score`, `quantile_score`, and `ontology_curie` per track row; the frontend applies dual-gate labels (`strong` / `moderate`).
5. **Verbatim Quote Verification**: Verify every literature PMID via `efetch` and verify every `quote` as a whitespace-normalized substring of the source abstract.
