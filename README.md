# jsbt0 — Java Spring Boot Template Project Zero

A **living template** for new Spring Boot projects. Fork or copy this to skip
the scaffolding ceremony and start with a known-good, up-to-date baseline.

---

## Current versions (update this table when you bump deps)

| Component            | Version      | Notes                                                      |
|----------------------|--------------|------------------------------------------------------------|
| Spring Boot          | 4.0.3        | Latest stable as of 2026-02                                |
| Spring Framework     | 7.0.5        | Transitive via Boot                                        |
| Java (LTS)           | 25           | Latest LTS; also the GraalVM baseline                      |
| GraalVM (native)     | 25+          | **Required** for native image builds                       |
| Spring gRPC          | 1.0.0-RC1    | Boot 4.x compatible; from repo.spring.io/milestone         |
| gRPC Java            | 1.76.0       | Managed via spring-grpc-dependencies BOM                   |
| Protobuf             | 4.32.1       | Managed via spring-grpc-dependencies BOM                   |

> **Spring gRPC note:** `1.0.0-RC1` is the first release targeting Spring Boot 4.0.x.
> Once `1.0.0` lands on Maven Central, remove the `spring-milestones` repository
> from `pom.xml` and update `<spring-grpc.version>` to `1.0.0`.

> **Spring Boot 4 test note:** `@WebMvcTest` was removed in Spring Boot 4 as part of
> module modularization. Controller tests use plain unit tests or
> `@SpringBootTest(webEnvironment=RANDOM_PORT)` with `TestRestTemplate` instead.

---

## Prerequisites

| Mode         | Requirement                                             |
|--------------|---------------------------------------------------------|
| JVM          | JDK 25+ (any distribution — e.g. Eclipse Temurin)      |
| Native       | GraalVM JDK 25+ (`sdk install java 25-graalvm`)         |
| Native (Win) | GraalVM 25 + Visual Studio Build Tools 2022 on PATH     |

Install GraalVM with SDKMAN:
```bash
sdk install java 25-graalvm
sdk use java 25-graalvm
```

---

## Build & Run

### JVM mode (default)

```bash
# Run in dev
mvn spring-boot:run

# Package fat JAR
mvn package
java -jar target/jsbt0-0.0.1-SNAPSHOT.jar
```

### Native mode

```bash
# Compile native executable (slow — AOT compilation)
mvn -Pnative native:compile

# Run the native binary
./target/jsbt0          # Linux / macOS
target\jsbt0.exe        # Windows
```

---

## Endpoints

### REST (HTTP on port 8080)

| Method | Path               | Description                          |
|--------|--------------------|--------------------------------------|
| GET    | `/health`          | Custom JSON: `{"status":"UP"}`       |
| GET    | `/actuator/health` | Spring Actuator: full component tree |
| GET    | `/actuator/info`   | App info from application.yml        |

### gRPC (port 9090)

