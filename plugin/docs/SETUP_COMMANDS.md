# Setup Commands (Muse-only)

`$PROJECT_ROOT` is the folder holding `workspace/` and `agentic-setup/`.
`plugin/bootstrap.sh` runs all of this for you; this file is the manual
reference behind it.

```bash
================================================================================
META HACKATHON — PART 1: ENVIRONMENT SETUP, API KEYS & DEPENDENCY DOWNLOADS
Root Workspace: "$PROJECT_ROOT"/..
Project Folder: "$PROJECT_ROOT"
Repositories  : "$PROJECT_ROOT"/workspace
================================================================================


================================================================================
SECTION 0: API KEYS & AUTHENTICATION SETUP (INCLUDING MUSE)
================================================================================

# --- Action 0.1: View Central .env File Where All API Keys Are Stored ---
cat ""$PROJECT_ROOT"/agentic-setup/.env"

# --- Action 0.4: Set Google DeepMind AlphaGenome API Key (Domain SDK & Sidecar) ---
sed -i '' 's|^ALPHA_GENOME_API_KEY=.*|ALPHA_GENOME_API_KEY=YOUR_ALPHAGENOME_KEY_HERE|' \
  ""$PROJECT_ROOT"/agentic-setup/.env"

# --- Action 0.5: Set Meta API Key for Muse Code CLI (Takes Priority Over Browser Login) ---
sed -i '' 's|^META_API_KEY=.*|META_API_KEY=YOUR_META_API_KEY_HERE|' \
  ""$PROJECT_ROOT"/agentic-setup/.env"

# --- Action 0.6: Store Meta API Key in Muse CLI Credential Store (via stdin) ---
source ""$PROJECT_ROOT"/agentic-setup/.env"
printf "%s" "$META_API_KEY" | ""$PROJECT_ROOT"/agentic-setup/bin/muse" auth set --provider meta --api-key-stdin

# --- Action 0.7: [Alternative to Action 0.6] Interactive Browser OAuth Login for Muse CLI ---
""$PROJECT_ROOT"/agentic-setup/bin/muse" login


================================================================================
SECTION 1: SYSTEM TOOLCHAIN & RUNTIME INSTALLATION
================================================================================

# --- Action 1.1: Install Maven, OpenJDK 11, OpenJDK 21, pnpm, and yarn via Homebrew ---
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install maven openjdk@11 openjdk@21 pnpm yarn

# --- Action 1.2: Download & Extract Exact Node.js v22.18.0 (Required by cbioportal-frontend & genome-nexus-frontend) ---
mkdir -p ""$PROJECT_ROOT"/agentic-setup/bin"
curl -fsSL https://nodejs.org/dist/v22.18.0/node-v22.18.0-darwin-arm64.tar.gz | tar -xz -C ""$PROJECT_ROOT"/agentic-setup/bin"

# --- Action 1.3: Install Exact pnpm@10.33.0 and yarn@1.22.22 into Node v22.18.0 ---
export PATH=""$PROJECT_ROOT"/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
npm install -g pnpm@10.33.0 yarn@1.22.22

# --- Action 1.4: Copy Muse CLI Binary into Project bin/ Directory ---
mkdir -p ""$PROJECT_ROOT"/agentic-setup/bin"
cp -f ~/.local/bin/muse ""$PROJECT_ROOT"/agentic-setup/bin/muse"
chmod +x ""$PROJECT_ROOT"/agentic-setup/bin/muse"

# --- Action 1.5: Create & Upgrade Python 3.13 Virtual Environment ---
/opt/homebrew/opt/python@3.13/bin/python3.13 -m venv ""$PROJECT_ROOT"/agentic-setup/.venv"
""$PROJECT_ROOT"/agentic-setup/.venv/bin/pip" install --upgrade pip setuptools wheel

# --- Action 1.6: Install Orchestrator & MCP Server Python Dependencies ---
""$PROJECT_ROOT"/agentic-setup/.venv/bin/pip" install "mcp<2" fastapi uvicorn httpx pypdf pytest python-dotenv

# --- Action 1.7: Verify All Installed System Runtimes & Muse Binary ---
export PATH=""$PROJECT_ROOT"/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
node --version
pnpm --version
yarn --version
mvn --version
/opt/homebrew/opt/openjdk@11/bin/java -version
/opt/homebrew/opt/openjdk@21/bin/java -version
/opt/homebrew/opt/python@3.13/bin/python3.13 --version
""$PROJECT_ROOT"/agentic-setup/bin/muse" --version


================================================================================
SECTION 2: REPOSITORY CLONING & WORKSPACE VERIFICATION
================================================================================

# --- Action 2.1: Create Workspace Directory ---
mkdir -p ""$PROJECT_ROOT"/workspace"

# --- Action 2.2: Clone genome-nexus-frontend (if not already present) ---
git clone --depth 1 https://github.com/genome-nexus/genome-nexus-frontend.git ""$PROJECT_ROOT"/workspace/genome-nexus-frontend"

# --- Action 2.3: Clone google-deepmind/alphagenome Official SDK (if not already present) ---
git clone --depth 1 https://github.com/google-deepmind/alphagenome.git ""$PROJECT_ROOT"/workspace/alphagenome"

# --- Action 2.4: List & Verify All 6 Repositories in workspace/ ---
ls -la ""$PROJECT_ROOT"/workspace"


================================================================================
SECTION 3: PYTHON REPOSITORIES — DOWNLOAD & INSTALL LIBRARIES
================================================================================

# --- Action 3.1: [Repo 1: alphagenome] Download & Install Official AlphaGenome SDK Dependencies ---
cd ""$PROJECT_ROOT"/workspace/alphagenome"
""$PROJECT_ROOT"/agentic-setup/.venv/bin/pip" install -e .

# --- Action 3.2: [Repo 2: alphagenome-sidecar] Download & Install Sidecar + Dev Dependencies (FastAPI, Uvicorn, AnnData, Pandas, NumPy, Pytest) ---
cd ""$PROJECT_ROOT"/workspace/alphagenome-sidecar"
""$PROJECT_ROOT"/agentic-setup/.venv/bin/pip" install -e ".[dev]"


================================================================================
SECTION 4: JAVA REPOSITORIES — DOWNLOAD MAVEN DEPENDENCIES
================================================================================

# --- Action 4.1: [Repo 3: genome-nexus] Setup Backend WAR (Fast Track vs Maven Build) ---
# Option A (Recommended — Instant): Use prebuilt WAR shipped with the plugin (commit 4a86895):
mkdir -p ""$PROJECT_ROOT"/workspace/genome-nexus/web/target"
cp ""$PROJECT_ROOT"/plugin/prebuilt/web-4a86895-SNAPSHOT.war" ""$PROJECT_ROOT"/workspace/genome-nexus/web/target/"

# Option B (Manual Full Build): Download All Maven Dependencies & Build (OpenJDK 11, ~15-20 min)
export JAVA_HOME="/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
cd ""$PROJECT_ROOT"/workspace/genome-nexus"
mvn dependency:go-offline -B

# --- Action 4.2: [Repo 4: genome-nexus-annotation-pipeline] Download All Maven Dependencies (OpenJDK 21) ---
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"
cd ""$PROJECT_ROOT"/workspace/genome-nexus-annotation-pipeline"
mvn dependency:go-offline -B


================================================================================
SECTION 5: TYPESCRIPT / FRONTEND REPOSITORIES — DOWNLOAD PACKAGES
================================================================================

# --- Action 5.1: [Repo 5: genome-nexus-frontend] Download Yarn Dependencies (Node v22.18.0) ---
export PATH=""$PROJECT_ROOT"/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd ""$PROJECT_ROOT"/workspace/genome-nexus-frontend"
yarn install --non-interactive

# --- Action 5.2: [Repo 6: cbioportal-frontend] Download pnpm Monorepo Dependencies (Node v22.18.0 + pnpm 10.33.0) ---
export PATH=""$PROJECT_ROOT"/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin:/opt/homebrew/bin:$PATH"
cd ""$PROJECT_ROOT"/workspace/cbioportal-frontend"
pnpm install --frozen-lockfile
```
