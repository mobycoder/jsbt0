# jsbt0 Monthly Dependency Update Task

You are running as an automated agent. Your working directory is the jsbt0 project root.
Do not ask questions. Make all decisions autonomously based on the rules below.

---

## Goal

Update all dependencies in `pom.xml` to their latest compatible versions, run full JVM
and native builds to verify compatibility, update `CHANGELOG.md` with a dated record of
every change and decision, and push to git only if both builds pass.

---

## Step 1 — Read current state

Read `pom.xml` and record the exact current values of:
- Spring Boot parent version (`<parent><version>`)
- `<spring-grpc.version>`
- `<grpc.version>`
- `<protobuf.version>`
- `<java.version>`

Read `CHANGELOG.md` to understand what changed last month.

Save these as your "original versions" — you will need them if you must revert.

---

## Step 2 — Research latest versions

Use WebSearch for each component. Record both the version number AND where it lives
(Maven Central vs Spring Milestone repo). Today's date is available from `date` command.

### Spring Boot
- Search: `Spring Boot latest stable release [current year]`
- Accept: GA releases only on Maven Central. Reject RC, M, SNAPSHOT.
- Artifact: `org.springframework.boot:spring-boot-starter-parent`
- Confirm on: https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-parent

### Spring gRPC
- Search: `spring-grpc latest version spring boot 4 [current year]`
- Check Maven Central first: `org.springframework.grpc:spring-grpc-dependencies`
  Run: `curl -s "https://search.maven.org/solrsearch/select?q=g:org.springframework.grpc+a:spring-grpc-dependencies&core=gav&rows=5&wt=json"`
- If no GA on Maven Central, check Spring Milestone:
  Run: `curl -s "https://repo.spring.io/milestone/org/springframework/grpc/spring-grpc-dependencies/maven-metadata.xml"`
- Accept preference order: GA on Central > RC on Milestone > keep current
- IMPORTANT: If Spring gRPC has graduated to Maven Central (GA available), remove
  the `<repositories>` and `<pluginRepositories>` spring-milestones blocks from pom.xml.

### gRPC Java and Protobuf
- These are managed by the spring-grpc-dependencies BOM. After you determine the new
  spring-grpc version, read its BOM POM to find the managed grpc.version and protobuf.version:
  Run: `curl -s "https://repo.spring.io/milestone/org/springframework/grpc/spring-grpc-dependencies/VERSION/spring-grpc-dependencies-VERSION.pom"`
  (replace VERSION with the new spring-grpc version)
- Update `<grpc.version>` and `<protobuf.version>` in pom.xml to match the BOM values.
  These must stay in sync — do not leave them at old values.

### Java LTS
- Current LTS: Java 25 (released Sept 2025). Next LTS: Java 29 (expected Sept 2027).
- Only increment if a new LTS has been officially released.
- Search: `Java latest LTS version [current year]` to confirm.
- If Java LTS version increases, GraalVM version must also increase to match.

---

## Step 3 — Determine what needs updating

Compare current vs latest for each component. Build a plan:
- List what will be updated (from → to)
- List what stays the same (and why)

---

## Step 4 — Update pom.xml

Edit `pom.xml` surgically — only change the specific version strings that need updating.
Do not reformat, reorder, or touch anything else.

---

## Step 5 — Run JVM build

First, determine JAVA_HOME:
```bash
if [ -n "$JAVA_HOME" ] && "$JAVA_HOME/bin/java" -version 2>&1 | grep -q "25\|26\|27\|28\|29"; then
  echo "Using JAVA_HOME: $JAVA_HOME"
else
  # macOS local fallback
  export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-25.jdk/Contents/Home
fi
```

Run:
```bash
JAVA_HOME="$JAVA_HOME" mvn -B verify 2>&1
```

### If JVM build PASSES → go to Step 6.

### If JVM build FAILS:
1. Read the error carefully. Identify which dependency caused the failure.
2. Search Maven Central for available versions of that artifact.
3. Try the most recent previous minor version (e.g., if 4.1.0 fails, try 4.0.x latest).
4. Update pom.xml and re-run the JVM build.
5. If the fallback also fails → revert pom.xml to original versions (Step 1 values).
6. Record the failure in CHANGELOG.md (what was tried, what failed, why).
7. Skip Steps 6, 7 (no native build, no git push of code changes).
8. Proceed to Step 8 (log-only commit).

---

## Step 6 — Run native build

```bash
JAVA_HOME="$JAVA_HOME" mvn -B -Pnative native:compile -DskipTests 2>&1
```

### If native build PASSES → go to Step 7.

### If native build FAILS:
- Apply the same fallback logic as Step 5.
- If fallback fails → revert pom.xml, record failure, skip git push of code changes.
- Proceed to Step 8 (log-only commit).

---

## Step 7 — Update CHANGELOG.md

Prepend a new entry directly after the `# CHANGELOG` heading line.
Use exactly this format (adjust content to reflect what actually happened):

```
## YYYY-MM-DD — Monthly Update

### Updated
- Spring Boot: X.X.X → Y.Y.Y
- Spring gRPC: X.X.X → Y.Y.Y  (Maven Central GA / Spring Milestone RC1)
- gRPC Java: X.X.X → Y.Y.Y
- Protobuf: X.X.X → Y.Y.Y
- Spring Milestone repository: removed (spring-grpc graduated to Maven Central)   ← only if applicable

### Unchanged
- Java LTS: 25 (next LTS expected Sept 2027)
- Spring Boot: already at latest (X.X.X)   ← only for components that did not change

### Issues & Resolutions
- [describe any build failures, fallback versions tried, and resolutions]
- None   ← if everything updated cleanly

### Build Results
- JVM build:    PASS ✓ / FAIL ✗
- Native build: PASS ✓ / FAIL ✗
```

If nothing changed at all (all versions already current):
```
## YYYY-MM-DD — Monthly Check

All components already at latest compatible versions. No changes made.

### Build Results
- JVM build:    PASS ✓
- Native build: PASS ✓
```

---

## Step 8 — Commit and push

### If both builds passed (with or without fallbacks, as long as they pass):
```bash
git add pom.xml CHANGELOG.md
git commit -m "chore: monthly dependency update $(date +%Y-%m-%d)

$(grep -A 20 "^## $(date +%Y-%m-%d)" CHANGELOG.md | head -20)"
git push
```

### If builds failed and pom.xml was reverted (log-only):
```bash
git add CHANGELOG.md
git commit -m "chore: monthly update log $(date +%Y-%m-%d) — no version changes (build failures, see CHANGELOG.md)"
git push
```

### If nothing changed (no updates available):
```bash
git add CHANGELOG.md
git commit -m "chore: monthly update log $(date +%Y-%m-%d) — no updates available"
git push
```

---

## Hard rules

1. **Never push broken code.** pom.xml changes are only pushed when both builds pass.
2. **Always push CHANGELOG.md**, even if it's just a "nothing changed" or "failed" entry.
3. **Never downgrade** a version unless forced by a build failure.
4. **Never modify** anything other than `pom.xml` and `CHANGELOG.md` (and git operations).
5. **One fallback attempt** per component — do not loop indefinitely.
6. **Document everything** — every version tried, every error seen, every decision made.
