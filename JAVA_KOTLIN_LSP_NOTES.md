# Java/Kotlin LSP notes

## Archive labels

Archive URIs remain unchanged internally and are shortened only when displayed:

| Surface | Display |
|---|---|
| LSP location picker | `Service.java spring-context-7.0.8.jar:42:5` |
| Tabline | `Service.java` |
| Statusline | `spring-context-7.0.8.jar › org.springframework.stereotype.Service` |

Both `jdt://contents/...` and `jar://...!/` are recognized. A source archive such as
`spring-context-7.0.8-sources.jar` is displayed as `spring-context-7.0.8.jar`, aligning Kotlin LSP and JDTLS results.
`jrt://` is left unchanged.

The real buffer name and the LSP result URI are never renamed. JDTLS and Kotlin LSP therefore continue receiving the
exact URI they returned.

### LSP picker implementation

The structured LSP-item filter builds a reversible two-field fzf row before fzf-lua serializes the location:

```text
visible archive label <unit separator> original LSP entry
```

Fzf displays and searches the first field. Its `_fmt._from` hook restores the second field before the existing
`path.filename_first` reverse formatter, previewer, navigation action, or quickfix action sees the entry. Ordinary
physical file results keep their existing formatting.

This shared behavior applies to the configured definition, peek, reference, implementation, and type-definition pickers.

## Filtering Kotlin-generated JDTLS locations

All configured LSP location pickers exclude an item only when its filename is a `jdt://` URI containing the literal
marker:

```text
/kotlin_generated=/true
```

Normal JDK and dependency locations are retained, including `spring-context-7.0.8.jar`, `jakarta.persistence-api`, and
`java.base`, because their URIs do not have that marker.

### Completeness warning

Kotlin-generated JDT locations are not necessarily duplicates. In the stress fixture, JDTLS returned one physical
`CustomerFacade.kt` URI and four distinct generated locations. Always filtering generated locations can therefore hide
real compiled Kotlin usages. This is an accepted tradeoff; there is no complete, unfiltered alternate mapping.
