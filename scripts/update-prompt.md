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
  spring-grpc version, read its BOM POM to find the managed grpc.version and protobuf.version.
  Use the correct repository depending on where the version lives:
  - If the new spring-grpc version is GA on Maven Central:
    `curl -s "https://repo.maven.apache.org/maven2/org/springframework/grpc/spring-grpc-dependencies/VERSION/spring-grpc-dependencies-VERSION.pom"`
  - If the new spring-grpc version is RC/Milestone only:
    `curl -s "https://repo.spring.io/milestone/org/springframework/grpc/spring-grpc-dependencies/VERSION/spring-grpc-dependencies-VERSION.pom"`
  (replace VERSION with the new spring-grpc version in both cases)
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

## Step 4 — Sync with remote before making any changes

Before editing anything, ensure the local repo is up to date with origin in case
GitHub Actions already ran an update this month:
```bash
git pull --rebase
```
If this fails (e.g., uncommitted changes), abort with an appropriate CHANGELOG entry
and do not proceed.

## Step 5 — Update pom.xml

Edit `pom.xml` surgically — only change the specific version strings that need updating.
Do not reformat, reorder, or touch anything else.

---

## Step 6 — Run JVM build

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

### If JVM build PASSES → go to Step 7.

### If JVM build FAILS:
1. Read the error carefully. Identify which dependency caused the failure.
2. Search Maven Central for available versions of that artifact.
3. Try the most recent previous minor version (e.g., if 4.1.0 fails, try 4.0.x latest).
4. Update pom.xml and re-run the JVM build.
5. If the fallback also fails → revert pom.xml to original versions (Step 1 values).
6. Record the failure in CHANGELOG.md (what was tried, what failed, why).
7. Skip Steps 7, 8 (no native build, no git push of code changes).
8. Proceed to Step 9 (log-only commit).

---

## Step 7 — Run native build

```bash
JAVA_HOME="$JAVA_HOME" mvn -B -Pnative native:compile -DskipTests 2>&1
```

### If native build PASSES → go to Step 8.

### If native build FAILS:
1. Read the error carefully.
2. Revert ALL pom.xml version changes back to the original Step 1 values — do not
   attempt per-component fallbacks at this stage, since the JVM build already passed
   and the native failure may be caused by an interaction between multiple updated
   components. A clean revert is safer than partial rollback.
3. Record the failure in CHANGELOG.md: what was tried, what the native error was,
   and that all versions were reverted.
4. Skip git push of pom.xml changes.
5. Proceed to Step 9 (log-only commit).

---

## Step 8 — Update CHANGELOG.md

Prepend a new entry directly after the `# CHANGELOG` heading line.
Use exactly this format (adjust content to reflect what actually happened):

Only include sections that are relevant. Do not copy placeholder text or instructions
into the actual CHANGELOG entry.

```
## YYYY-MM-DD — Monthly Update

### Updated
- Spring Boot: X.X.X → Y.Y.Y
- Spring gRPC: X.X.X → Y.Y.Y  (Maven Central GA)
- gRPC Java: X.X.X → Y.Y.Y
- Protobuf: X.X.X → Y.Y.Y
- Spring Milestone repository: removed (spring-grpc graduated to Maven Central)

### Unchanged
- Java LTS: 25 (next LTS expected Sept 2027)

### Issues & Resolutions
- None

### Build Results
- JVM build:    PASS ✓
- Native build: PASS ✓
```

Rules for each section:
- **Updated**: only list components whose version actually changed. If spring-grpc is
  still on Milestone, note that. If it graduated to Central, include the "removed" line.
- **Unchanged**: only list components that were checked but not changed. Omit this
  section entirely if everything was updated.
- **Issues & Resolutions**: write "None" if everything updated cleanly. Otherwise
  describe each failure, what fallback was tried, and the outcome.
- **Build Results**: always include both lines with actual PASS/FAIL result.

If nothing changed at all (all versions already current):
```
## YYYY-MM-DD — Monthly Check

All components already at latest compatible versions. No changes made.

### Build Results
- JVM build:    PASS ✓
- Native build: PASS ✓
```

---

## Step 9 — Commit and push

Write the commit message to a temp file first to avoid shell-quoting issues with
CHANGELOG content (backticks, dollar signs, or quotes in the log would break an
inline `-m "..."` argument).

### If both builds passed (with or without fallbacks, as long as they pass):
```bash
TODAY=$(date +%Y-%m-%d)
printf 'chore: monthly dependency update %s\n\nSee CHANGELOG.md for full details.' "$TODAY" > /tmp/jsbt0-commit-msg.txt
git add pom.xml CHANGELOG.md
git commit -F /tmp/jsbt0-commit-msg.txt
git push
rm -f /tmp/jsbt0-commit-msg.txt
```

### If builds failed and pom.xml was reverted (log-only):
```bash
TODAY=$(date +%Y-%m-%d)
printf 'chore: monthly update log %s — no version changes\n\nBuild failures encountered. See CHANGELOG.md for details.' "$TODAY" > /tmp/jsbt0-commit-msg.txt
git add CHANGELOG.md
git commit -F /tmp/jsbt0-commit-msg.txt
git push
rm -f /tmp/jsbt0-commit-msg.txt
```

### If nothing changed (no updates available):
```bash
TODAY=$(date +%Y-%m-%d)
printf 'chore: monthly update log %s — no updates available\n\nAll components already at latest compatible versions.' "$TODAY" > /tmp/jsbt0-commit-msg.txt
git add CHANGELOG.md
git commit -F /tmp/jsbt0-commit-msg.txt
git push
rm -f /tmp/jsbt0-commit-msg.txt
```

---

## Hard rules

1. **Never push broken code.** pom.xml changes are only pushed when both builds pass.
2. **Always push CHANGELOG.md**, even if it's just a "nothing changed" or "failed" entry.
3. **Never downgrade** a version unless forced by a build failure.
4. **Never modify** anything other than `pom.xml` and `CHANGELOG.md` (and git operations).
5. **One fallback attempt** per component — do not loop indefinitely.
6. **Document everything** — every version tried, every error seen, every decision made.
