---
name: compliance_and_safety
description: Mandatory rules for Muse Standard mode, AlphaGenome non-clinical notices, and NCBI quote verification.
type: feedback
---

# Compliance & Safety Requirements

1. **Always Run Muse in Standard Mode (`--contributor-mode off`)**:
   AlphaGenome terms forbid training models on AlphaGenome outputs. Never run Muse Code in Contributor mode when AlphaGenome data or NCBI text is in context.
2. **Always Display Research-Only Notice**:
   Every UI view showing AlphaGenome scores must display `"Model prediction, not experimental evidence."`
3. **Never Fabricate Citations or Quotes**:
   Every PMID must come from LitVar 2.0 / PubMed retrieval and be verified via `efetch`, and every quote must be verified as a whitespace-normalized substring of the source abstract.
