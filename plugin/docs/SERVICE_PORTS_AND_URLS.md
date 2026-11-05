# Service Ports, Endpoints & Sample URLs Reference

**Project Root**: `$PROJECT_ROOT`  
**Last Updated**: October 27, 2026  

---

## 1. Master Service Ports & Protocol Summary

| Service | Protocol | Host Port | Internal / Target Port | Base URL |
| :--- | :--- | :--- | :--- | :--- |
| **cBioPortal Frontend** | HTTPS *(Self-Signed / CORS)* | `3000` | `3000` | `https://localhost:3000` |
| **Genome Nexus Frontend** | HTTP | `3088` | `3088` | `http://localhost:3088` |
| **Genome Nexus Backend** | HTTP | `38080` | `38080` | `http://localhost:38080` |
| **Genome Nexus MongoDB (`gn-mongo`)** | TCP / Mongo | `27017` | `27017` | `mongodb://127.0.0.1:27017/annotator` |
| **AlphaGenome Scoring Sidecar** | HTTP | `8000` | `8000` | `http://localhost:8000` |
| **Host Setup HTTP Bridge** | HTTP | `8005` | `8005` | `http://localhost:8005` |

---

## 2. cBioPortal Frontend (`https://localhost:3000`)

> [!NOTE]
> `rspack.config.js` configures the dev server with `server: 'https'` and `Access-Control-Allow-Origin: *`.
> When opening `https://localhost:3000/` in Chrome or Safari for the first time, click **Advanced -> Proceed to localhost** to accept the self-signed developer certificate.

### Sample Interactive Pages
* **Application Home**:
  `https://localhost:3000/`
* **Study Summary View (MSK-IMPACT 2017)**:
  `https://localhost:3000/study/summary?id=msk_impact_2017`
* **Study Clinical Data Table**:
  `https://localhost:3000/study/clinicalData?id=msk_impact_2017`
* **Patient / Case Clinical View**:
  `https://localhost:3000/patient?studyId=lgg_ucsf_2014&caseId=P04`
* **Results View — Mutations Table (Single Gene: TP53)**:
  `https://localhost:3000/results/mutations?cancer_study_list=msk_impact_2017&case_set_id=msk_impact_2017_all&gene_list=TP53`
* **Results View — Mutations Table (Multi-Gene TCGA Pancreatic Cancer / PAAD)**:
  `https://localhost:3000/results/mutations?cancer_study_list=paad_tcga_pan_can_atlas_2018&case_set_id=paad_tcga_pan_can_atlas_2018_all&gene_list=KRAS%20TP53%20SMAD4%20CDKN2A`
* **Results View — OncoPrint**:
  `https://localhost:3000/results/oncoprint?cancer_study_list=msk_impact_2017&case_set_id=msk_impact_2017_all&gene_list=TP53%20EGFR%20KRAS`
* **Results View — Cancer Types Summary**:
  `https://localhost:3000/results/cancerTypesSummary?cancer_study_list=msk_impact_2017&case_set_id=msk_impact_2017_all&gene_list=TP53`

### Development Bundles & Assets
* **Common Bundle (Vendor + Shared)**:
  `https://localhost:3000/reactapp/common.bundle.js`
* **Main Application Bundle**:
  `https://localhost:3000/reactapp/main.app.js`
* **Prefixed Bootstrap Stylesheet**:
  `https://localhost:3000/reactapp/prefixed-bootstrap.min.css`

### Production Live Mounting (`localdev` Bookmarklet / Console)
Mount your local frontend onto the live public cBioPortal instance to test UI changes against live production databases:
* Open `https://www.cbioportal.org`
* Open Developer Console (`Cmd + Option + J`) and execute:
  ```javascript
  localStorage.setItem("localdev", true);
  location.reload();
  ```
* To revert back to standard production scripts:
  ```javascript
  localStorage.setItem("localdev", false);
  location.reload();
  ```

---

## 3. Genome Nexus Frontend (`http://localhost:3088`)

> [!TIP]
> Genome Nexus Frontend runs on Create React App (`react-scripts start`) on port `3088` and connects by default to `https://www.genomenexus.org` (or `http://localhost:8888` when using `--local-gn`).

