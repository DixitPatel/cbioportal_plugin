# Workstream W1: Liftover and REF Check (`liftover-refcheck`)

- **Workstream ID**: `W1` (broken down into iterative, approval-gated sub-steps `W1.1` – `W1.6`)
- **Skill**: `liftover-refcheck` (`.agents/skills/liftover-refcheck/SKILL.md` / `.muse/skills/liftover-refcheck.md`)
- **Target Repository**: `genome-nexus` (`workspace/genome-nexus`)
- **Live Backend Server**: Running at `http://localhost:38080` (backed by `gn-mongo` on `127.0.0.1:27017`)
- **Language / Stack**: Java 8+ (compiled with OpenJDK 11) / Spring Boot / `htsjdk`

---

## 1. End Goal & Why W1 Needs Iterative Clarity

AlphaGenome (`W2`) only accepts **GRCh38** coordinates with a `chr` prefix (`chr1`..`chr22`, `chrX`, `chrY`) and **VCF-style alleles** (`pos`, `REF`, `ALT` where indels include a 1-bp anchor base and are left-aligned), and **does not reject variants whose `REF` allele mismatches GRCh38**.

By contrast, Genome Nexus (`workspace/genome-nexus`) defaults to **GRCh37**, stores variants on `VariantAnnotation` as:
- `assemblyName` (`"GRCh37"` or `"GRCh38"`)
- `seqRegionName` (`"1"`..`"22"`, `"X"`, `"Y"`, `"MT"`, without `"chr"` prefix)
- `start` (`Integer`, 1-based inclusive)
- `end` (`Integer`, 1-based inclusive)
- `alleleString` (`String`, slash-delimited `REF/ALT` where empty indel alleles are written as `"-"`, e.g., `"AA/-"` for deletions or `"-/T"` for insertions)
- `strand` (`Integer`, `1` or `-1`)
- `successfullyAnnotated` (`Boolean`)
- `errorMessage` (`String`)
- `transcriptConsequences` (`List<TranscriptConsequence>`)

### Live Genome Nexus Server Verification (`http://localhost:38080`)
Querying the live local Genome Nexus server reveals the exact payloads `W1` must normalize:
1. **`BRAF` V600E (`7:g.140453136A>T`)**:
   - `GET http://localhost:38080/annotation/7:g.140453136A%3ET`
   - `assembly_name: "GRCh37"`, `seq_region_name: "7"`, `start: 140453136`, `end: 140453136`, `allele_string: "A/T"`, `successfully_annotated: true`
   - **Expected W1 Output**: Lifts from `7:140453136` (`GRCh37`) $\rightarrow$ `chr7:140753336:A>T` (`GRCh38`), `geneId = "ENSG00000157764"`, `geneSymbol = "BRAF"`.
2. **`DDX41` R525H (`5:g.176940011C>T`)**:
   - `GET http://localhost:38080/annotation/5:g.176940011C%3ET`
   - `assembly_name: "GRCh37"`, `seq_region_name: "5"`, `start: 176940011`, `end: 176940011`, `allele_string: "C/T"`, `successfully_annotated: true`
   - **Expected W1 Output**: Lifts from `5:176940011` (`GRCh37`) $\rightarrow$ `chr5:177513010:C>T` (`GRCh38`), `geneId = "ENSG00000183258"`, `geneSymbol = "DDX41"`.
3. **`SMAD4` `c.1520_1521del` (`18:g.48604697_48604698del` / `18:g.48604696_48604697del`)**:
   - `GET http://localhost:38080/annotation/18:g.48604697_48604698del`
   - Returns canonical transcript `ENST00000342988.3:c.1520_1521del` (`SMAD4`, `ENSG00000141646`), `assembly_name: "GRCh37"`, `seq_region_name: "18"`, `start: 48604697`, `end: 48604698`, `allele_string: "AA/-"`.
   - Note that `18:48604696` in `GRCh37` (and `chr18:51078327` in `GRCh38`) has reference base `G` immediately preceding `AA` (`18:g.48604696_48604697del` has `allele_string: "GA/-"`).
   - Because VEP 3'-shifts `hgvsg` across the `AA` homopolymer run, `W1` **must not** parse `VariantAnnotation.getHgvsg()`. Instead, `W1` must use `seqRegionName`, `start`, `end`, and `alleleString`, lift to `GRCh38`, fetch the 1-bp anchor base at `pos = start - 1` (`G`), and left-align so the VCF representation is `GAA>G` (`ref = "GAA"`, `alt = "G"`).

