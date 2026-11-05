---
name: alphagenome-terms
description: Enforce AlphaGenome non-clinical research notices, no-model-training restrictions, and Meta Muse Standard mode compliance.
---

# AlphaGenome Terms & Meta Muse Standard Mode Compliance

Use this skill whenever handling AlphaGenome API outputs, configuring Muse Code sessions, or rendering AlphaGenome predictions in Genome Nexus and cBioPortal.

## Mandatory Compliance Rules

1. **No Model Training on AlphaGenome Outputs (`--contributor-mode off`)**:
   - AlphaGenome's terms prohibit using its outputs to train machine learning models.
   - Every Muse Code CLI session (`muse` or `muse exec`) and Meta API call must run in **Standard mode** (`--contributor-mode off`), never Contributor mode.
2. **Non-Commercial & Non-Clinical Research Use Only**:
   - AlphaGenome predictions are for non-commercial research use only and must never be used for clinical decision-making or patient diagnosis.
3. **Required UI Disclaimer**:
   - Every UI component displaying AlphaGenome predictions (`cbioportal-frontend` hover tooltip and `genome-nexus-frontend` Variant Page) must display the notice:
     `"Model prediction, not experimental evidence."`
4. **API Key Isolation**:
   - Keep `ALPHA_GENOME_API_KEY` solely in the backend `alphagenome-sidecar` environment; never expose it in frontend bundles, client responses, or session logs.