### Sample Variant Pages
* **Application Home & Search**:
  `http://localhost:3088/`
* **EGFR L858R (Sensitive & Resistant on Therapeutic Implication)**:
  `http://localhost:3088/variant/7:g.55249071C>T`
* **BRAF V600E (Standard Oncogenic Hotspot)**:
  `http://localhost:3088/variant/7:g.140453136A>T`
* **BRAF V600E (With Explicit Ensembl Canonical Transcript)**:
  `http://localhost:3088/variant/7:g.140453136A>T?transcriptId=ENST00000288602`
* **TP53 R175H (Multi-level Functional Impact)**:
  `http://localhost:3088/variant/17:g.7577121G>A`
* **NRAS Q61K (Long Therapeutic Name)**:
  `http://localhost:3088/variant/1:g.115256529T>C`
* **BRCA1 Indel**:
  `http://localhost:3088/variant/17:g.41226411G>A`
* **PIK3CA Complex In-frame Deletion (Differing Protein Changes Across DBs)**:
  `http://localhost:3088/variant/3:g.178952152_178952162del`
* **TERT Promoter Mutation**:
  `http://localhost:3088/variant/5:g.1295228G>A`

### Development Bundles & Assets
* **Main CRA Bundle**:
  `http://localhost:3088/static/js/bundle.js`
* **Main 0 Chunk**:
  `http://localhost:3088/static/js/0.chunk.js`
* **Main App Chunk**:
  `http://localhost:3088/static/js/main.chunk.js`

---

## 4. Genome Nexus Backend Engine (`http://localhost:38080` & Public)

### Endpoints
* **Swagger UI Documentation**:
  `http://localhost:38080/swagger-ui.html`
* **OpenAPI 2.0 / Swagger JSON Spec**:
  `http://localhost:38080/v2/api-docs`
* **Single Variant Annotation (Default Fields)**:
  `http://localhost:38080/annotation/7:g.140453136A%3ET`
* **Single Variant Annotation with AlphaGenome Prediction Field (Workstream W3)**:
  `http://localhost:38080/annotation/7:g.140453136A%3ET?fields=annotation_summary,alpha_genome`
* **Batch Variant Annotation**:
  `POST http://localhost:38080/annotation`
  ```json
  [
    "7:g.140453136A>T",
    "7:g.55249071C>T",
    "17:g.7577121G>A"
  ]
  ```
* **Public Production GRCh37 Fallback**:
  `https://www.genomenexus.org/v2/api-docs`  
  `https://www.genomenexus.org/annotation/7:g.140453136A%3ET`
* **Public Production GRCh38 Fallback**:
  `https://grch38.genomenexus.org/v2/api-docs`

---

## 5. AlphaGenome Scoring Sidecar Service (`http://localhost:8000`)

### Endpoints
* **Interactive OpenAPI Swagger Docs**:
  `http://localhost:8000/docs`
* **Interactive ReDoc Documentation**:
  `http://localhost:8000/redoc`
* **OpenAPI Schema JSON**:
  `http://localhost:8000/openapi.json`
* **Service Health Check**:
  `http://localhost:8000/health`
* **Variant Scoring Endpoint**:
  `POST http://localhost:8000/score`
  ```json
  {
    "chromosome": "chr7",
    "position": 140753336,
    "reference_allele": "A",
    "alternate_allele": "T",
    "canonical_gene": "BRAF"
  }
  ```

---

## 6. Orchestration & LLM Gateways

| Service | Port | Endpoint / URL | Health / Verification Command |
| :--- | :--- | :--- | :--- |
| **Host Setup Bridge** | `:8005` | `http://localhost:8005/health` | `curl -s http://localhost:8005/health` |

---

## 7. Quick Startup Commands Reference

```bash
# 1. Start cBioPortal Frontend (Port 3000, HTTPS)
$PROJECT_ROOT/workspace/startup_scripts/start_cbioportal_frontend.sh --public-gn

# 2. Start Genome Nexus Frontend (Port 3088, HTTP)
$PROJECT_ROOT/workspace/startup_scripts/start_genome_nexus_frontend.sh

# 3. Check active listening ports
lsof -i :3000 -i :3088 -i :8888 -i :8000 -i :4000 -i :5678
```
