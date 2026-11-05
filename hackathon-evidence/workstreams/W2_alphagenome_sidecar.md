# Workstream W2: AlphaGenome Variant Scoring Sidecar (`alphagenome-sidecar`)

- **Workstream ID**: `W2`
- **Skill**: `alphagenome-sidecar`
- **Target Repository**: `alphagenome-sidecar` (`workspace/alphagenome-sidecar`)
- **Language / Stack**: Python / FastAPI / `alphagenome` SDK

---

## 1. Workstream Summary (As-Is from Proposal)

- **`W2` — `alphagenome-sidecar` (`alphagenome-sidecar` · Python)**:
  Wrap `score_variant` in a FastAPI `POST /score` with the recommended `RNA_SEQ` and splicing scorers, run `tidy_scores` locally, keep only the rows for the gene that Genome Nexus sends, and add the merged splicing score.

---

## 2. Architecture and Implementation Details (As-Is from Proposal §2.3)

### 2.3 AlphaGenome Variant Scoring and Sidecar Summarization (`score_variant`)

- **FastAPI sidecar**:
  Because the official AlphaGenome SDK is Python-only, a FastAPI service (`POST /score`) wraps `dna_client.score_variant()` with a 1 Mb (`1,048,576` bp) interval and four of the `RECOMMENDED_VARIANT_SCORERS`: `RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`.
- **Why sidecar filtering is required**:
  In AlphaGenome benchmark runs, `tidy_scores` returns about 30,000–38,000 rows per variant: one row per `gene × scorer × track`, for every gene in the 1 Mb window. The sidecar keeps only the given gene's rows before it returns to Genome Nexus. This keeps each document well below the MongoDB 16 MB BSON limit and keeps UI payloads small:
  - **Per-variant summary**: the GRCh38 `chr:pos:REF>ALT`, interval, model version, and the merged splicing score for the given gene:
    $$\text{max(SPLICE\_SITES)} + \text{max(SPLICE\_SITE\_USAGE)} + \frac{\text{max(SPLICE\_JUNCTIONS)}}{5}$$
  - **Per-gene rows**: For the canonical-transcript gene that Genome Nexus sends, the sidecar returns each `scorer × track` row (`raw_score`, `quantile_score`, and `ontology_curie` where the track has one). `SPLICE_SITES` has no tissue tracks. The sidecar adds no labels.

---

## 3. Sequence Flow & Deliverables (As-Is from Proposal §2.1, §3, §4.2)

- **Sequence Steps**:
  - `GN->>SC`: `5. POST /score (GRCh38 chrom, pos, ref, alt + canonical gene_id, symbol), 1 variant per call`
  - `SC->>AG`: `6. score_variant (RNA_SEQ, SPLICE_SITES, SPLICE_SITE_USAGE, SPLICE_JUNCTIONS)`
  - `AG-->>SC`: `7. Scores (AnnData), then SC runs tidy_scores locally`
  - `SC-->>GN`: `8. Rows for the given gene (scorer x track) + merged splicing score`
- **Deliverable**:
  - The AlphaGenome scoring sidecar (`alphagenome-sidecar`), with its OpenAPI contract and a Docker Compose entry.
- **Engineering Note**:
  - **New sidecar service**: The sidecar (§2.3) adds one more service to deploy and monitor.

---

## 4. Additional Instructions for Muse

### Skill & Contracts to Load
- **Skills**: `.agents/skills/alphagenome-sidecar/SKILL.md` (`alphagenome-sidecar`), `.agents/skills/ncbi-etiquette/SKILL.md` (`ncbi-etiquette`), and `.agents/skills/alphagenome-terms/SKILL.md` (`alphagenome-terms`)
- **Contracts**: `workstreams/contracts/sidecar_openapi.yaml` and `workstreams/contracts/alpha_genome_schema.json`

### Target Files in `workspace/alphagenome-sidecar`
- `app/main.py`: FastAPI `POST /score` and `GET /health` endpoints.
- `app/` scoring & literature modules:
  - Build `genome.Variant` and resize interval to `SEQUENCE_LENGTH_1MB` (`1,048,576` bp), shifting or rejecting intervals starting `< 0`.
  - Call `dna_client.score_variant()` with `RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, and `SPLICE_JUNCTIONS` from `RECOMMENDED_VARIANT_SCORERS`.
  - Run `tidy_scores([scores], match_gene_strand=True)` locally, filter rows to the canonical gene (`canonical_gene_id` / `canonical_gene`) sent by Genome Nexus, compute `merged_splicing_score = max(SPLICE_SITES) + max(SPLICE_SITE_USAGE) + max(SPLICE_JUNCTIONS) / 5.0`, and echo the original Genome Nexus `variant` string at the root of the JSON response.
  - When literature synthesis is enabled, query LitVar 2.0 + PubMed E-Utilities, screen abstracts with `muse-spark-1.3` (Standard mode), and verify every PMID (`efetch`) and verbatim `quote` substring.
- `tests/`: Unit tests for `POST /score`, gene filtering, merged splicing score, HTTP 422 validation, and quote verification.

### Build & Acceptance Test Commands (Python 3.13 `.venv`)
```bash
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar
/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v
```
