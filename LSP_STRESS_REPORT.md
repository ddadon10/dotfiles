# Mixed Java + Kotlin Spring Boot Neovim LSP stress report

Date: 2026-07-30

## Outcome

The final stable headless run executed 71 checks:

- 61 passed
- 3 failed reproducibly
- 7 were unsupported because the server did not advertise the capability
- Both clients detached all buffers and shut down gracefully
- No JDTLS or Kotlin LSP process remained after the run

The three failures are narrow:

1. A rename initiated by JDTLS on a Java declaration updates Java files but
   omits Kotlin source references.
2. Kotlin LSP advertises type hierarchy but returns `nil` for a same-language
   Kotlin class.
3. Kotlin LSP also returns `nil` for a Kotlin interface implemented by Java.

There is a working rename mitigation: initiating the rename from a Kotlin usage
through Kotlin LSP updates both the Kotlin usage and the Java declaration and
implementation.

## Artifacts

- Project: `/tmp/nvim-java-kotlin-spring-lsp-stress`
- Headless harness: `/workspace/lsp-stress.lua`
- Final raw result: `/tmp/nvim-java-kotlin-spring-lsp-stress/lsp-stress-final-stable.json`
- Earlier true-cold result: `/tmp/nvim-java-kotlin-spring-lsp-stress/lsp-stress-cold.json`

## Environment and installation

| Component | Tested version |
|---|---|
| Neovim | 0.12.4 |
| Java | OpenJDK 21.0.11-ea |
| JDTLS | 1.60.0 milestone |
| Kotlin LSP | LS-262.9593.0 |
| Kotlin LSP runtime | bundled JBR 25.0.2 |
| Spring Boot | 4.1.0 |
| Spring Framework | 7.0.8 |
| Kotlin Gradle plugin | 2.3.21 |
| Gradle wrapper | 9.5.1 |

The test `PATH` contained the exact extracted server artifacts represented by
the repository Dockerfile:

- JDTLS archive SHA-256:
  `e94c303d8198f977930803582738771fd18c52c5492878410bf222b1aa81ef1d`
- ARM64 Kotlin LSP SHA-256:
  `2317831c6e5607d05b7ebc1da655330125ce0e3d66fbf24517dfce442debc14e`

The Spring Initializr Gradle wrapper installed Gradle 9.5.1. The project passed
`./gradlew clean test`, including Spring context startup, JPA initialization,
H2, Kotlin compilation, and Java compilation.

## Fixture

The project contains seven Java files and eight Kotlin files under `src/main`.
It uses Spring Web MVC, Validation, Data JPA, H2, and Actuator.

The cross-language graph is intentionally bidirectional:

- Java `JavaGreetingService` depends on Kotlin `GreetingFormatter`.
- Kotlin `CustomerFacade` depends on Java `CustomerRepository` and
  `GreetingPort`.
- Java `ActiveCustomerPolicy` implements Kotlin `CustomerPolicy`.
- Java `JavaProbe` depends on Kotlin `CustomerFacade` and `CustomerView`.
- Kotlin controllers navigate into Spring Framework classes and Java/JDK
  classes.

## Method

The harness starts Neovim headlessly with the real repository `init.lua`. It
opens Java and Kotlin buffers concurrently, waits for each client, and then
polls a cross-language definition until semantic project import is usable.

Every feature is exercised with an actual LSP request. Results are validated
against expected file URIs, symbols, completion labels, edit sets, diagnostics,
or source contents. In-memory error and formatting probes are restored without
writing invalid source to disk. Rename edits are inspected but not applied.

Stress cases include 25 concurrent hover requests per server, 20 rapid
incremental changes per language, multiple attached buffers, archive source
loading, and repeated cold/warm client lifecycles.

## Startup and lifecycle

| Run | Cache state | Semantic readiness |
|---|---|---|
| Initial Spring run | Both project caches absent | Both usable in about 39.4 s |
| Clean JDTLS, warm Kotlin | JDTLS rebuilt, Kotlin reused | Both usable in about 9.3 s |
| Final warm run | Both reused | Both usable in about 3.6 s |

