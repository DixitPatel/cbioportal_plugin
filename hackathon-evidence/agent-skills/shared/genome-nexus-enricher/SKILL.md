---
name: genome-nexus-enricher
description: Add the alpha_genome annotation field, MongoDB cache repository, cached sidecar fetcher, and post-enricher to genome-nexus following the MyVariantInfo and ClinVar patterns.
---

# Genome Nexus Enricher (`W3`)

Use this skill when implementing or modifying the `alpha_genome` annotation field and sidecar caching layer in `genome-nexus` (Java 11 / Spring Boot / MongoDB).

## Eight-File Implementation Pattern

Follow the existing `MyVariantInfo` and `ClinVar` post-enricher architecture across the `model`, `persistence`, `component`, `service`, and `web` modules:

1. **Enum (`model`)**:
   - Add `ALPHA_GENOME("alpha_genome")` to `org.cbioportal.genome_nexus.model.AnnotationField`.
2. **Domain Models (`model`)**:
   - Create `AlphaGenome` annotated with `@Document(collection = "alphagenome.annotation")` storing `variant` (`@Id`), `hg38Variant`, `interval`, `modelVersion`, `mergedSplicingScore`, `scores`, and optional `literature`.
   - Create `AlphaGenomeAnnotation` wrapper containing `license` and `AlphaGenome annotation`.
3. **VariantAnnotation Accessors (`model`)**:
   - Add `private AlphaGenomeAnnotation alphaGenomeAnnotation;` with getter and setter on `VariantAnnotation`.
4. **JSON Mixin (`web`)**:
   - Add `@JsonProperty(value = "alpha_genome", index = ...)` in `org.cbioportal.genome_nexus.web.mixin.VariantAnnotationMixin`.
5. **MongoDB Repository (`persistence`)**:
   - Create `AlphaGenomeRepository extends MongoRepository<AlphaGenome, String>, CustomSparseRepository<AlphaGenome, String>`.
6. **Cached External Fetcher (`service`)**:
   - Create `CachedAlphaGenomeFetcher extends BaseCachedExternalResourceFetcher<AlphaGenome, AlphaGenomeRepository>` with `max_page_size = 1`.
   - Override `extractId(DBObject)` and `extractId(AlphaGenome)` to return the echoed Genome Nexus `variant` string so `saveToDb` writes `_id = variant` into `alphagenome.annotation`.
   - Build sidecar request bodies from a pre-computed map of `variant -> NormalizedAlphaGenomeRequest` (since `BaseCachedExternalResourceFetcher` passes only ID strings to `buildRequestBody`).
7. **Service & Post-Enricher (`service`)**:
   - Create `AlphaGenomeService` / `AlphaGenomeServiceImpl` and `AlphaGenomeAnnotationEnricher extends BaseAnnotationEnricher`.
   - Register `AlphaGenomeAnnotationEnricher` in `VariantAnnotationService.initPostEnrichmentService` when `fields.contains(AnnotationField.ALPHA_GENOME)`.
8. **Controller Swagger Docs (`web`)**:
   - Add `alpha_genome` to the `@ApiParam` allowable values in `AnnotationController.java`.

## Build & Test Commands (OpenJDK 11 Required)

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
cd /Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus
mvn test -pl model,component,service -B
```