Implements the standard [gRPC Health Checking Protocol](https://github.com/grpc/grpc/blob/master/doc/health-checking.md):

```bash
# Requires grpcurl (https://github.com/fullstorydev/grpcurl)

# Health check
grpcurl -plaintext localhost:9090 grpc.health.v1.Health/Check

# Example Ping service (from ping.proto)
grpcurl -plaintext -d '{"message":"hello"}' localhost:9090 \
  mobycode.template.jsbt0.v1.PingService/Ping
```

---

## Project structure

```
jsbt0/
├── .github/workflows/ci.yml           # CI: JVM tests + native matrix (Linux/macOS/Win)
├── src/
│   ├── main/
│   │   ├── java/mobycode/template/jsbt0/
│   │   │   ├── Jsbt0Application.java          # Entry point
│   │   │   ├── controller/
│   │   │   │   └── HealthController.java      # GET /health → JSON
│   │   │   └── grpc/
│   │   │       ├── GrpcHealthService.java     # grpc.health.v1 standard health check
│   │   │       └── PingGrpcService.java       # Example custom proto service
│   │   ├── proto/mobycode/template/jsbt0/v1/
│   │   │   └── ping.proto                     # Example proto — replace with your own
│   │   └── resources/
│   │       └── application.yml
│   └── test/
│       └── java/mobycode/template/jsbt0/
│           ├── controller/HealthControllerTest.java
│           └── grpc/GrpcHealthServiceTest.java
└── pom.xml
```

---

## How to add a custom gRPC service

1. Add a `.proto` file under `src/main/proto/`
2. Generate Java stubs:
   ```bash
   mvn generate-sources
   ```
3. Create a class that extends the generated `*ImplBase` and annotate it:
   ```java
   @GrpcService
   public class MyService extends MyServiceGrpc.MyServiceImplBase { ... }
   ```
4. Delete `ping.proto` and `PingGrpcService.java` once you have your own.

---

## CI overview

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs two jobs:

| Job    | OS                               | What it does                        |
|--------|----------------------------------|-------------------------------------|
| test   | ubuntu-latest (Temurin 25)       | `mvn verify` — unit + integration   |
| native | ubuntu / macos / windows (GVM25) | `mvn -Pnative native:compile`        |

Native binaries are uploaded as workflow artifacts on each run.

---

## Automated monthly updates (Claude Code)

This template updates itself automatically on the 1st of every month using
Claude Code as the update agent. It researches the latest compatible versions,
edits `pom.xml`, runs full JVM and native builds, and pushes only if both pass.
Every run appends a dated entry to `CHANGELOG.md` regardless of outcome.

### How it works

```
Trigger (GitHub Actions schedule or launchd cron)
  → Claude reads scripts/update-prompt.md
  → WebSearch: latest Spring Boot, Spring gRPC, Java LTS
  → Edit pom.xml
  → mvn -B verify          (JVM build + tests)
  → mvn -Pnative native:compile  (native build)
  → if PASS: git commit + push pom.xml + CHANGELOG.md
  → if FAIL: revert pom.xml, push CHANGELOG.md only (with failure notes)
```

### Primary: GitHub Actions (cloud, always-on)

1. Push this repo to GitHub.
2. Add your Anthropic API key as a repository secret named `ANTHROPIC_API_KEY`:
   **Settings → Secrets and variables → Actions → New repository secret**
3. Done. The workflow (`.github/workflows/monthly-update.yml`) fires at 02:00 UTC
   on the 1st of every month. Trigger it manually anytime from the **Actions** tab.

### Secondary: Local launchd (macOS backup trigger)

Use this if you want ad-hoc local runs between monthly cycles, or if the repo
is not on GitHub.

**One-time setup:**
```bash
# 1. Store your API key securely (chmod 600 keeps it private)
mkdir -p ~/.config/jsbt0
echo 'ANTHROPIC_API_KEY=sk-ant-YOUR_KEY_HERE' > ~/.config/jsbt0/env
chmod 600 ~/.config/jsbt0/env

# 2. Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# 3. Install the launchd agent
cp scripts/com.mobycode.jsbt0.monthly-update.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.mobycode.jsbt0.monthly-update.plist
```

**Manual trigger (test it now):**
```bash
bash scripts/monthly-update.sh
```

**Check launchd status:**
```bash
launchctl list | grep jsbt0
```

**Uninstall:**
```bash
launchctl unload ~/Library/LaunchAgents/com.mobycode.jsbt0.monthly-update.plist
rm ~/Library/LaunchAgents/com.mobycode.jsbt0.monthly-update.plist
```

> **Note:** launchd only fires if the Mac is awake at 02:00 on the 1st.
> It does **not** retry missed runs. GitHub Actions is the reliable primary trigger.

### Fallback logic

The update agent follows this decision tree for each component:

```
Latest version → JVM build → PASS?
                               ├─ YES → Native build → PASS?
                               │                        ├─ YES → commit + push
                               │                        └─ NO  → try N-1 version → repeat
                               └─ NO  → try N-1 version → PASS?
                                                           ├─ YES → native build ...
                                                           └─ NO  → revert all, log failure
```

### Logs

- **GitHub Actions**: see the Actions tab in your GitHub repo
- **Local runs**: `logs/update-YYYY-MM.log`
- **All runs**: `CHANGELOG.md` — human-readable record of every update