The final feature matrix took 21.6 seconds after startup and shut down
gracefully.

An earlier harness version force-stopped clients with edited buffers attached.
On the next start JDTLS reported an unclean workspace and Buildship hit an OSGi
bundle-lock timeout. The stalled cache was preserved at
`/tmp/jdtls-stalled-cache-20260730`. The final harness sends `didClose`, detaches
all buffers, and performs a graceful shutdown. A real crash or `SIGKILL` could
still produce this JDTLS recovery case; `:JdtWipeDataAndRestart` is the recovery
command supplied by `nvim-jdtls`.

## Per-feature results

Status meanings:

- PASS: an actual request returned the expected semantic result.
- FAIL: the server advertised or performed the base operation, but the tested
  result was missing.
- UNSUPPORTED: the server did not advertise the capability, so a normal Neovim
  client would not issue the request.

| Feature | Language | How it was tested | Result |
|---|---|---|---|
| Server attachment and root | Java | Opened `JavaGreetingService.java`; inspected the attached client, root, command, and `-data` path. | PASS: one JDTLS client, correct root and hashed workspace. |
| Server attachment and root | Kotlin | Opened `KotlinProbe.kt`; inspected client, root, command, and `--system-path`. | PASS: one Kotlin client, correct root and hashed system path. |
| Clean baseline diagnostics | Java | Read published diagnostics for a compiled source buffer. | PASS: zero errors. |
| Clean baseline diagnostics | Kotlin | Issued `textDocument/diagnostic` after project import. | PASS: zero errors; response in 1.76 s. |
| Same-language definition | Java | Requested definition of `CustomerStatus` from `ActiveCustomerPolicy`. | PASS: `CustomerStatus.java`. |
| Same-language definition | Kotlin | Requested definition of `CustomerFacade` from the controller. | PASS: `CustomerFacade.kt`. |
| Java-to-Kotlin definition | Java | Requested `GreetingFormatter` from Java service code. | PASS: `GreetingFormatter.kt`. |
| Kotlin-to-Java definition | Kotlin | Requested `Customer` from `KotlinProbe`. | PASS: `Customer.java`. |
| Type definition | Java | Requested the type of Java field `formatter`. | PASS: crossed into `GreetingFormatter.kt`. |
| Type definition | Kotlin | Requested the type of controller property `customerFacade`. | PASS: `CustomerFacade.kt`. |
| Declaration | Java | Requested declaration from Java override `greet` to `GreetingPort`. | PASS: `GreetingPort.java`. |
| Cross-language declaration | Java | Requested declaration from Java override `canGreet` to the Kotlin interface. | PASS: `CustomerPolicy.kt`. |
| Declaration | Kotlin | Checked server capabilities before requesting. | UNSUPPORTED: not advertised. |
| Hover | Java | Hovered the Kotlin `GreetingFormatter` type from Java. | PASS: Kotlin type/source information returned. |
| Hover | Kotlin | Hovered Java entity `Customer` from Kotlin. | PASS: entity annotations and class information returned. |
| Document symbols | Java | Requested nested symbols for `JavaGreetingService`. | PASS: 8 recursive symbols. |
| Document symbols | Kotlin | Requested nested symbols for `CustomerFacade`. | PASS: 9 recursive symbols. |
| Workspace symbols | Java | Queried `Customer`. | PASS: 9 symbols. |
| Workspace symbols | Kotlin | Queried `Customer`. | PASS: 12 symbols. |
| Completion | Java | Changed a buffer to `customer.` and requested triggered completion. | PASS: 16 items including `getDisplayName`. |
| Completion | Kotlin | Changed a buffer to `customer.` and requested triggered completion. | PASS: 24 items including `displayName`. |
| Same-language signature help | Java | Replaced a line in memory with `decorate(` and tested valid cursor/context combinations. | PASS: `decorate(String value, int repeat) : String`. |
| Cross-language signature help | Java | Typed `formatter.format(` where `formatter` is Kotlin. | PASS: `format(Customer customer) : String`. |
| Same-language signature help | Kotlin | Requested help inside `customerFacade.find(id)`. | PASS: `find(id: Long): CustomerView`. |
| Cross-language signature help | Kotlin | Requested help inside the Java `Customer(...)` constructor. | PASS: Java constructor signature returned. |
| Semantic diagnostics | Java | Changed a `String` return to `return 42` in memory and waited for published diagnostics. | PASS: Java type-mismatch error returned. |
| Semantic diagnostics | Kotlin | Changed a `String` expression to `42` and pulled diagnostics. | PASS: Kotlin return-type mismatch returned. |
| Missing-import quick fix | Java | Inserted an unresolved `ResponseEntity` use and requested code actions with diagnostics. | PASS: Spring `ResponseEntity` import action returned. |
| Missing-import quick fix | Kotlin | Removed the `ResponseEntity` import in memory, pulled diagnostics, and requested actions. | PASS: Spring `ResponseEntity` import action returned. |
| Organize imports | Java | Requested only `source.organizeImports`. | PASS: organize-imports action returned. |
| Organize imports | Kotlin | Requested only `source.organizeImports`. | PASS: organize-imports action returned. |
| Formatting | Java | Made a method line deliberately malformed in memory and requested full formatting. | PASS: 4 edits returned. |
| Formatting | Kotlin | Made a function line deliberately malformed in memory and requested full formatting. | PASS: 6 edits returned. |
| References across languages | Java | Requested references for Java `Customer`. | PASS: 21 results including Kotlin source files. |
| References across languages | Kotlin | Requested references for Kotlin `CustomerFacade`. | PASS: 7 results including `JavaProbe.java`. |
| Implementation | Java | Requested implementations of Java `GreetingPort`. | PASS: `JavaGreetingService.java`. |
| Cross-language implementation | Kotlin | Requested implementations of Kotlin `CustomerPolicy`. | PASS: Java `ActiveCustomerPolicy.java`. |
| Prepare rename | Java | Checked `renameProvider.prepareProvider`. | UNSUPPORTED: not advertised. Direct rename is supported. |
| Prepare rename | Kotlin | Checked `renameProvider.prepareProvider`. | UNSUPPORTED: not advertised. Direct rename is supported. |
| Rename within Java | Java | Previewed rename of `GreetingPort`. | PASS: declaration and `JavaGreetingService` edits returned. |
| Java rename including Kotlin callers | Java | Previewed the same rename and required `CustomerFacade.kt` edits. | FAIL: only 2 Java edits; Kotlin use omitted. |
| Kotlin rename including Java callers | Kotlin | Previewed rename of Kotlin `CustomerFacade`. | PASS: 7 edits across Kotlin and `JavaProbe.java`. |
| Rename Java symbol from Kotlin | Kotlin | Requested rename on the Kotlin use of Java `GreetingPort`. | PASS: 3 edits across Java declaration, Java implementation, and Kotlin use. |
| Document highlights | Java | Highlighted `formatter` uses in one document. | PASS: 3 ranges. |
| Document highlights | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
| Folding ranges | Java | Requested ranges for `JavaGreetingService`. | PASS: 7 ranges. |
| Folding ranges | Kotlin | Requested ranges for `CustomerController`. | PASS: 6 ranges. |
| Selection ranges | Java | Requested nested selections inside a method argument. | PASS: nested parent ranges returned. |
| Selection ranges | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
| Semantic tokens | Java | Requested full-document semantic tokens. | PASS: 75 tokens. |
| Semantic tokens | Kotlin | Requested full-document semantic tokens. | PASS: 74 tokens. |
| Call hierarchy | Java | Prepared `greet`, then requested incoming and outgoing calls. | PASS: 1 incoming and 3 outgoing. |
| Call hierarchy | Kotlin | Prepared `CustomerFacade.find`, then requested both directions. | PASS: 2 incoming and 2 outgoing. |
| Type hierarchy | Java | Prepared `GreetingPort`, then requested subtypes/supertypes. | PASS: `JavaGreetingService` subtype returned. |
| Same-language type hierarchy | Kotlin | Prepared Kotlin `CustomerNotFoundException`, which extends another type. | FAIL: provider advertised, but prepare returned `nil`. |
| Cross-language type hierarchy | Kotlin | Prepared Kotlin `CustomerPolicy`, implemented by Java. | FAIL: provider advertised, but prepare returned `nil`. |
| Inlay hints | Java | Checked capabilities. | UNSUPPORTED: not advertised in this client session. |
| Inlay hints | Kotlin | Enabled parameter hints, called `customerFacade.find(42)`, and requested hints. | PASS: 1 actual hint returned. |
| Code lens | Java | Requested code lenses for the service. | PASS: 5 lenses. |
| Code lens | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
| JDK class source | Java | Navigated `List` to a `jdt://` URI and opened it through `nvim-jdtls`. | PASS: 190 Java lines, nonmodifiable buffer. |
| Spring class source | Java | Navigated `@Service` into `spring-context`. | PASS: 57 Java lines, nonmodifiable buffer. |
| JDK decompilation | Kotlin | Navigated `UUID` to `jrt://` and executed Kotlin's `decompile` command. | PASS: 55 Java lines, readonly and nonmodifiable. |
| Spring source/decompilation | Kotlin | Navigated `ResponseEntity` to `jar://` and opened it through the Kotlin bridge. | PASS: 667 Java lines, readonly and nonmodifiable. |
| `nvim-jdtls` integration | Java | Inspected extended capabilities, server commands, and buffer-local commands. | PASS: 11 extended capabilities, 33 server commands, and `JdtCompile`, `JdtUpdateConfig`, `JdtRestart`. |
| Concurrent request burst | Java | Sent 25 asynchronous hover requests before waiting. | PASS: 25/25 completed with nonempty results. |
| Concurrent request burst | Kotlin | Sent 25 asynchronous hover requests before waiting. | PASS: 25/25 completed with nonempty results. |
| Rapid incremental changes | Java | Sent 20 alternating valid `didChange` updates, then requested hover. | PASS: semantic hover recovered. |
| Rapid incremental changes | Kotlin | Sent 20 alternating valid `didChange` updates, then requested hover. | PASS: semantic hover recovered. |
| Multi-buffer reuse | Java | Attached four Java buffers and counted clients. | PASS: all four used one JDTLS client. |
| Multi-buffer reuse | Kotlin | Attached six Kotlin buffers and counted clients. | PASS: all six used one Kotlin client. |