---

## 2. Existing `genome-nexus` & `alphagenome` Codebase Context for Muse

Before writing any code, Muse must inspect both `workspace/genome-nexus` and the existing AlphaGenome SDK repository at `workspace/alphagenome`:
1. **Existing AlphaGenome SDK (`workspace/alphagenome/src/alphagenome/data/genome.py`, `io/fasta.py`, & `colabs/v1/haplotype_workaround.ipynb`)**:
   - **Already exists in workspace** at `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/alphagenome` (remote origin: `https://github.com/google-deepmind/alphagenome.git`).
   - **Remote GRCh38 Reference FASTA & FAI Index (`colabs/v1/haplotype_workaround.ipynb` lines 162–166 & `io/fasta.py`)**:
     - FASTA URL: `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/GRCh38.p13.genome.fa`
     - FAI Index URL: `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/GRCh38.p13.genome.fa.fai`
     - GENCODE v46 GTF Feather: `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/gencode.v46.annotation.gtf.gz.feather`
     - UCSC Liftover Chain URL: `https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz`
     - Because `GRCh38.p13.genome.fa.fai` is a tiny text index (`chrName`, `length`, `byteOffset`, `basesPerLine=60`, `bytesPerLine=61`) and Google Cloud Storage supports `Range: bytes=<start>-<end>` HTTP requests, `genome-nexus` can either query a local indexed FASTA or fetch exact slices from `https://storage.googleapis.com/alphagenome/reference/gencode/hg38/GRCh38.p13.genome.fa` using the `.fai` index offsets without downloading the full 3 GB FASTA!
   - `genome.Variant` (`lines 645–815`) defines `VariantFormat.DEFAULT` (`chr:pos:REF>ALT`, regex `_DEFAULT_REGEX`), 1-based `position`, `start = position - 1`, `end = start + len(reference_bases)`, and `VALID_VARIANT_BASES`.
   - `genome.normalize_variant(variant, extractor)` (`lines 965–1024` of `genome.py`, tested in `genome_test.py` `lines 816–845`) already implements the exact **Tan et al. (2015)** (`https://doi.org/10.1093/bioinformatics/btv112`) left-alignment and anchor-base algorithm:
     1. Trim common suffix across `[genome_sequence, ref, alt]`.
     2. While any allele is empty (e.g., MAF deletion `alt = ""` or insertion `ref = ""`), decrement `position -= 1`, fetch 1 base at `0-based [position - 1, position)` from the reference extractor, and prepend it to all alleles (`alleles = [base + a for a in alleles]`), repeating the suffix trim loop until `suffix_length == 0`.
     3. Trim common prefix (`i = min(len(min(alleles)) - 1, _prefix_length(*alleles))`) so at least 1 bp of context remains, returning `Variant(chromosome, position + i, ref[i:], alt[i:])`.
   - `AlphaGenomeVariantNormalizer` in `genome-nexus` (`W1`) should port this exact `normalize_variant` algorithm in Java (converting MAF `"-"` to `""` before running the loop, plus verifying that `reference_bases` matches `genome_sequence` in GRCh38)!
2. **`model/src/main/java/org/cbioportal/genome_nexus/model/VariantAnnotation.java`**:
   - Holds `assemblyName`, `seqRegionName`, `start`, `end`, `alleleString`, `strand`, `successfullyAnnotated`, `errorMessage`, `transcriptConsequences`.
