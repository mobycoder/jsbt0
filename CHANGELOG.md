# CHANGELOG

All dependency updates, build results, and issues are logged here automatically
by the monthly update agent. Each entry is prepended by the agent after every run.

---

## 2026-03-11 — Initial Setup

### Created
- Project bootstrapped: jsbt0 — Java Spring Boot Template Project Zero
- Build tool: Maven

### Versions
- Spring Boot:   4.0.3  (Maven Central)
- Spring Framework: 7.0.5 (transitive via Boot parent)
- Java LTS:      25  (GraalVM 25.0.2+10.1, arm64)
- GraalVM:       25.0.2
- Spring gRPC:   1.0.0-RC1  (Spring Milestone repo — not yet GA on Maven Central)
- gRPC Java:     1.76.0  (managed by spring-grpc-dependencies BOM)
- Protobuf:      4.32.1  (managed by spring-grpc-dependencies BOM)

### Build Results
- JVM build:    PASS ✓  (mvn verify — 3 tests, ~13s)
- Native build: PASS ✓  (GraalVM native-image, 87 MB Mach-O arm64, 0.053s startup)

### gRPC Services (auto-registered at startup)
- `grpc.health.v1.Health`                      — standard health check (auto-configured by Spring Boot gRPC)
- `mobycode.template.jsbt0.v1.PingService`     — example custom proto service (from ping.proto)
- `grpc.reflection.v1.ServerReflection`        — gRPC reflection for tooling (grpcurl etc.)

### Issues Encountered & Resolutions
1. **spring-grpc-bom does not exist** — correct artifact ID is `spring-grpc-dependencies`.
2. **spring-grpc 1.0.0 not on Maven Central** — only 1.0.0-RC1 available on Spring Milestone repo.
   Added `<repositories>` block for `repo.spring.io/milestone`. Remove when 1.0.0 GA ships.
3. **grpc/protobuf version mismatch** — updated from 1.68.1/3.25.5 to 1.76.0/4.32.1 to match RC1 BOM.
4. **@WebMvcTest removed in Spring Boot 4** — modularization dropped web MVC test slice.
   Controller tests converted to plain unit tests.
5. **Native AOT: ClassNotFoundException for io.grpc.servlet.jakarta.ServletServerBuilder** —
   Spring Boot gRPC RC1 AOT condition evaluation requires this class present even for Netty-only apps.
   Added `io.grpc:grpc-servlet-jakarta` as `<optional>true</optional>` dependency to satisfy it.
6. **BeanDefinitionOverrideException for grpcHealthService** — Spring Boot gRPC auto-configures
   the standard `grpc.health.v1.Health` service via `GrpcServerHealthAutoConfiguration`.
   Removed manual `GrpcHealthService.java` implementation; autoconfiguration handles it.

### Notes for Monthly Update Agent
- When `spring-grpc` graduates to Maven Central (GA release), remove the
  `<repositories>` and `<pluginRepositories>` spring-milestones blocks from pom.xml
  and note the removal here.
- Java LTS 25 is current. Next LTS (Java 29) expected September 2027.
- GraalVM version must always match Java LTS version.
