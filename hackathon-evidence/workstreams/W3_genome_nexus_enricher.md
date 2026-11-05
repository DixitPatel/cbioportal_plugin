# Workstream W3: `alpha_genome` Field and Cache (`genome-nexus-enricher`)

- **Workstream ID**: `W3`
- **Skill**: `genome-nexus-enricher`
- **Target Repository**: `genome-nexus` (`workspace/genome-nexus`)
- **Language / Stack**: Java / Spring Boot / MongoDB

---

## 1. Workstream Summary (As-Is from Proposal)

- **`W3` — `genome-nexus-enricher` (`genome-nexus` · Java)**:
  Add `AnnotationField.ALPHA_GENOME`, the `AlphaGenome` model, the `VariantAnnotationMixin` property, `AlphaGenomeRepository`, `CachedAlphaGenomeFetcher` (`max_page_size=1`, `extractId` overrides) and `AlphaGenomeAnnotationEnricher`, following the `MyVariantInfo` pattern.

---

## 2. Architecture and Implementation Details (As-Is from Proposal §2.2)

### 2.2 Genome Nexus Backend Engine (`genome-nexus`)

**Goal**: Lift variants to GRCh38, make cached sidecar calls, and return `alpha_genome` from the annotation endpoints (`genome-nexus`).

- **`AlphaGenomeServiceImpl` and `CachedAlphaGenomeFetcher`**:
  Both follow the `MyVariantInfoServiceImpl` / `CachedMyVariantInfoFetcher` pattern. `CachedAlphaGenomeFetcher` extends `BaseCachedExternalResourceFetcher<AlphaGenome, AlphaGenomeRepository>` with `max_page_size=1`. The fetcher first queries MongoDB (`findAllById`) by `VariantAnnotation.getVariant()`. On a cache miss, it calls the sidecar. The sidecar echoes the original Genome Nexus variant string at the root of its JSON response. `CachedAlphaGenomeFetcher` overrides `extractId(DBObject)` and `extractId(AlphaGenome)` to return it, so `saveToDb` writes `_id = variant` into `alphagenome.annotation`.
- **API wiring**:
  Add `AnnotationField.ALPHA_GENOME("alpha_genome")`, `AlphaGenome` (`@Document(collection = "alphagenome.annotation")`), `AlphaGenomeAnnotation` (`@JsonProperty("alpha_genome")` in `web/.../mixin/VariantAnnotationMixin`), `AlphaGenomeRepository` and `AlphaGenomeAnnotationEnricher`. Register the enricher in `VariantAnnotationService.initPostEnrichmentService`.
- **Cold-cache strategy**:
  For uncached variants, `CachedAlphaGenomeFetcher` sends sidecar calls through a bounded thread pool sized to the AlphaGenome API quota. This replaces the sequential loop in `BaseCachedExternalResourceFetcher`.

---

## 3. Deliverables & Engineering Challenges (As-Is from Proposal §3, §4)

- **Deliverable**:
  - Upstream PR to `genome-nexus` implementing §2.2. Genome Nexus returns the field only when `fields=alpha_genome` is requested.
- **Tissue context**:
  - Genome Nexus has no study or cancer-type context, so scores are stored per `ontology_curie`, and each UI chooses the tissue when it renders them.
- **API cost and latency**:
  - Each unique variant needs one AlphaGenome call. A four-gene TCGA PAAD query (`KRAS`, `TP53`, `SMAD4`, `CDKN2A`) has 301 mutation rows and 158 unique variants. With a cold cache, the AlphaGenome icons render only after 158 calls. The MongoDB cache in §2.2 addresses this.
- **Public API feasibility (GSoC #139, goal 4)**:
  - Measure call latency, cache hit rate and API usage on a TCGA PAAD study to compare the public API with self-hosting.

---

## 4. Additional Instructions for Muse

### Skill & Contracts to Load
- **Skills**: `.agents/skills/genome-nexus-enricher/SKILL.md` (`genome-nexus-enricher`) and `.agents/skills/alphagenome-terms/SKILL.md` (`alphagenome-terms`)
- **Contracts**: `workstreams/contracts/alpha_genome_schema.json` and `workstreams/contracts/sidecar_openapi.yaml`

### Target Files in `workspace/genome-nexus` (Eight-File Pattern)
1. `model/src/main/java/org/cbioportal/genome_nexus/model/AnnotationField.java`: Add `ALPHA_GENOME("alpha_genome")`.
2. `model/src/main/java/org/cbioportal/genome_nexus/model/AlphaGenome.java` & `AlphaGenomeAnnotation.java`: Domain models with `@Document(collection = "alphagenome.annotation")`.
3. `model/src/main/java/org/cbioportal/genome_nexus/model/VariantAnnotation.java`: Add `alphaGenomeAnnotation` field, getter, and setter.
4. `web/src/main/java/org/cbioportal/genome_nexus/web/mixin/VariantAnnotationMixin.java`: Add `@JsonProperty(value = "alpha_genome", index = ...)`.
5. `persistence/src/main/java/org/cbioportal/genome_nexus/persistence/AlphaGenomeRepository.java`: MongoDB repository extending `MongoRepository<AlphaGenome, String>, CustomSparseRepository<AlphaGenome, String>`.
6. `service/src/main/java/org/cbioportal/genome_nexus/service/cached/CachedAlphaGenomeFetcher.java` & `service/internal/AlphaGenomeServiceImpl.java`:
   - `max_page_size = 1`, bounded thread pool for uncached sidecar requests.
   - Override `extractId(DBObject)` and `extractId(AlphaGenome)` to return the echoed `variant` string so `saveToDb` writes `_id = variant` into `alphagenome.annotation`.
   - Build sidecar requests from a map of `variant ID -> normalized GRCh38 variant and canonical gene`.
7. `service/src/main/java/org/cbioportal/genome_nexus/service/enricher/AlphaGenomeAnnotationEnricher.java` & registration in `VariantAnnotationService.initPostEnrichmentService`.
8. `web/src/main/java/org/cbioportal/genome_nexus/web/AnnotationController.java`: Add `alpha_genome` to Swagger `@ApiParam` allowable values.

### Build & Acceptance Test Commands (OpenJDK 11)
```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus
mvn test -pl model,component,service -B
```