3. **`component/src/main/java/org/cbioportal/genome_nexus/component/annotation/NotationConverter.java`**:
   - Shows how Genome Nexus normalizes chromosome names (`chromosomeNormalizer`: strips `chr`, maps `23 -> X`, `24 -> Y`, `M -> MT`) and converts VCF-to-MAF. `W1` implements the **inverse** for AlphaGenome: MAF (`-`) $\rightarrow$ left-aligned VCF anchor-base form with `chr` prefix (`chr1`..`chr22`, `chrX`, `chrY`).
4. **`component/src/main/java/org/cbioportal/genome_nexus/component/annotation/CanonicalTranscriptResolver.java`**:
   - Existing `@Component` with `public TranscriptConsequence resolve(VariantAnnotation variantAnnotation)`. Use this directly to extract the canonical transcript's `geneId` (`ENSG...`, stripping any `.version` suffix if present) and `geneSymbol` (`BRAF`, `DDX41`, `SMAD4`).
5. **`service/src/main/java/org/cbioportal/genome_nexus/service/internal/VerifiedVariantAnnotationService.java`** and **`NucleotideContextServiceImpl.java`**:
   - Existing precedents for checking reference alleles and querying sequence regions.
6. **`component/pom.xml` and `service/pom.xml`**:
   - Neither currently declares `com.github.samtools:htsjdk`. Adding `htsjdk` is required for `htsjdk.samtools.liftover.LiftOver`, `htsjdk.samtools.util.Interval`, and `htsjdk.samtools.reference.ReferenceSequenceFile` / `IndexedFastaSequenceFile`.

---

## 3. Guided, Approval-Required Step-by-Step Execution Plan for Muse (`W1.1` – `W1.6`)

Muse **must not** implement all of `W1` in a single unreviewed dump. Muse must execute `W1` one sub-step at a time, stopping for **User Approval** after each sub-step.

### Step `W1.1`: Discovery & Design Alignment (Read-Only + Interactive Q&A)
- **Agent**: `Planner` | **Skill**: `codebase-analysis`, `liftover-refcheck`
- **Action**:
  1. Read `VariantAnnotation.java`, `NotationConverter.java`, `CanonicalTranscriptResolver.java`, `component/pom.xml`, and `service/pom.xml`.
  2. Propose the exact class design for `NormalizedAlphaGenomeVariant` (value object holding `variantStr` e.g. `chr5:177513010:C>T`, `chrom`, `pos`, `ref`, `alt`, `geneId`, `geneSymbol`) and `AlphaGenomeVariantNormalizer` (Spring `@Component`), plus how GRCh38 reference sequence lookup will work in both unit tests (in-memory/indexed test FASTA slice or `ReferenceSequenceFile` abstraction) and runtime (indexed GRCh38 FASTA file path / configurable provider).
- **Done When**: Muse presents the `W1.1` design summary and the user approves moving to `W1.2`.

### Step `W1.2`: Add `htsjdk` Dependency & Liftover Chain Resource (`hg19ToHg38.over.chain.gz`)
- **Agent**: `Implementer` | **Skill**: `liftover-refcheck`
- **Action**:
  1. Add `com.github.samtools:htsjdk` (e.g., version `2.24.1`, compatible with Java 8 / OpenJDK 11) to `genome-nexus/component/pom.xml` (or root `pom.xml` `<dependencyManagement>`).
  2. Add or configure `hg19ToHg38.over.chain.gz` under `genome-nexus/component/src/main/resources/liftover/hg19ToHg38.over.chain.gz` (or downloadable/configurable classpath resource) and verify `new LiftOver(chainFile)` loads cleanly in a smoke test.
- **Verification**:
  ```bash
  export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
  mvn test-compile -pl model,component -B
  ```
- **Done When**: `mvn test-compile -pl model,component -B` succeeds and user approves moving to `W1.3`.