## Configuration changes discovered by testing

The stress loop found and fixed two missing settings in the repository Neovim
configuration:

1. `java.signatureHelp.enabled = true`
   - JDTLS advertises signature help but defaults this preference to `false`.
   - Before enabling it, every Java signature request returned an empty list.
2. `jetbrains.kotlin["hints.parameters"] = true`
   - Kotlin LSP requests this configuration through `workspace/configuration`.
   - Without it, the server accepted inlay requests but returned no hints.

Both settings are now present in `/workspace/.config/nvim/init.lua`, and their
features passed in the final run.

## Assessment

The setup is strong for normal Java/Kotlin Spring work: completion, hover,
diagnostics, fixes, formatting, symbols, definitions, declarations,
implementations, references, signature help, semantic tokens, call hierarchy,
archive navigation, and repeated editing all worked.

The important operational caveat is refactoring ownership. Cross-language
read/navigation is good in both directions, but a rename initiated from a Java
buffer is not Kotlin-safe. For a Java symbol referenced by Kotlin, initiate the
rename from a Kotlin usage so Kotlin LSP can produce the combined Java/Kotlin
workspace edit, or verify Java-initiated rename results before applying them.

Kotlin type hierarchy is currently unreliable despite being advertised.
Unsupported Kotlin declaration/highlight/selection/code-lens features reflect
the current Alpha server rather than the Neovim wiring.
