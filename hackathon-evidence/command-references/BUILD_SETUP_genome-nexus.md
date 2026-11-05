# Build & Test Setup Guide: `genome-nexus`

- **Language**: `java`
- **Build System**: `maven`
- **Documentation Files Read**: `README.md`, `Dockerfile`, `pom.xml`
- **Target Java Version (`pom.xml`)**: `1.8`

## Detected Commands
- **Build Command**: `mvn install -DskipTests -B`
- **Test Command**: `mvn test -pl model -B`

## Host Toolchain Check
- `java`: `/usr/bin/java`
- `javac`: `/usr/bin/javac`
- `mvn`: `/opt/homebrew/bin/mvn`