### Step `W1.3`: Implement Variant Pre-Filter & `GRCh37 -> GRCh38` Liftover
- **Agent**: `Implementer` | **Skill**: `liftover-refcheck`, `tdd`
- **Action**:
  1. Create `NormalizedAlphaGenomeVariant.java` and `AlphaGenomeVariantNormalizer.java` in `org.cbioportal.genome_nexus.component.annotation`.
  2. Implement **Step 1 (Pre-Filter)**:
     - Reject (`Optional.empty()`) if `annotation == null`, `!Boolean.TRUE.equals(annotation.getSuccessfullyAnnotated())`, or `annotation.getErrorMessage() != null`.
     - Reject if `seqRegionName`, `start`, `end`, or `alleleString` is null/empty.
     - Normalize chromosome (`23 -> X`, `24 -> Y`, strip `chr` if present); reject if chromosome is `MT` / `M` or not in `{1..22, X, Y}`.
     - Split `alleleString` on `/`; reject if not 2 parts, if `ref.equals(alt)`, or if either allele contains characters outside `^[ACGT-]+$`.
     - If `annotation.getStrand() != null && annotation.getStrand() == -1`, reverse-complement non-`-` alleles via `GenomicLocationUtil.getReverseStrandAllele(...)`.
  3. Implement **Step 2 (`GRCh37 -> GRCh38` Liftover)**:
     - If `assemblyName` is `"GRCh37"` ( since Genome Nexus defaults to GRCh37), lift `new Interval("chr" + chrom, start, end)` using `htsjdk.samtools.liftover.LiftOver`.
     - For insertions (`"-".equals(ref)` where Genome Nexus stores `start` and `end = start + 1` or `end = start - 1`), lift the anchor coordinate consistently.
     - Reject (`Optional.empty()`) if `liftOver(...)` returns `null` or maps to a different chromosome (`!lifted.getContig().equals("chr" + chrom)`).
     - If `assemblyName` is `"GRCh38"`, keep coordinates and ensure `"chr"` prefix.
- **Done When**: Unit tests verify pre-filter rejections (`MT`, `N` bases, `!successfullyAnnotated`, `errorMessage != null`) and `GRCh37 -> GRCh38` coordinate liftover (`7:140453136 -> chr7:140753336`, `5:176940011 -> chr5:177513010`), and user approves moving to `W1.4`.

### Step `W1.4`: Implement MAF Indel Anchor-Base Normalization, Left-Alignment & GRCh38 `REF` Check
- **Agent**: `Implementer` | **Skill**: `liftover-refcheck`, `tdd`
- **Action**:
  1. Introduce a clean `Grch38ReferenceSequenceResolver` interface (backed by `htsjdk` `IndexedFastaSequenceFile` / `ReferenceSequenceFile` when a local FASTA is configured, with a deterministic testable implementation for unit tests).
  2. Implement **Step 3 (VCF Indel Anchoring & Left-Alignment)**:
     - **SNV / MNV (`!ref.equals("-") && !alt.equals("-")`)**:
       - `pos = liftedStart`, `vcfRef = ref`, `vcfAlt = alt`.
     - **Deletion (`alt.equals("-")`)**:
       - Anchor position in GRCh38 is `anchorPos = liftedStart - 1` (or after left-alignment across repetitive sequence in GRCh38).
       - Fetch reference sequence from GRCh38 to left-align the deletion (`while (anchorPos > 1 && refBaseAt(anchorPos) == lastBaseOfDeletedSpan)`) and prepend the 1-bp anchor base at `anchorPos`: `vcfRef = anchorBase + deletedBases`, `vcfAlt = anchorBase`, `pos = anchorPos`.
     - **Insertion (`ref.equals("-")`)**:
       - Seed at the right-flank coordinate (`seedPos = Math.max(liftedStart, liftedEnd)`): the ported `normalize_variant` loop extends left (`position -= 1`) on its first pass because the seed `ref` is empty, landing exactly on the true anchor base. Seeding the left flank (`min`) shifts the result one base too far left. The loop then left-aligns in GRCh38 if repetitive, yielding 1-bp anchor base `anchorBase`: `vcfRef = anchorBase`, `vcfAlt = anchorBase + insertedBases`.
  3. Implement **Step 4 (GRCh38 `REF` Check & Canonical Transcript Extraction)**:
     - Fetch the exact GRCh38 reference bases at `[chr, pos, pos + vcfRef.length() - 1]`.
     - Compare case-insensitively with `vcfRef`. If they do not match, **reject** (`Optional.empty()`).
     - Resolve canonical transcript via `CanonicalTranscriptResolver.resolve(annotation)` to populate `geneId` (strip version suffix if any, e.g., `ENSG00000157764`) and `geneSymbol` (e.g., `BRAF`).
     - Format `variantStr = String.format("%s:%d:%s>%s", chrContig, pos, vcfRef, vcfAlt)`.
