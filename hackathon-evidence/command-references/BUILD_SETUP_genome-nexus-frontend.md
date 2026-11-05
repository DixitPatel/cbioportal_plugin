# Build & Test Setup Guide: `genome-nexus-frontend`

- **Language**: `typescript/javascript`
- **Build System**: `yarn`
- **Documentation Files Read**: `README.md`, `.nvmrc`, `package.json`
- **Target Node Engine (`package.json`)**: `>=22.18.0`

## Detected Commands
- **Build Command**: `yarn install --non-interactive`
- **Test Command**: `CI=true yarn test --watchAll=false --passWithNoTests`

## Host Toolchain Check
- `node`: `$PROJECT_ROOT/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin/node`
- `yarn`: `$PROJECT_ROOT/agentic-setup/bin/node-v22.18.0-darwin-arm64/bin/yarn`

## Available `package.json` Scripts
```json
{
  "start": "NODE_OPTIONS=--openssl-legacy-provider PORT=3088 react-scripts start",
  "build": "NODE_OPTIONS=--openssl-legacy-provider react-scripts build",
  "test": "NODE_OPTIONS=--openssl-legacy-provider react-scripts test --transformIgnorePatterns \"node_modules/(?!react-markdown)/\"",
  "eject": "react-scripts eject",
  "prettier": "prettier --config ./.prettierrc.js --write './src/**'",
  "test-prettier": "prettier --config ./.prettierrc.js -c './src/**'"
}
```
