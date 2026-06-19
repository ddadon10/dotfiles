; Inject Bash into HCL
((heredoc_template) @injection.content
 (#set! injection.language "bash"))
