# Build & Test Setup Guide: `cbioportal-frontend`

- **Language**: `typescript/javascript`
- **Build System**: `pnpm`
- **Documentation Files Read**: `README.md`, `CONTRIBUTING.md`, `pnpm-workspace.yaml`, `package.json`
- **Target Node Engine (`package.json`)**: `22.18.0`

## Detected Commands
- **Build Command**: `pnpm install --frozen-lockfile`
- **Test Command**: `pnpm --filter genome-nexus-ts-api-client run build`

## Host Toolchain Check
- `node`: `$PROJECT_ROOT/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin/node`
- `pnpm`: `$PROJECT_ROOT/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin/pnpm`

## Available `package.json` Scripts
```json
{
  "prestart": "./scripts/check_build_prereqs.sh",
  "start": "pnpm watch",
  "prestartSSL": "./scripts/check_build_prereqs.sh",
  "startSSL": "pnpm watchSSL",
  "prestartAll": "./scripts/check_build_prereqs.sh",
  "startAll": "concurrently -n packages,app -k \"lerna run watch --parallel\" \"pnpm watch\"",
  "prestartAllSSL": "./scripts/check_build_prereqs.sh",
  "startAllSSL": "concurrently -n packages,app -k \"lerna run watchSSL --parallel\" \"pnpm watchSSL\"",
  "mergeTests": "./scripts/api-test_env.sh && node api-e2e/merge-tests.js",
  "apitests": "cd ./api-e2e && npx tsc && pnpm run mergeTests && node ./run.js",
  "watch": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && cross-env NODE_ENV=development rspack serve -c rspack.config.js",
  "watchSSL": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && cross-env NODE_ENV=development NODE_OPTIONS=--max-old-space-size=4096 rspack serve -c rspack.config.js",
  "clean": "rimraf dist tsDist",
  "updatePackageVersion": "./scripts/update_package_version.sh",
  "build": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && pnpm run buildAll",
  "buildAll": "pnpm run buildModules && pnpm run buildMain",
  "buildMain": "pnpm run clean && pnpm run compileOqlParser && cross-env NODE_ENV=production NODE_OPTIONS=--openssl-legacy-provider --max-old-space-size=4096 rspack build -c rspack.config.js",
  "buildModules": "turbo run build --filter=./packages/*",
  "publishModules": "lerna publish from-git --yes --concurrency 1",
  "publishModulesFromPackages": "lerna publish from-package --yes --concurrency 1",
  "build:size": "pnpm run clean && cross-env NODE_ENV=production rspack build -c rspack.config.js --json > stats.json",
  "buildBootstrap": "sass --style :compressed src/globalStyles/bootstrap-entry.scss src/globalStyles/prefixed-bootstrap.min.css",
  "heroku-postbuild": "pnpm run build && pnpm add pushstate-server@3.0.1 -g",
  "updateAPI": "pnpm run fetchAPI && pnpm run buildAPI && pnpm run updateOncoKbAPI && pnpm run updateGenomeNexusAPI",
  "convertToSwagger2": "./scripts/convert_to_swagger2.sh && pnpm run extendSwagger2Converter",
  "fetchAPILocal": "export CBIOPORTAL_URL=http://localhost:8082 && curl -s -L -k ${CBIOPORTAL_URL}/api/v3/api-docs/public > packages/cbioportal-ts-api-client/src/generated/CBioPortalAPI-docs.json && curl -s -L -k ${CBIOPORTAL_URL}/api/v3/api-docs/internal | json > packages/cbioportal-ts-api-client/src/generated/CBioPortalAPIInternal-docs.json && pnpm run convertToSwagger2",
  "fetchAPI": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && curl -s -L -k ${CBIOPORTAL_URL}/api/v3/api-docs/public  > packages/cbioportal-ts-api-client/src/generated/CBioPortalAPI-docs.json && curl -s -L -k ${CBIOPORTAL_URL}/api/v3/api-docs/internal | json  > packages/cbioportal-ts-api-client/src/generated/CBioPortalAPIInternal-docs.json && pnpm run convertToSwagger2",
  "extendSwagger2Converter": "node scripts/extend_converter.js packages/cbioportal-ts-api-client/src/generated CBioPortalAPI CBioPortalAPIInternal",
  "buildAPI": "node scripts/generate-api.js packages/cbioportal-ts-api-client/src/generated CBioPortalAPI CBioPortalAPIInternal",
  "updateOncoKbAPI": "pnpm run fetchOncoKbAPI && pnpm run buildOncoKbAPI",
  "fetchOncoKbAPI": "curl -s -k https://www.oncokb.org/api/v1/v2/api-docs?group=Public%20APIs | json | grep -v basePath | grep -v termsOfService | grep -v host > packages/oncokb-ts-api-client/src/generated/OncoKbAPI-docs.json",
  "buildOncoKbAPI": "node scripts/generate-api.js packages/oncokb-ts-api-client/src/generated OncoKbAPI",
  "updateG2SAPI": "pnpm run fetchG2SAPI && pnpm run buildG2SAPI",
  "fetchG2SAPI": "curl -s -k http://g2s.genomenexus.org/v2/api-docs?group=api > packages/genome-nexus-ts-api-client/src/generated/Genome2StructureAPI-docs.json",
  "buildG2SAPI": "node scripts/generate-api.js packages/genome-nexus-ts-api-client/src/generated Genome2StructureAPI",
  "updateGenomeNexusAPI": "pnpm run fetchGenomeNexusAPI && pnpm run buildGenomeNexusAPI",
  "fetchGenomeNexusAPI": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && curl -s -L -k ${GENOME_NEXUS_URL}/v2/api-docs | json | grep -v basePath | grep -v termsOfService | grep -v host > packages/genome-nexus-ts-api-client/src/generated/GenomeNexusAPI-docs.json && curl -s -L -k ${GENOME_NEXUS_URL}/v2/api-docs?group=internal | json | grep -v basePath | grep -v termsOfService | grep -v host > packages/genome-nexus-ts-api-client/src/generated/GenomeNexusAPIInternal-docs.json",
  "buildGenomeNexusAPI": "node scripts/generate-api.js packages/genome-nexus-ts-api-client/src/generated GenomeNexusAPI GenomeNexusAPIInternal",
  "updateHotspotGenes": "./scripts/get_hotspot_genes.sh > src/shared/static-data/hotspotGenes.json",
  "compileOqlParser": "cd src/shared/lib/oql && pegjs oql-parser.pegjs",
  "serveDist": "./scripts/serve_dist.sh",
  "serveDistLocalDb": "./end-to-end-test/local/runtime-config/serve_dist.sh",
  "testTime": "start_time=`date +%s` && karma start karma.conf.js && echo run time is $(expr `date +%s` - $start_time) s",
  "test": "pnpm run testMain",
  "typecheck": "tsc --noEmit -p tsconfig.json",
  "check-env": "echo ",
  "testMain": "jest $GREP --env=jsdom --runInBand --ci --reporters=default --reporters=jest-junit",
  "testPackagesCI": "JEST_JUNIT_UNIQUE_OUTPUT_NAME=true JEST_JUNIT_OUTPUT_DIR=/tmp/junit/module/ JEST_JUNIT_OUTPUT_NAME=unit-test-module pnpm run testPackages",
  "testPackages": "lerna run test --ignore=cbioportal-frontend --stream",
  "test:watch": "pnpm run testMain:watch",
  "testMain:watch": "pnpm run testMain --watch",
  "test:debug": "pnpm run test --debug --browsers=Chrome_with_debugging --single-run=false",
  "waitForNetlifyPreview": "node scripts/wait_for_netlify_preview.js",
  "findNetlifyDeployId": "node scripts/find_netlify_deploy_id.js",
  "prettierFixCurrentChanges": "STAGED_AND_CHANGED_FILES=$(git diff HEAD --name-only --cached --diff-filter=d) && ([ -z \"$STAGED_AND_CHANGED_FILES\" ] && echo \"Nothing to prettify\" || (pnpm exec prettier --write $(echo $STAGED_AND_CHANGED_FILES) && git add -f $(echo $STAGED_AND_CHANGED_FILES)))",
  "prettierCheckCircleCI": "./scripts/env_vars.sh && eval \"$(./scripts/env_vars.sh)\" && git remote add cbio-repo https://github.com/cBioPortal/cbioportal-frontend.git 2>/dev/null || true && git fetch cbio-repo $(echo $BRANCH_ENV) && CHANGED_FILES=$(git diff cbio-repo/$(echo $BRANCH_ENV)...HEAD --name-only --diff-filter=d) && [ ! -z \"$CHANGED_FILES\" ] && pnpm exec prettier -c $(echo $CHANGED_FILES) && git remote remove cbio-repo 2>/dev/null || true",
  "prettierFixLocal": "CHANGED_FILES=$(git diff $(echo $BRANCH_ENV) --name-only --diff-filter=d) && ([ ! -z \"$CHANGED_FILES\" ] && pnpm exec prettier --write $(echo $CHANGED_FILES) || echo \"Nothing to prettify\")",
  "prettierAll": "pnpm exec prettier --write $(git ls-files | grep '\\(.js\\|.ts\\|.scss\\|.css\\)')",
  "checkIncorrectImportStatements": "./scripts/check_incorrect_import_statements.sh",
  "e2e:spinup": "./scripts/e2e.sh",
  "e2e:local": "export RETRIES=0 && export CBIOPORTAL_URL=http://localhost:8080 && export && export SCREENSHOT_DIRECTORY=/local/screenshots/ && cd end-to-end-test && pnpm run test-webdriver-manager-local",
  "e2e:remote": "export RETRIES=0 && export CBIOPORTAL_URL=https://www.cbioportal.org && export SCREENSHOT_DIRECTORY=/remote/screenshots/ && rm -r -f end-to-end-test/shared/results && cd end-to-end-test && pnpm run test-webdriver-manager-remote",
  "e2e:report": "npx http-server end-to-end-test -o /shared/imageCompare.html -p 8089",
  "localChromeDriver": "chromedriver"
}
```
