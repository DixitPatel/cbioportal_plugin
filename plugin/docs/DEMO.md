# Demo walkthrough

Run `./verify.sh` first. Every line must read OK.

Demo case: **TCGA-IB-AAUO**, pancreatic adenocarcinoma, study
`paad_tcga_pan_can_atlas_2018`. KRAS G12D at `chr12:25245350:C>T` is the
variant used throughout. It sits on the minus strand, which is why strand
filtering matters in the notebook.

Open:

```
https://localhost:3000/patient?studyId=paad_tcga_pan_can_atlas_2018&caseId=TCGA-IB-AAUO
```

The certificate is self-signed. Click **Advanced → Proceed to localhost** once.

## 1. Score the variants (AlphaGenome)

Go to the **Mutations** tab. Click **⚡ AlphaGenome Score Variants**.

Variants are scored in background chunks. Each row's Annotation column gains a
score badge: `strong`, `moderate` or `none`. Hover a badge for the per-track
tooltip. The numbers come from the sidecar on `:8000` through Genome Nexus on
`:38080`, cached in Mongo.

Scores are a prediction of molecular effect, not a clinical call.

## 2. Open Ask Muse

Click **🧬 Ask Muse** in the Mutations tab. A floating window opens and stays
open as you move between tabs.

Muse Wonder (`muse-wonder-1.0`, `reasoning_effort: high`) answers from this
patient's own context: the scored variants, the clinical attributes and the
OncoTree mapping. Expect about 9 seconds to the first token — reasoning runs
before any text streams.

## 3. Inside Ask Muse:

**Free text.** Type a question, for example *"which of this patient's variants
is most likely to affect splicing, and why?"* The answer cites the scores on
screen.

**Query PubMed.** Builds a three-part Boolean query from the patient's context
genes and cancer type, retrieves papers, then ranks them by citation count
through iCite and groups them into sections. The raw Boolean string is
deliberately not shown — the papers are the answer.

**Map OncoTree.** Resolves the sample's OncoTree code to a UBERON tissue term.
Pancreatic adenocarcinoma maps to `UBERON:0001264`. This mapping drives which
AlphaGenome tissue tracks are requested, so it has to be right.

**Context pills.** TMB–grade paradox, PFS–stage gap and the rest are built from
this patient's own values

**Show failures.** Lists variants that failed scoring, with the reason.

## 4. 🚀 Colab Cookbook

Click the pill. The card lists the scored variants, sorted by score level then
by merged splicing score — labels read `KRAS G12D · moderate · splice 0.109`.

Pick KRAS G12D. The card renders a ready-made parameter cell. Confirm the
numbers match the Mutations table tooltip for the same variant: both read the
same Mongo record.

Click **Copy cell 3**, then **Open in Colab**. In the notebook:

1. Set the notebook secrets `ALPHA_GENOME_API_KEY` and `META_API_KEY`.
2. Run cells 1–2 (installs `alphagenome==0.10.0`, loads the GENCODE annotation).
3. Paste into cell 3. Run 3–6.

Cell 6 draws REF versus ALT: a transcript row, RNA-seq, splice-site and
splice-site-usage overlays, and REF/ALT Sashimi plots for pancreas.

Cell 7, **Explain with Muse**, sends the computed numbers — not the picture —
to Muse Wonder: top changed tracks, junction changes, exon context and the
sidecar scores. It answers mechanism first, then the numbers it used, and is
told to say so when the data does not support a claim.

## 5. Variant page (Genome Nexus)

```
http://localhost:3088/variant/7:g.140453136A>T
```

The same AlphaGenome annotation rendered on the Genome Nexus variant page.

## If something is wrong mid-demo

`./verify.sh` names the failing service. For anything it cannot
place, hand its output and the named log in `workspace/logs/` to Muse Code and
ask it to use the `demo-recovery` skill.

## Notes
- Study data is read from actual public cBioPortal
- Research use only
