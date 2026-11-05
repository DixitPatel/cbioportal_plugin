---
name: alphagenome-sidecar
description: Implement and test the FastAPI AlphaGenome scoring and Muse Spark literature curation sidecar service in alphagenome-sidecar.
---

# AlphaGenome Sidecar (`W2`)

Use this skill when working on `alphagenome-sidecar` (`POST /score` and `GET /health`), wrapping `dna_client.score_variant()`, running `tidy_scores` locally, filtering to the canonical gene, and curating variant literature with `muse-spark-1.3`.

## Endpoint Contract (`POST /score`)

### Request Payload
Accept one normalized GRCh38 variant and canonical gene per request:
- `variant`: original Genome Nexus variant string (e.g., `"7:g.140453136A>T"` or `"5:g.176940011C>T"`), echoed at the root of the response so `CachedAlphaGenomeFetcher` can key MongoDB `_id = variant`.
- `chromosome`: `^chr([1-9]|1[0-9]|2[0-2]|X|Y)$` (e.g., `"chr7"`).
- `position`: 1-based GRCh38 integer position (`>= 1`).
- `reference_allele`: `^[ACGT]+$`.
- `alternate_allele`: `^[ACGT]+$`.
- `canonical_gene_id`: Ensembl gene ID (e.g., `"ENSG00000157764"`, version stripped).
- `canonical_gene`: Hugo gene symbol (e.g., `"BRAF"`).
- `include_literature`: optional boolean (default `false` or enabled per query) to run LitVar 2.0 + PubMed retrieval and `muse-spark-1.3` curation.

### Scoring & Gene Filtering Rules
1. Build `genome.Variant(chromosome, position, reference_allele, alternate_allele)` and resize interval to `SEQUENCE_LENGTH_1MB` (`1,048,576` bp), shifting or rejecting intervals that would start `< 0`.
2. Call `dna_client.score_variant()` with the four recommended scorers from `RECOMMENDED_VARIANT_SCORERS`:
   - `RNA_SEQ`
   - `SPLICE_SITES`
   - `SPLICE_SITE_USAGE`
   - `SPLICE_JUNCTIONS`
3. Run `tidy_scores([scores])` locally. Because all genes in the 1 Mb window produce ~30,000–38,000 rows, filter rows to the canonical gene (`gene_id == canonical_gene_id` or `gene_name == canonical_gene`) so each MongoDB document stays compact (`~5–50 KB`, well below the 16 MB BSON limit).
4. Compute the per-gene merged splicing score:
   `merged_splicing_score = max(SPLICE_SITES) + max(SPLICE_SITE_USAGE) + max(SPLICE_JUNCTIONS) / 5.0`
5. Return per-gene `scorer x track` rows (`scorer x junction x track` for `SPLICE_JUNCTIONS`) with `raw_score`, `quantile_score`, and `ontology_curie` (where present; `SPLICE_SITES` is tissue-agnostic). Do not bake UI threshold labels into the sidecar score rows.

## Verification Commands

```bash
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar
/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/python -m pytest -v
```
