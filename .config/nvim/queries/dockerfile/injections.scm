; Inject Bash into Dockerfile
((shell_command) @injection.content
 (#set! injection.language "bash"))
