---
name: ncbi-etiquette
description: Follow NCBI E-Utilities, LitVar 2.0, and PubTator3 rate limits, parameter rules, and strict PMID and verbatim quote verification.
---

# NCBI E-Utilities & Literature Verification Rules

Use this skill whenever querying NCBI E-Utilities (`esearch`, `esummary`, `efetch`), LitVar 2.0, or PubTator3, or when screening retrieved abstracts with `muse-spark-1.3`.

## API Etiquette & Rate Limits

1. **Required Query Parameters**:
   - Include `tool=cbioportal_alphagenome_muse` and `email` on every NCBI E-Utilities request.
   - Include `api_key` when `NCBI_API_KEY` is set in the environment.
2. **Rate Limiting**:
   - Without `NCBI_API_KEY`: maximum 3 requests/second.
   - With `NCBI_API_KEY`: maximum 10 requests/second.
   - Retry `HTTP 429` or `5xx` responses with exponential backoff.

## Anti-Hallucination & Quote Verification

1. **PMID Verification**:
   - Never accept a PMID that was not returned by the upstream LitVar 2.0 / PubMed retrieval step and verified via `efetch` / `esummary`.
2. **Verbatim Quote Verification**:
   - Every `quote` (`<= 300` characters) returned by `muse-spark-1.3` must be checked as a case-insensitive, whitespace-normalized substring of the retrieved abstract or open-access full text.
   - If a quote fails substring verification, set `quote_verified: false` and drop the unverified quote before assembling the final payload.
3. **Closed-Vocabulary Labels**:
   - `evidence_level` in `{"same_variant", "same_mechanism_same_gene", "gene_only", "unrelated"}`
   - `evidence_type` in `{"experimental", "computational", "clinical_observation", "review"}`
   - `relation_to_prediction` in `{"supports", "conflicts", "not_addressed"}`
