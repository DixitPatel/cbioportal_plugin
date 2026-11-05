# AGENTS.md — Genome Nexus Backend (`genome-nexus`)

Muse Code reads this file as project rules when running in `/Users/dixitpatel/Documents/Personal-Dev-Workspace/Meta_hackathon/workspace/genome-nexus`.

## 1. Purpose & Workstreams (`W1` & `W3`)

Java 11 / Spring Boot / MongoDB backend annotation service (`:38080` in Docker, `:8888` standalone).
- **`W1` (`skill: liftover-refcheck`)**: Lift GRCh37 variants to GRCh38 (`htsjdk` `LiftOver` with `hg19ToHg38.over.chain.gz`), normalize MAF indels (`-`) to left-aligned VCF anchor-base form, check `REF` against the GRCh38 FASTA, extract canonical transcript `geneId` + `geneSymbol`, and reject variants that fail these checks.
- **`W3` (`skill: genome-nexus-enricher`)**: Add `AnnotationField.ALPHA_GENOME("alpha_genome")`, `AlphaGenome` (`@Document(collection = "alphagenome.annotation")`), `AlphaGenomeAnnotation`, `VariantAnnotation` accessors, `VariantAnnotationMixin` (`@JsonProperty("alpha_genome")`), `AlphaGenomeRepository`, `CachedAlphaGenomeFetcher` (`max_page_size=1`, `extractId` overrides), and `AlphaGenomeAnnotationEnricher`.

## 2. Java 11 Toolchain & Maven Commands

`genome-nexus` requires **OpenJDK 11** (do not use Java 21 for this repository):

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
```

- **Compile (Skip Tests)**:
  `mvn test-compile -DskipTests -B`
- **Run Unit Tests (`model`, `component`, `service`)**:
  `mvn test -pl model,component,service -B`
- **Full Package Build (Skip Tests)**:
  `mvn install -N -DskipTests -B && mvn clean install -DskipTests -B`

## 3. Module Structure

- `model/`: Domain models (`VariantAnnotation.java`, `AnnotationField.java`, `AlphaGenome.java`, `AlphaGenomeAnnotation.java`)
- `persistence/`: Spring Data MongoDB repositories (`AlphaGenomeRepository.java`)
- `component/`: Shared utilities & coordinate/sequence helpers
- `service/`: Enrichers (`AlphaGenomeAnnotationEnricher.java`), cached fetchers (`CachedAlphaGenomeFetcher.java`), and services (`VariantAnnotationService.java`)
- `web/`: REST controllers (`AnnotationController.java`) and Jackson mixins (`VariantAnnotationMixin.java`)
