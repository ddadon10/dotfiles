; Inject Bash into YAML
((block_scalar) @injection.content
 (#set! injection.language "bash")
 (#match? @injection.content "^\\|"))