- **Done When**: Unit tests pass for SNVs, deletions (`SMAD4` `AA/-` $\rightarrow$ `GAA>G`), insertions (`-/A`), and `REF` mismatch rejection, and user approves moving to `W1.5`.

### Step `W1.5`: Comprehensive Unit Test Suite (`AlphaGenomeVariantNormalizerTest`)
- **Agent**: `Tester` | **Skill**: `tdd`, `debugging`
- **Action**:
  1. Verify all 5 required acceptance test cases in `AlphaGenomeVariantNormalizerTest.java`:
     - **Case 1 (`DDX41` GRCh37 SNV)**: `5:g.176940011C>T` (`seqRegionName="5"`, `start=176940011`, `end=176940011`, `alleleString="C/T"`, `assemblyName="GRCh37"`) $\rightarrow$ `chr5:177513010:C>T`.
     - **Case 2 (`BRAF` V600E GRCh37 SNV)**: `7:g.140453136A>T` (`seqRegionName="7"`, `start=140453136`, `end=140453136`, `alleleString="A/T"`, `assemblyName="GRCh37"`) $\rightarrow$ `chr7:140753336:A>T`.
     - **Case 3 (`SMAD4` `c.1520_1521del` Deletion)**: `18:g.48604697_48604698del` (`seqRegionName="18"`, `start=48604697`, `end=48604698`, `alleleString="AA/-"`) $\rightarrow$ lifts to `chr18`, left-aligns and prepends `G` anchor base $\rightarrow$ `GAA>G` (`ref="GAA"`, `alt="G"`), without using `getHgvsg()`.
     - **Case 4 (Insertion)**: MAF insertion `alleleString="-/T"` $\rightarrow$ prepends GRCh38 anchor base at `pos = end` (or `min(start, end)`).
     - **Case 5 (Rejections)**:
       - `REF` mismatch against GRCh38 FASTA (e.g. `5:g.176940011G>T` where GRCh38 has `C` at `chr5:177513010`) $\rightarrow$ `Optional.empty()`.
       - `seqRegionName="MT"`, `alleleString="A/N"`, `successfullyAnnotated=false`, `errorMessage="bad"` $\rightarrow$ `Optional.empty()`.
  2. Run Maven test suite:
     ```bash
     export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
     export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
     cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus
     mvn test -pl model,component,service -B
     ```
- **Done When**: All tests in `model,component,service` pass with 0 failures and user approves moving to `W1.6`.

### Step `W1.6`: Code Review & Workstream `W1` Sign-Off
- **Agent**: `Reviewer` | **Skill**: `code-review`, `liftover-refcheck`
- **Action**:
  1. Run `git status` and `git diff` in `workspace/genome-nexus`.
  2. Verify adherence to all guardrails (no `getHgvsg()` usage, no sidecar call or MongoDB cache write on rejected variants, clean Java 8 / OpenJDK 11 compatibility).
  3. Update `.muse/state.json` and append completion event to `workstreams/trajectories/event_log.jsonl`.
- **Done When**: Reviewer reports 0 critical findings and user approves `W1` completion.
