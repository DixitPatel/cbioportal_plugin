# Handoff Plan 1: Core AlphaGenome Sidecar Parameterization

**Status**: Ready for Muse Implementation  
**Target Repository**: `workspace/alphagenome-sidecar` (Branch: `w2-sidecar`)  
**Assigned Agent**: Muse Code (Implementer / Tester)

---

## 1. Architectural Scope & Parameterization Boundary

Parameterization defines what is accepted as **API input** and where in the pipeline it takes effect:

```
                  ┌────────────────────────────────────────────────────────┐
                  │ POST /score (ScoreRequest)                             │
                  └──────┬───────────────────────┬───────────────────┬─────┘
                         │                       │                   │
                 sequence_length              scorers         ontology_curies
                         │                       │                   │
                         ▼                       ▼                   │
    ┌─────────────────────────────────────────────────────────┐      │
    │ Direct Input to AlphaGenome Model                       │      │
    │ • interval = variant.reference_interval.resize(length)  │      │
    │ • client.score_variant(interval, variant, scorers)      │      │
    └────────────────────────────┬────────────────────────────┘      │
                                 │                                   │
                                 ▼ (Raw AnnData -> tidy_scores)      │
    ┌─────────────────────────────────────────────────────────┐      │
    │ Post-Model Output Filtering                             │      │
    │ • Filter by canonical gene                              │      │
    │ • Filter tracks by ontology_curie <─────────────────────────────┘
    └─────────────────────────────────────────────────────────┘
```

1. **Direct Input to AlphaGenome (`sequence_length`)**:
   - Replaces hardcoded 1 Mb with a sidecar-side allowlist (verified 2026-10-29: the
     vendored SDK 0.10.0 exposes **no** `SUPPORTED_SEQUENCE_LENGTHS` constant and no
     length literals — valid lengths are enforced server-side, so the allowlist lives here):
     - `16KB` = $16{,}384$ bp ($2^{14}$)
     - `100KB` = $131{,}072$ bp ($2^{17}$)
     - `500KB` = $524{,}288$ bp ($2^{19}$)
     - `1MB` = $1{,}048{,}576$ bp ($2^{20}$) — **Default**
   - Anything outside the allowlist is rejected with 422 by Pydantic validation.
   - Interval construction idiom from AlphaGenome notebooks (`splicing_variant_scoring.ipynb`):
     ```python
     interval = variant.reference_interval.resize(sequence_length)
     ```
2. **Direct Input to AlphaGenome (`scorers`)**:
   - The current 4 chosen scorers (`RNA_SEQ`, `SPLICE_SITES`, `SPLICE_SITE_USAGE`, `SPLICE_JUNCTIONS`) **remain the active default**.
   - Input names must come from the ~11+ supported `RECOMMENDED_VARIANT_SCORERS` keys (superset containing the 4 defaults); anything else is rejected with 422.
3. **Post-Model Output Filtering (`ontology_curies`)**:
   - Filters the expanded tabular `tidy_scores` DataFrame after model execution.
   - Default (`None`): Retains all tissue tracks.
   - > [!IMPORTANT]
     > **Open Architecture Flag**: The existing `oncotree_to_uberon.json` in the frontend is a testing mock. Dynamic translation of arbitrary clinical biosamples to ontology CURIEs belongs to the Genome Nexus backend or an ontology resolver service. For this sidecar API, assume a valid `ontology_curie` (or list) is provided as input.

---

## 2. API Schema Reference (`app/schemas.py`)

> [!NOTE]
> **Implementation Suggestion Only**: Muse implementer should implement using existing codebase conventions and Pydantic validation.

```python
from pydantic import BaseModel, Field

# Sidecar-side allowlist (no SDK constant exists in 0.10.0; enforced here, 422 otherwise)
ALLOWED_SEQUENCE_LENGTHS = (16384, 131072, 524288, 1048576)

class ScoreRequest(BaseModel):
    variant: str
    chromosome: str
    position: int
    reference_allele: str
    alternate_allele: str
    canonical_gene_id: str | None = None
    canonical_gene: str

    # Optional parameterizations:
    sequence_length: int = Field(
        default=1048576,
        description="Supported AlphaGenome sequence length: 16384 (16KB), 131072 (100KB), 524288 (500KB), 1048576 (1MB)",
    )
    scorers: list[str] | None = Field(
        default=None,
        description="List of scorers to run. None preserves default recommended 4 scorers.",
    )
    ontology_curies: list[str] | None = Field(
        default=None,
        description="Post-output filter for specific UBERON/CL ontology curies. None preserves all tissues.",
    )
```

---

## 3. Pipeline Reference Patterns (`app/scoring.py`)

> [!NOTE]
> **Implementation Suggestion Only**: Muse implementer should follow SDK reference patterns (`variant.reference_interval.resize`).

1. **Interval Construction**:
   ```python
   # Uses AlphaGenome's built-in resize method on variant.reference_interval.
   # NOTE: Interval.resize() centers without clamping, so the existing
   # start<0 right-shift guard from build_interval() must be preserved here:
   # a telomeric variant with a wide window would otherwise send a negative
   # start to the API. Future iteration: replace the manual shift with a
   # chromosome-bounds-aware clamp once contig lengths are available in the
   # sidecar (currently only the backend resolver knows them).
   interval = variant.reference_interval.resize(request.sequence_length)
   if interval.start < 0:
       interval = genome.Interval(
           interval.chromosome, 0, request.sequence_length
       )
   ```
2. **Scorer Factory**:
   - Default remains the 4 chosen scorers (`build_scorers()` without args).
   - If `request.scorers` is supplied, resolve each name against
     `variant_scorers_module.RECOMMENDED_VARIANT_SCORERS` keys (the ~11+ supported
     scorer names, which include the 4 defaults). Unknown names are rejected
     with 422 — genuinely custom (non-recommended) scorers cannot be built
     from a string and are out of scope for this plan.
3. **Post-Output Curie Filter**:
   - In `_filter_to_canonical_gene`, if `ontology_curies` is present:
     Keep tracks where `ontology_curie.isin(ontology_curies)` OR `output_type == "SPLICE_SITES"` (tissue-agnostic).

---

## 4. Verification & Testing Strategy

Muse must verify changes using the repository's native pytest suite:
- File: `tests/test_score.py`
- Test Cases to Add / Verify:
  1. `test_score_default_backward_compatible`: Omitting new fields runs 1 Mb (`1,048,576` bp), all 4 recommended scorers, and returns all tissues.
  2. `test_score_sequence_length`: Passing `sequence_length=16384` builds a 16 KB interval via `resize()`.
  3. `test_score_ontology_curie_filter`: Filters output tracks to specified curie plus tissue-independent splice sites.
  4. `test_score_custom_scorers`: Evaluates only requested scorers when specified.
- Execution Command:
  ```bash
  cd "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome-sidecar"
  "/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/agentic-setup/.venv/bin/pytest" -v
  ```
