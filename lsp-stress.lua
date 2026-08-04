local root = vim.env.LSP_STRESS_ROOT or '/tmp/nvim-java-kotlin-spring-lsp-stress'
local output = vim.env.LSP_STRESS_OUTPUT or (root .. '/lsp-stress-result.json')
local run_name = vim.env.LSP_STRESS_RUN or 'unspecified'
local uv = vim.uv
local suite_started = uv.hrtime()

local report = {
    fixture = root,
    run = run_name,
    started_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    tests = {},
}

local function elapsed_ms(started)
    return math.floor((uv.hrtime() - started) / 100000) / 10
end

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function count_table(value)
    local count = 0
    for _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function add_result(feature, language, method, status, started, details)
    local result = {
        feature = feature,
        language = language,
        method = method,
        status = status,
        elapsed_ms = elapsed_ms(started),
        details = details,
    }
    table.insert(report.tests, result)
    print(string.format(
        '[%s] %-7s %-42s %7.1f ms',
        status:upper(),
        language,
        feature,
        result.elapsed_ms
    ))
end

local function test(feature, language, method, callback)
    local started = uv.hrtime()
    local ok, details = xpcall(callback, debug.traceback)
    if ok then
        add_result(feature, language, method, 'pass', started, details)
    else
        add_result(feature, language, method, 'fail', started, { error = details })
    end
end

local function unsupported(feature, language, method, reason)
    add_result(feature, language, method, 'unsupported', uv.hrtime(), { reason = reason })
end

local function request(client, method, params, bufnr, timeout)
    local response = client:request_sync(method, params, timeout or 30000, bufnr)
    expect(response ~= nil, method .. ' timed out')
    expect(response.err == nil, method .. ' failed: ' .. vim.inspect(response.err))
    return response.result
end

local function open_buffer(relative_path)
    vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. relative_path))
    return vim.api.nvim_get_current_buf()
end

local function wait_for_client(name, bufnr, timeout)
    local client
    local attached = vim.wait(timeout or 300000, function()
        client = vim.lsp.get_clients({ name = name, bufnr = bufnr })[1]
        return client ~= nil and client.initialized
    end, 100)
    expect(attached, name .. ' did not initialize for buffer ' .. bufnr)
    return client
end

local function find_position(bufnr, line_fragment, symbol, occurrence)
    occurrence = occurrence or 1
    local seen = 0
    for index, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if line:find(line_fragment, 1, true) then
            local from = 1
            while true do
                local start_col = line:find(symbol, from, true)
                if not start_col then
                    break
                end
                seen = seen + 1
                if seen == occurrence then
                    return {
                        line = index - 1,
                        character = start_col - 1,
                    }
                end
                from = start_col + #symbol
            end
        end
    end
    error(string.format('Could not find %q in line containing %q', symbol, line_fragment))
end

local function text_document_position(bufnr, position)
    return {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = position,
    }
end

local function document_params(bufnr)
    return { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
end

local function normalize_locations(result)
    if type(result) ~= 'table' then
        return {}
    end
    if result.uri or result.targetUri then
        return { result }
    end
    return result
end

local function location_uris(result)
    local uris = {}
    for _, location in ipairs(normalize_locations(result)) do
        local uri = location.uri or location.targetUri
        if uri then
            table.insert(uris, uri)
        end
    end
    return uris
end

local function definition(client, bufnr, position)
    return request(
        client,
        'textDocument/definition',
        text_document_position(bufnr, position),
        bufnr,
        30000
    )
end

local function wait_for_definition(client, bufnr, position, expected, timeout)
    local started = uv.hrtime()
    local last_uris = {}
    local attempt = 0
    while elapsed_ms(started) < timeout do
        attempt = attempt + 1
        local ok, result = pcall(definition, client, bufnr, position)
        if ok then
            last_uris = location_uris(result)
            for _, uri in ipairs(last_uris) do
                if uri:find(expected, 1, true) then
                    return uri, elapsed_ms(started), attempt
                end
            end
        end
        if attempt % 3 == 0 then
            print(string.format(
                '[WAIT] %s cross-language import %.1fs; last=%s',
                client.name,
                elapsed_ms(started) / 1000,
                vim.inspect(last_uris)
            ))
        end
        vim.wait(1000)
    end
    error(string.format(
        '%s did not resolve %s after %.1fs; last=%s',
        client.name,
        expected,
        timeout / 1000,
        vim.inspect(last_uris)
    ))
end

local function hover_text(result)
    if type(result) ~= 'table' or result.contents == nil then
        return ''
    end
    return table.concat(vim.lsp.util.convert_input_to_markdown_lines(result.contents), '\n')
end

local function completion_labels(result)
    local labels = {}
    local items = type(result) == 'table' and (result.items or result) or {}
    for _, item in ipairs(items) do
        if item.label then
            table.insert(labels, item.label)
        end
    end
    return labels
end

local function probe_signature_help(client, bufnr, line_fragment, call_fragment)
    local target_line
    local line_number
    for index, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if line:find(line_fragment, 1, true) then
            target_line = line
            line_number = index - 1
            break
        end
    end
    expect(target_line ~= nil, 'Could not find signature line ' .. line_fragment)

    local call_start = target_line:find(call_fragment, 1, true)
    expect(call_start ~= nil, 'Could not find call ' .. call_fragment)
    local argument_start = call_start - 1 + #call_fragment
    local contexts = {
        { name = 'no-context' },
        {
            name = 'invoked',
            value = { triggerKind = 1, isRetrigger = false },
        },
        {
            name = 'trigger-character',
            value = {
                triggerKind = 2,
                triggerCharacter = '(',
                isRetrigger = false,
            },
        },
    }
    local attempts = {}
    for _, character in ipairs({ argument_start, argument_start + 1 }) do
        for _, context in ipairs(contexts) do
            local params = {
                textDocument = { uri = vim.uri_from_bufnr(bufnr) },
                position = { line = line_number, character = character },
            }
            if context.value then
                params.context = context.value
            end
            local result = request(client, 'textDocument/signatureHelp', params, bufnr)
            local count = result and result.signatures and #result.signatures or 0
            table.insert(attempts, {
                character = character,
                context = context.name,
                signature_count = count,
            })
            if count > 0 then
                return {
                    attempts = attempts,
                    label = result.signatures[1].label,
                    matched_character = character,
                    matched_context = context.name,
                }
            end
        end
    end
    error('No signature response: ' .. vim.inspect(attempts))
end

local function contains_fragment(values, fragment)
    for _, value in ipairs(values) do
        if value:find(fragment, 1, true) then
            return true
        end
    end
    return false
end

local function with_restored_buffer(bufnr, callback)
    local original = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local ok, result = xpcall(callback, debug.traceback)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, original)
    vim.bo[bufnr].modified = false
    vim.wait(500)
    if not ok then
        error(result, 2)
    end
    return result
end

local function replace_line(bufnr, fragment, replacement)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for index, line in ipairs(lines) do
        if line:find(fragment, 1, true) then
            vim.api.nvim_buf_set_lines(bufnr, index - 1, index, false, { replacement })
            return index - 1
        end
    end
    error('Could not replace line containing ' .. fragment)
end

local function insert_before_final_brace(bufnr, lines)
    local current = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    expect(current[#current] == '}', 'Expected final class brace')
    vim.api.nvim_buf_set_lines(bufnr, #current - 1, #current - 1, false, lines)
end

local function lsp_diagnostics(bufnr)
    local diagnostics = {}
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
        table.insert(diagnostics, {
            range = {
                start = {
                    line = diagnostic.lnum,
                    character = diagnostic.col,
                },
                ['end'] = {
                    line = diagnostic.end_lnum or diagnostic.lnum,
                    character = diagnostic.end_col or (diagnostic.col + 1),
                },
            },
            severity = diagnostic.severity,
            code = diagnostic.code,
            source = diagnostic.source,
            message = diagnostic.message,
        })
    end
    return diagnostics
end

local function wait_for_diagnostic(bufnr, fragment, timeout)
    local matching
    local found = vim.wait(timeout or 30000, function()
        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
            if not fragment or diagnostic.message:lower():find(fragment:lower(), 1, true) then
                matching = diagnostic
                return true
            end
        end
        return false
    end, 100)
    expect(found, string.format(
        'No diagnostic containing %s; current=%s',
        tostring(fragment),
        vim.inspect(vim.diagnostic.get(bufnr))
    ))
    return matching
end

local function pull_diagnostics(client, bufnr, timeout)
    local result = request(client, 'textDocument/diagnostic', {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    }, bufnr, timeout or 30000)
    return result and result.items or {}
end

local function wait_for_pull_diagnostics(client, bufnr, timeout)
    local started = uv.hrtime()
    local attempts = 0
    local last_error
    while elapsed_ms(started) < (timeout or 90000) do
        attempts = attempts + 1
        local ok, diagnostics = pcall(pull_diagnostics, client, bufnr, 10000)
        if ok then
            return diagnostics, {
                attempts = attempts,
                ready_ms = elapsed_ms(started),
            }
        end
        last_error = diagnostics
        vim.wait(250)
    end
    error('Pull diagnostics did not become ready: ' .. tostring(last_error))
end

local function wait_for_pulled_diagnostic(client, bufnr, fragment, timeout)
    local started = uv.hrtime()
    local diagnostics = {}
    while elapsed_ms(started) < (timeout or 30000) do
        diagnostics = pull_diagnostics(client, bufnr)
        for _, diagnostic in ipairs(diagnostics) do
            if not fragment or diagnostic.message:lower():find(fragment:lower(), 1, true) then
                return diagnostic, diagnostics
            end
        end
        vim.wait(250)
    end
    error(string.format(
        'No pulled diagnostic containing %s; current=%s',
        tostring(fragment),
        vim.inspect(diagnostics)
    ))
end

local function workspace_edit_summary(edit)
    local uris = {}
    local edit_count = 0
    if type(edit) ~= 'table' then
        return { edit_count = 0, uris = {} }
    end
    for uri, edits in pairs(edit.changes or {}) do
        uris[uri] = true
        edit_count = edit_count + #edits
    end
    for _, change in ipairs(edit.documentChanges or {}) do
        local uri = change.textDocument and change.textDocument.uri
            or change.oldUri
            or change.newUri
        if uri then
            uris[uri] = true
        end
        edit_count = edit_count + #(change.edits or {})
    end
    local sorted_uris = vim.tbl_keys(uris)
    table.sort(sorted_uris)
    return {
        edit_count = edit_count,
        uris = sorted_uris,
    }
end

local function action_titles(actions)
    local titles = {}
    for _, action in ipairs(actions or {}) do
        table.insert(titles, action.title or action.command or '<untitled>')
    end
    return titles
end

local function recursive_symbol_count(symbols)
    local count = 0
    for _, symbol in ipairs(symbols or {}) do
        count = count + 1 + recursive_symbol_count(symbol.children)
    end
    return count
end

local function capability_enabled(value)
    return value ~= nil and value ~= false
end

local function whole_document_range(bufnr)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    return {
        start = { line = 0, character = 0 },
        ['end'] = { line = line_count, character = 0 },
    }
end

local function test_archive_open(source_buf, uri, expected_text, open_uri)
    local original_window = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_buf(source_buf)
    if open_uri then
        open_uri()
        expect(
            vim.wait(10000, function() return vim.api.nvim_buf_get_name(0) == uri end, 20),
            'Archive URI did not open'
        )
    else
        vim.cmd.edit(vim.fn.fnameescape(uri))
    end
    local archive_buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(archive_buf, 0, -1, false)
    local contents = table.concat(lines, '\n')
    expect(#lines > 5, 'Archive buffer contains too few lines')
    expect(contents:find(expected_text, 1, true) ~= nil, 'Archive text lacks ' .. expected_text)
    expect(vim.bo[archive_buf].modifiable == false, 'Archive buffer is modifiable')
    vim.api.nvim_set_current_win(original_window)
    vim.api.nvim_set_current_buf(source_buf)
    return {
        filetype = vim.bo[archive_buf].filetype,
        line_count = #lines,
        modifiable = vim.bo[archive_buf].modifiable,
        readonly = vim.bo[archive_buf].readonly,
        uri = uri,
    }
end

print('[SETUP] Opening Kotlin and Java buffers to start both servers concurrently')
local kotlin_opened = uv.hrtime()
local kotlin_probe = open_buffer('src/main/kotlin/dev/stress/lsp/probe/KotlinProbe.kt')
local java_opened = uv.hrtime()
local java_service = open_buffer('src/main/java/dev/stress/lsp/customer/JavaGreetingService.java')

local kotlin = wait_for_client('kotlin_lsp', kotlin_probe)
local java = wait_for_client('jdtls', java_service)

local kotlin_cross_position = find_position(
    kotlin_probe,
    'fun customerName(customer: Customer)',
    'Customer'
)
local java_cross_position = find_position(
    java_service,
    'private final GreetingFormatter formatter',
    'GreetingFormatter'
)

print('[SETUP] Waiting for semantic project import in both servers')
local kotlin_ready_uri, kotlin_ready_ms, kotlin_ready_attempts = wait_for_definition(
    kotlin,
    kotlin_probe,
    kotlin_cross_position,
    '/Customer.java',
    480000
)
local java_ready_uri, java_ready_ms, java_ready_attempts = wait_for_definition(
    java,
    java_service,
    java_cross_position,
    '/GreetingFormatter.kt',
    480000
)

report.servers = {
    java = {
        id = java.id,
        name = java.name,
        command = java.config.cmd,
        root_dir = java.config.root_dir,
        ready_ms = elapsed_ms(java_opened),
        readiness_probe_ms = java_ready_ms,
        readiness_attempts = java_ready_attempts,
        readiness_uri = java_ready_uri,
        capabilities = {
            code_lens = capability_enabled(java.server_capabilities.codeLensProvider),
            document_highlight = capability_enabled(
                java.server_capabilities.documentHighlightProvider
            ),
            inlay_hint = capability_enabled(java.server_capabilities.inlayHintProvider),
            prepare_rename = type(java.server_capabilities.renameProvider) == 'table'
                and java.server_capabilities.renameProvider.prepareProvider == true,
            selection_range = capability_enabled(java.server_capabilities.selectionRangeProvider),
            signature_help = capability_enabled(java.server_capabilities.signatureHelpProvider),
            type_hierarchy = capability_enabled(java.server_capabilities.typeHierarchyProvider),
        },
        execute_commands = java.server_capabilities.executeCommandProvider
            and java.server_capabilities.executeCommandProvider.commands
            or {},
    },
    kotlin = {
        id = kotlin.id,
        name = kotlin.name,
        command = kotlin.config.cmd,
        root_dir = kotlin.config.root_dir,
        ready_ms = elapsed_ms(kotlin_opened),
        readiness_probe_ms = kotlin_ready_ms,
        readiness_attempts = kotlin_ready_attempts,
        readiness_uri = kotlin_ready_uri,
        capabilities = {
            code_lens = capability_enabled(kotlin.server_capabilities.codeLensProvider),
            document_highlight = capability_enabled(
                kotlin.server_capabilities.documentHighlightProvider
            ),
            inlay_hint = capability_enabled(kotlin.server_capabilities.inlayHintProvider),
            prepare_rename = type(kotlin.server_capabilities.renameProvider) == 'table'
                and kotlin.server_capabilities.renameProvider.prepareProvider == true,
            selection_range = capability_enabled(
                kotlin.server_capabilities.selectionRangeProvider
            ),
            signature_help = capability_enabled(kotlin.server_capabilities.signatureHelpProvider),
            type_hierarchy = capability_enabled(kotlin.server_capabilities.typeHierarchyProvider),
        },
        execute_commands = kotlin.server_capabilities.executeCommandProvider
            and kotlin.server_capabilities.executeCommandProvider.commands
            or {},
    },
}

local java_probe = open_buffer('src/main/java/dev/stress/lsp/probe/JavaProbe.java')
local java_policy = open_buffer('src/main/java/dev/stress/lsp/customer/ActiveCustomerPolicy.java')
local java_port = open_buffer('src/main/java/dev/stress/lsp/customer/GreetingPort.java')
local kotlin_controller = open_buffer(
    'src/main/kotlin/dev/stress/lsp/customer/CustomerController.kt'
)
local kotlin_facade = open_buffer('src/main/kotlin/dev/stress/lsp/customer/CustomerFacade.kt')
local kotlin_policy = open_buffer('src/main/kotlin/dev/stress/lsp/customer/CustomerPolicy.kt')
local kotlin_exception = open_buffer(
    'src/main/kotlin/dev/stress/lsp/customer/CustomerNotFoundException.kt'
)
local kotlin_formatter = open_buffer(
    'src/main/kotlin/dev/stress/lsp/customer/format/GreetingFormatter.kt'
)

for _, bufnr in ipairs({ java_probe, java_policy, java_port }) do
    wait_for_client('jdtls', bufnr, 60000)
end
for _, bufnr in ipairs({
    kotlin_controller,
    kotlin_facade,
    kotlin_policy,
    kotlin_exception,
    kotlin_formatter,
}) do
    wait_for_client('kotlin_lsp', bufnr, 60000)
end

test('server attachment and workspace root', 'java', 'initialize', function()
    expect(java.config.root_dir == root, 'Unexpected root: ' .. tostring(java.config.root_dir))
    expect(vim.lsp.buf_is_attached(java_service, java.id), 'Java service is not attached')
    return {
        client_id = java.id,
        root_dir = java.config.root_dir,
        command = java.config.cmd,
    }
end)

test('server attachment and workspace root', 'kotlin', 'initialize', function()
    expect(kotlin.config.root_dir == root, 'Unexpected root: ' .. tostring(kotlin.config.root_dir))
    expect(vim.lsp.buf_is_attached(kotlin_probe, kotlin.id), 'Kotlin probe is not attached')
    return {
        client_id = kotlin.id,
        root_dir = kotlin.config.root_dir,
        command = kotlin.config.cmd,
    }
end)

test('baseline project diagnostics are clean', 'java', 'textDocument/publishDiagnostics', function()
    local errors = vim.tbl_filter(function(diagnostic)
        return diagnostic.severity == vim.diagnostic.severity.ERROR
    end, vim.diagnostic.get(java_service))
    expect(#errors == 0, vim.inspect(errors))
    return { error_count = #errors }
end)

test('baseline project diagnostics are clean', 'kotlin', 'textDocument/diagnostic', function()
    local diagnostics, readiness = wait_for_pull_diagnostics(kotlin, kotlin_facade, 90000)
    local errors = vim.tbl_filter(function(diagnostic)
        return diagnostic.severity == vim.lsp.protocol.DiagnosticSeverity.Error
    end, diagnostics)
    expect(#errors == 0, vim.inspect(errors))
    return {
        attempts = readiness.attempts,
        diagnostic_ready_ms = readiness.ready_ms,
        error_count = #errors,
    }
end)

test('cross-language definition Java to Kotlin', 'java', 'textDocument/definition', function()
    local uris = location_uris(definition(java, java_service, java_cross_position))
    expect(contains_fragment(uris, '/GreetingFormatter.kt'), vim.inspect(uris))
    return { uris = uris }
end)

test('cross-language definition Kotlin to Java', 'kotlin', 'textDocument/definition', function()
    local uris = location_uris(definition(kotlin, kotlin_probe, kotlin_cross_position))
    expect(contains_fragment(uris, '/Customer.java'), vim.inspect(uris))
    return { uris = uris }
end)

test('same-language definition', 'java', 'textDocument/definition', function()
    local position = find_position(java_policy, 'CustomerStatus.ACTIVE', 'CustomerStatus')
    local uris = location_uris(definition(java, java_policy, position))
    expect(contains_fragment(uris, '/CustomerStatus.java'), vim.inspect(uris))
    return { uris = uris }
end)

test('same-language definition', 'kotlin', 'textDocument/definition', function()
    local position = find_position(
        kotlin_controller,
        'private val customerFacade: CustomerFacade',
        'CustomerFacade'
    )
    local uris = location_uris(definition(kotlin, kotlin_controller, position))
    expect(contains_fragment(uris, '/CustomerFacade.kt'), vim.inspect(uris))
    return { uris = uris }
end)

if capability_enabled(java.server_capabilities.typeDefinitionProvider) then
    test('cross-language type definition', 'java', 'textDocument/typeDefinition', function()
        local position = find_position(
            java_service,
            'private final GreetingFormatter formatter',
            'formatter'
        )
        local result = request(
            java,
            'textDocument/typeDefinition',
            text_document_position(java_service, position),
            java_service
        )
        local uris = location_uris(result)
        expect(contains_fragment(uris, '/GreetingFormatter.kt'), vim.inspect(uris))
        return { uris = uris }
    end)
else
    unsupported('cross-language type definition', 'java', 'textDocument/typeDefinition', 'not advertised')
end

if capability_enabled(kotlin.server_capabilities.typeDefinitionProvider) then
    test('type definition', 'kotlin', 'textDocument/typeDefinition', function()
        local position = find_position(
            kotlin_controller,
            'private val customerFacade: CustomerFacade',
            'customerFacade'
        )
        local result = request(
            kotlin,
            'textDocument/typeDefinition',
            text_document_position(kotlin_controller, position),
            kotlin_controller
        )
        local uris = location_uris(result)
        expect(contains_fragment(uris, '/CustomerFacade.kt'), vim.inspect(uris))
        return { uris = uris }
    end)
else
    unsupported('type definition', 'kotlin', 'textDocument/typeDefinition', 'not advertised')
end

if capability_enabled(java.server_capabilities.declarationProvider) then
    test('same-language declaration', 'java', 'textDocument/declaration', function()
        local position = find_position(
            java_service,
            'public String greet(Customer customer)',
            'greet'
        )
        local result = request(
            java,
            'textDocument/declaration',
            text_document_position(java_service, position),
            java_service
        )
        local uris = location_uris(result)
        expect(contains_fragment(uris, '/GreetingPort.java'), vim.inspect(uris))
        return { uris = uris }
    end)

    test('cross-language declaration', 'java', 'textDocument/declaration', function()
        local position = find_position(
            java_policy,
            'public boolean canGreet(Customer customer)',
            'canGreet'
        )
        local result = request(
            java,
            'textDocument/declaration',
            text_document_position(java_policy, position),
            java_policy
        )
        local uris = location_uris(result)
        expect(contains_fragment(uris, '/CustomerPolicy.kt'), vim.inspect(uris))
        return { uris = uris }
    end)
else
    unsupported('cross-language declaration', 'java', 'textDocument/declaration', 'not advertised')
end

if capability_enabled(kotlin.server_capabilities.declarationProvider) then
    test('declaration', 'kotlin', 'textDocument/declaration', function()
        local position = find_position(
            kotlin_probe,
            'customerFacade.find(id)',
            'find'
        )
        local result = request(
            kotlin,
            'textDocument/declaration',
            text_document_position(kotlin_probe, position),
            kotlin_probe
        )
        local uris = location_uris(result)
        expect(contains_fragment(uris, '/CustomerFacade.kt'), vim.inspect(uris))
        return { uris = uris }
    end)
else
    unsupported('declaration', 'kotlin', 'textDocument/declaration', 'not advertised')
end

test('hover', 'java', 'textDocument/hover', function()
    local result = request(
        java,
        'textDocument/hover',
        text_document_position(java_service, java_cross_position),
        java_service
    )
    local text = hover_text(result)
    expect(text:find('GreetingFormatter', 1, true) ~= nil, text)
    return { preview = text:sub(1, 500) }
end)

test('hover', 'kotlin', 'textDocument/hover', function()
    local result = request(
        kotlin,
        'textDocument/hover',
        text_document_position(kotlin_probe, kotlin_cross_position),
        kotlin_probe
    )
    local text = hover_text(result)
    expect(text:find('Customer', 1, true) ~= nil, text)
    return { preview = text:sub(1, 500) }
end)

test('document symbols', 'java', 'textDocument/documentSymbol', function()
    local result = request(java, 'textDocument/documentSymbol', document_params(java_service), java_service)
    local count = recursive_symbol_count(result)
    expect(count >= 7, vim.inspect(result))
    return { top_level_count = #result, recursive_count = count }
end)

test('document symbols', 'kotlin', 'textDocument/documentSymbol', function()
    local result = request(
        kotlin,
        'textDocument/documentSymbol',
        document_params(kotlin_facade),
        kotlin_facade
    )
    local count = recursive_symbol_count(result)
    expect(count >= 8, vim.inspect(result))
    return { top_level_count = #result, recursive_count = count }
end)

test('workspace symbols', 'java', 'workspace/symbol', function()
    local result = request(java, 'workspace/symbol', { query = 'Customer' }, java_service)
    expect(type(result) == 'table' and #result >= 5, vim.inspect(result))
    return { symbol_count = #result }
end)

test('workspace symbols', 'kotlin', 'workspace/symbol', function()
    local result = request(kotlin, 'workspace/symbol', { query = 'Customer' }, kotlin_probe)
    expect(type(result) == 'table' and #result >= 5, vim.inspect(result))
    return { symbol_count = #result }
end)

test('member completion after incremental edit', 'java', 'textDocument/completion', function()
    return with_restored_buffer(java_probe, function()
        local line = replace_line(
            java_probe,
            'return customer.getDisplayName();',
            '        return customer.;'
        )
        vim.wait(300)
        local result = request(java, 'textDocument/completion', {
            textDocument = { uri = vim.uri_from_bufnr(java_probe) },
            position = { line = line, character = 24 },
            context = { triggerKind = 2, triggerCharacter = '.' },
        }, java_probe)
        local labels = completion_labels(result)
        expect(contains_fragment(labels, 'getDisplayName'), vim.inspect(labels))
        return { item_count = #labels, matched = 'getDisplayName' }
    end)
end)

test('member completion after incremental edit', 'kotlin', 'textDocument/completion', function()
    return with_restored_buffer(kotlin_probe, function()
        local line = replace_line(
            kotlin_probe,
            'fun customerName(customer: Customer): String = customer.displayName',
            '    fun customerName(customer: Customer): String = customer.'
        )
        vim.wait(300)
        local result = request(kotlin, 'textDocument/completion', {
            textDocument = { uri = vim.uri_from_bufnr(kotlin_probe) },
            position = { line = line, character = 65 },
            context = { triggerKind = 2, triggerCharacter = '.' },
        }, kotlin_probe)
        local labels = completion_labels(result)
        expect(contains_fragment(labels, 'displayName'), vim.inspect(labels))
        return { item_count = #labels, matched = 'displayName' }
    end)
end)

test('same-language signature help', 'java', 'textDocument/signatureHelp', function()
    return with_restored_buffer(java_service, function()
        replace_line(
            java_service,
            'return decorate(formatter.format(customer), 1);',
            '        return decorate('
        )
        vim.wait(500)
        return probe_signature_help(java, java_service, 'return decorate(', 'decorate(')
    end)
end)

test('cross-language signature help', 'java', 'textDocument/signatureHelp', function()
    return with_restored_buffer(java_service, function()
        replace_line(
            java_service,
            'return decorate(formatter.format(customer), 1);',
            '        return formatter.format('
        )
        vim.wait(500)
        return probe_signature_help(java, java_service, 'return formatter.format(', 'format(')
    end)
end)

test('same-language signature help', 'kotlin', 'textDocument/signatureHelp', function()
    local position = find_position(
        kotlin_probe,
        'fun loadCustomer(id: Long): CustomerView = customerFacade.find(id)',
        'id',
        2
    )
    local result = request(kotlin, 'textDocument/signatureHelp', {
        textDocument = { uri = vim.uri_from_bufnr(kotlin_probe) },
        position = position,
        context = { triggerKind = 1, isRetrigger = false },
    }, kotlin_probe)
    expect(result and result.signatures and #result.signatures > 0, vim.inspect(result))
    return { label = result.signatures[1].label }
end)

test('cross-language signature help', 'kotlin', 'textDocument/signatureHelp', function()
    local position = find_position(
        kotlin_facade,
        '.save(Customer(request.displayName, CustomerStatus.ACTIVE))',
        'request'
    )
    local result = request(kotlin, 'textDocument/signatureHelp', {
        textDocument = { uri = vim.uri_from_bufnr(kotlin_facade) },
        position = position,
        context = { triggerKind = 1, isRetrigger = false },
    }, kotlin_facade)
    expect(result and result.signatures and #result.signatures > 0, vim.inspect(result))
    return { label = result.signatures[1].label }
end)

test('semantic diagnostics after incremental edit', 'java', 'textDocument/publishDiagnostics', function()
    return with_restored_buffer(java_probe, function()
        replace_line(java_probe, 'return customer.getDisplayName();', '        return 42;')
        local diagnostic = wait_for_diagnostic(java_probe, 'mismatch', 30000)
        return {
            message = diagnostic.message,
            severity = diagnostic.severity,
            source = diagnostic.source,
        }
    end)
end)

test('semantic diagnostics after incremental edit', 'kotlin', 'textDocument/diagnostic', function()
    return with_restored_buffer(kotlin_probe, function()
        replace_line(
            kotlin_probe,
            'fun customerName(customer: Customer): String = customer.displayName',
            '    fun customerName(customer: Customer): String = 42'
        )
        local diagnostic = wait_for_pulled_diagnostic(
            kotlin,
            kotlin_probe,
            'Return type mismatch',
            30000
        )
        return {
            message = diagnostic.message,
            severity = diagnostic.severity,
            source = diagnostic.source,
        }
    end)
end)

test('quick-fix import code action', 'java', 'textDocument/codeAction', function()
    return with_restored_buffer(java_probe, function()
        insert_before_final_brace(java_probe, {
            '',
            '    public ResponseEntity<Customer> response(Customer customer) {',
            '        return ResponseEntity.ok(customer);',
            '    }',
        })
        local diagnostic = wait_for_diagnostic(java_probe, 'ResponseEntity', 30000)
        local actions = request(java, 'textDocument/codeAction', {
            textDocument = { uri = vim.uri_from_bufnr(java_probe) },
            range = {
                start = { line = diagnostic.lnum, character = diagnostic.col },
                ['end'] = {
                    line = diagnostic.end_lnum or diagnostic.lnum,
                    character = diagnostic.end_col or (diagnostic.col + 1),
                },
            },
            context = { diagnostics = lsp_diagnostics(java_probe) },
        }, java_probe)
        local titles = action_titles(actions)
        expect(contains_fragment(titles, 'Import'), vim.inspect(titles))
        return { titles = titles }
    end)
end)

test('quick-fix import code action', 'kotlin', 'textDocument/codeAction', function()
    return with_restored_buffer(kotlin_controller, function()
        replace_line(kotlin_controller, 'import org.springframework.http.ResponseEntity', '')
        local diagnostic, diagnostics = wait_for_pulled_diagnostic(
            kotlin,
            kotlin_controller,
            'ResponseEntity',
            30000
        )
        local actions = request(kotlin, 'textDocument/codeAction', {
            textDocument = { uri = vim.uri_from_bufnr(kotlin_controller) },
            range = diagnostic.range,
            context = { diagnostics = diagnostics },
        }, kotlin_controller)
        local titles = action_titles(actions)
        expect(contains_fragment(titles, 'Import'), vim.inspect(titles))
        return { titles = titles }
    end)
end)

test('source organize imports action', 'java', 'textDocument/codeAction', function()
    local actions = request(java, 'textDocument/codeAction', {
        textDocument = { uri = vim.uri_from_bufnr(java_service) },
        range = whole_document_range(java_service),
        context = {
            diagnostics = lsp_diagnostics(java_service),
            only = { 'source.organizeImports' },
        },
    }, java_service)
    local titles = action_titles(actions)
    expect(#titles > 0, vim.inspect(actions))
    return { titles = titles }
end)

test('source organize imports action', 'kotlin', 'textDocument/codeAction', function()
    local actions = request(kotlin, 'textDocument/codeAction', {
        textDocument = { uri = vim.uri_from_bufnr(kotlin_controller) },
        range = whole_document_range(kotlin_controller),
        context = {
            diagnostics = lsp_diagnostics(kotlin_controller),
            only = { 'source.organizeImports' },
        },
    }, kotlin_controller)
    local titles = action_titles(actions)
    expect(#titles > 0, vim.inspect(actions))
    return { titles = titles }
end)

test('document formatting', 'java', 'textDocument/formatting', function()
    return with_restored_buffer(java_probe, function()
        replace_line(
            java_probe,
            'return customer.getDisplayName();',
            '       return      customer.getDisplayName( ) ;'
        )
        vim.wait(300)
        local edits = request(java, 'textDocument/formatting', {
            textDocument = { uri = vim.uri_from_bufnr(java_probe) },
            options = { tabSize = 4, insertSpaces = true },
        }, java_probe)
        expect(type(edits) == 'table' and #edits > 0, vim.inspect(edits))
        return { edit_count = #edits }
    end)
end)

test('document formatting', 'kotlin', 'textDocument/formatting', function()
    if not kotlin.server_capabilities.documentFormattingProvider then
        error('Kotlin server did not advertise document formatting')
    end
    return with_restored_buffer(kotlin_probe, function()
        replace_line(
            kotlin_probe,
            'fun customerName(customer: Customer): String = customer.displayName',
            ' fun customerName( customer:Customer):String=customer.displayName'
        )
        vim.wait(300)
        local edits = request(kotlin, 'textDocument/formatting', {
            textDocument = { uri = vim.uri_from_bufnr(kotlin_probe) },
            options = { tabSize = 4, insertSpaces = true },
        }, kotlin_probe)
        expect(type(edits) == 'table' and #edits > 0, vim.inspect(edits))
        return { edit_count = #edits }
    end)
end)

test('find references including Kotlin callers', 'java', 'textDocument/references', function()
    local customer_position = find_position(
        java_service,
        'public String greet(Customer customer)',
        'Customer'
    )
    local result = request(java, 'textDocument/references', {
        textDocument = { uri = vim.uri_from_bufnr(java_service) },
        position = customer_position,
        context = { includeDeclaration = true },
    }, java_service)
    local uris = location_uris(result)
    expect(#uris >= 8, vim.inspect(uris))
    return {
        reference_count = #uris,
        includes_kotlin = contains_fragment(uris, '.kt'),
        uris = uris,
    }
end)

test('find references including Java callers', 'kotlin', 'textDocument/references', function()
    local position = find_position(
        kotlin_facade,
        'class CustomerFacade(',
        'CustomerFacade'
    )
    local result = request(kotlin, 'textDocument/references', {
        textDocument = { uri = vim.uri_from_bufnr(kotlin_facade) },
        position = position,
        context = { includeDeclaration = true },
    }, kotlin_facade)
    local uris = location_uris(result)
    expect(#uris >= 3, vim.inspect(uris))
    return {
        reference_count = #uris,
        includes_java = contains_fragment(uris, '.java'),
        uris = uris,
    }
end)

test('go to implementation', 'java', 'textDocument/implementation', function()
    local position = find_position(java_port, 'public interface GreetingPort', 'GreetingPort')
    local result = request(
        java,
        'textDocument/implementation',
        text_document_position(java_port, position),
        java_port
    )
    local uris = location_uris(result)
    expect(contains_fragment(uris, '/JavaGreetingService.java'), vim.inspect(uris))
    return { uris = uris }
end)

test('cross-language go to implementation', 'kotlin', 'textDocument/implementation', function()
    local position = find_position(kotlin_policy, 'interface CustomerPolicy', 'CustomerPolicy')
    local result = request(
        kotlin,
        'textDocument/implementation',
        text_document_position(kotlin_policy, position),
        kotlin_policy
    )
    local uris = location_uris(result)
    expect(contains_fragment(uris, '/ActiveCustomerPolicy.java'), vim.inspect(uris))
    return { uris = uris }
end)

if report.servers.java.capabilities.prepare_rename then
    test('prepare rename', 'java', 'textDocument/prepareRename', function()
        local position = find_position(java_port, 'public interface GreetingPort', 'GreetingPort')
        local result = request(
            java,
            'textDocument/prepareRename',
            text_document_position(java_port, position),
            java_port
        )
        expect(type(result) == 'table', vim.inspect(result))
        return result
    end)
else
    unsupported('prepare rename', 'java', 'textDocument/prepareRename', 'not advertised')
end

if report.servers.kotlin.capabilities.prepare_rename then
    test('prepare rename', 'kotlin', 'textDocument/prepareRename', function()
        local position = find_position(kotlin_facade, 'class CustomerFacade(', 'CustomerFacade')
        local result = request(
            kotlin,
            'textDocument/prepareRename',
            text_document_position(kotlin_facade, position),
            kotlin_facade
        )
        expect(type(result) == 'table', vim.inspect(result))
        return result
    end)
else
    unsupported('prepare rename', 'kotlin', 'textDocument/prepareRename', 'not advertised')
end

local function java_rename_summary()
    local position = find_position(java_port, 'public interface GreetingPort', 'GreetingPort')
    local edit = request(java, 'textDocument/rename', vim.tbl_extend(
        'force',
        text_document_position(java_port, position),
        { newName = 'RenamedGreetingPort' }
    ), java_port, 60000)
    return workspace_edit_summary(edit)
end

test('rename preview within Java', 'java', 'textDocument/rename', function()
    local summary = java_rename_summary()
    expect(summary.edit_count >= 2, vim.inspect(summary))
    expect(contains_fragment(summary.uris, '/GreetingPort.java'), vim.inspect(summary))
    expect(contains_fragment(summary.uris, '/JavaGreetingService.java'), vim.inspect(summary))
    return summary
end)

test('rename preview includes Kotlin callers', 'java', 'textDocument/rename', function()
    local summary = java_rename_summary()
    summary.includes_kotlin = contains_fragment(summary.uris, '.kt')
    expect(summary.includes_kotlin, vim.inspect(summary))
    return summary
end)

test('rename preview and cross-language edits', 'kotlin', 'textDocument/rename', function()
    local position = find_position(kotlin_facade, 'class CustomerFacade(', 'CustomerFacade')
    local edit = request(kotlin, 'textDocument/rename', vim.tbl_extend(
        'force',
        text_document_position(kotlin_facade, position),
        { newName = 'RenamedCustomerFacade' }
    ), kotlin_facade, 60000)
    local summary = workspace_edit_summary(edit)
    expect(summary.edit_count >= 5, vim.inspect(summary))
    summary.includes_java = contains_fragment(summary.uris, '.java')
    expect(summary.includes_java, vim.inspect(summary))
    return summary
end)

test('rename Java symbol from Kotlin usage', 'kotlin', 'textDocument/rename', function()
    local position = find_position(
        kotlin_facade,
        'private val greetingPort: GreetingPort',
        'GreetingPort'
    )
    local edit = request(kotlin, 'textDocument/rename', vim.tbl_extend(
        'force',
        text_document_position(kotlin_facade, position),
        { newName = 'RenamedGreetingPort' }
    ), kotlin_facade, 60000)
    local summary = workspace_edit_summary(edit)
    summary.includes_java = contains_fragment(summary.uris, '.java')
    summary.includes_kotlin = contains_fragment(summary.uris, '.kt')
    expect(summary.edit_count >= 3, vim.inspect(summary))
    expect(summary.includes_java and summary.includes_kotlin, vim.inspect(summary))
    return summary
end)

test('document highlights', 'java', 'textDocument/documentHighlight', function()
    local position = find_position(
        java_service,
        'private final GreetingFormatter formatter',
        'formatter'
    )
    local result = request(
        java,
        'textDocument/documentHighlight',
        text_document_position(java_service, position),
        java_service
    )
    expect(type(result) == 'table' and #result >= 3, vim.inspect(result))
    return { highlight_count = #result }
end)

if report.servers.kotlin.capabilities.document_highlight then
    test('document highlights', 'kotlin', 'textDocument/documentHighlight', function()
        local position = find_position(
            kotlin_facade,
            'private val customerRepository: CustomerRepository',
            'customerRepository'
        )
        local result = request(
            kotlin,
            'textDocument/documentHighlight',
            text_document_position(kotlin_facade, position),
            kotlin_facade
        )
        expect(type(result) == 'table' and #result >= 4, vim.inspect(result))
        return { highlight_count = #result }
    end)
else
    unsupported('document highlights', 'kotlin', 'textDocument/documentHighlight', 'not advertised')
end

test('folding ranges', 'java', 'textDocument/foldingRange', function()
    local result = request(java, 'textDocument/foldingRange', document_params(java_service), java_service)
    expect(type(result) == 'table' and #result >= 3, vim.inspect(result))
    return { range_count = #result }
end)

test('folding ranges', 'kotlin', 'textDocument/foldingRange', function()
    local result = request(
        kotlin,
        'textDocument/foldingRange',
        document_params(kotlin_controller),
        kotlin_controller
    )
    expect(type(result) == 'table' and #result >= 3, vim.inspect(result))
    return { range_count = #result }
end)

test('selection ranges', 'java', 'textDocument/selectionRange', function()
    local position = find_position(
        java_service,
        'return decorate(formatter.format(customer), 1)',
        'customer'
    )
    local result = request(java, 'textDocument/selectionRange', {
        textDocument = { uri = vim.uri_from_bufnr(java_service) },
        positions = { position },
    }, java_service)
    expect(type(result) == 'table' and result[1] and result[1].parent, vim.inspect(result))
    return { nested = true }
end)

if report.servers.kotlin.capabilities.selection_range then
    test('selection ranges', 'kotlin', 'textDocument/selectionRange', function()
        local position = find_position(
            kotlin_facade,
            '.save(Customer(request.displayName, CustomerStatus.ACTIVE))',
            'displayName'
        )
        local result = request(kotlin, 'textDocument/selectionRange', {
            textDocument = { uri = vim.uri_from_bufnr(kotlin_facade) },
            positions = { position },
        }, kotlin_facade)
        expect(type(result) == 'table' and result[1] and result[1].parent, vim.inspect(result))
        return { nested = true }
    end)
else
    unsupported('selection ranges', 'kotlin', 'textDocument/selectionRange', 'not advertised')
end

test('semantic tokens full document', 'java', 'textDocument/semanticTokens/full', function()
    local result = request(
        java,
        'textDocument/semanticTokens/full',
        document_params(java_service),
        java_service
    )
    expect(result and result.data and #result.data > 20, vim.inspect(result))
    return { integer_count = #result.data, token_count = #result.data / 5 }
end)

test('semantic tokens full document', 'kotlin', 'textDocument/semanticTokens/full', function()
    local result = request(
        kotlin,
        'textDocument/semanticTokens/full',
        document_params(kotlin_facade),
        kotlin_facade
    )
    expect(result and result.data and #result.data > 20, vim.inspect(result))
    return { integer_count = #result.data, token_count = #result.data / 5 }
end)

local function call_hierarchy_test(client, bufnr, position)
    local items = request(
        client,
        'textDocument/prepareCallHierarchy',
        text_document_position(bufnr, position),
        bufnr
    )
    expect(type(items) == 'table' and items[1], vim.inspect(items))
    local incoming = request(client, 'callHierarchy/incomingCalls', { item = items[1] }, bufnr)
    local outgoing = request(client, 'callHierarchy/outgoingCalls', { item = items[1] }, bufnr)
    return {
        item = items[1].name,
        incoming_count = #(incoming or {}),
        outgoing_count = #(outgoing or {}),
    }
end

if java.server_capabilities.callHierarchyProvider then
    test('call hierarchy incoming and outgoing', 'java', 'callHierarchy/*', function()
        local position = find_position(
            java_service,
            'public String greet(Customer customer)',
            'greet'
        )
        local details = call_hierarchy_test(java, java_service, position)
        expect(details.incoming_count >= 1, vim.inspect(details))
        expect(details.outgoing_count >= 2, vim.inspect(details))
        return details
    end)
else
    unsupported('call hierarchy incoming and outgoing', 'java', 'callHierarchy/*', 'not advertised')
end

if kotlin.server_capabilities.callHierarchyProvider then
    test('call hierarchy incoming and outgoing', 'kotlin', 'callHierarchy/*', function()
        local position = find_position(kotlin_facade, 'fun find(id: Long)', 'find')
        local details = call_hierarchy_test(kotlin, kotlin_facade, position)
        expect(details.incoming_count >= 2, vim.inspect(details))
        expect(details.outgoing_count >= 1, vim.inspect(details))
        return details
    end)
else
    unsupported('call hierarchy incoming and outgoing', 'kotlin', 'callHierarchy/*', 'not advertised')
end

local function type_hierarchy_test(client, bufnr, position)
    local items = request(
        client,
        'textDocument/prepareTypeHierarchy',
        text_document_position(bufnr, position),
        bufnr
    )
    expect(type(items) == 'table' and items[1], vim.inspect(items))
    local supertypes = request(client, 'typeHierarchy/supertypes', { item = items[1] }, bufnr)
    local subtypes = request(client, 'typeHierarchy/subtypes', { item = items[1] }, bufnr)
    return {
        item = items[1].name,
        subtype_names = vim.tbl_map(function(item)
            return item.name
        end, subtypes or {}),
        supertype_names = vim.tbl_map(function(item)
            return item.name
        end, supertypes or {}),
    }
end

if java.server_capabilities.typeHierarchyProvider then
    test('type hierarchy', 'java', 'typeHierarchy/*', function()
        local position = find_position(java_port, 'public interface GreetingPort', 'GreetingPort')
        local details = type_hierarchy_test(java, java_port, position)
        expect(contains_fragment(details.subtype_names, 'JavaGreetingService'), vim.inspect(details))
        return details
    end)
else
    unsupported('type hierarchy', 'java', 'typeHierarchy/*', 'not advertised')
end

if kotlin.server_capabilities.typeHierarchyProvider then
    test('same-language type hierarchy', 'kotlin', 'typeHierarchy/*', function()
        local position = find_position(
            kotlin_exception,
            'class CustomerNotFoundException',
            'CustomerNotFoundException'
        )
        position.character = position.character + 1
        local details = type_hierarchy_test(kotlin, kotlin_exception, position)
        expect(
            contains_fragment(details.supertype_names, 'NoSuchElementException'),
            vim.inspect(details)
        )
        return details
    end)

    test('cross-language type hierarchy', 'kotlin', 'typeHierarchy/*', function()
        local position = find_position(kotlin_policy, 'interface CustomerPolicy', 'CustomerPolicy')
        position.character = position.character + 1
        local details = type_hierarchy_test(kotlin, kotlin_policy, position)
        expect(contains_fragment(details.subtype_names, 'ActiveCustomerPolicy'), vim.inspect(details))
        return details
    end)
else
    unsupported('cross-language type hierarchy', 'kotlin', 'typeHierarchy/*', 'not advertised')
end

local function test_inlay_hints(client, language, bufnr)
    if not client.server_capabilities.inlayHintProvider then
        unsupported('inlay hints', language, 'textDocument/inlayHint', 'not advertised')
        return
    end
    test('inlay hints', language, 'textDocument/inlayHint', function()
        local result = request(client, 'textDocument/inlayHint', {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            range = whole_document_range(bufnr),
        }, bufnr)
        local hint_count = #(result or {})
        expect(hint_count > 0, 'The server returned no inlay hints')
        return { hint_count = hint_count }
    end)
end

test_inlay_hints(java, 'java', java_service)
test_inlay_hints(kotlin, 'kotlin', kotlin_probe)

local function test_code_lens(client, language, bufnr)
    if not client.server_capabilities.codeLensProvider then
        unsupported('code lens', language, 'textDocument/codeLens', 'not advertised')
        return
    end
    test('code lens', language, 'textDocument/codeLens', function()
        local result = request(client, 'textDocument/codeLens', document_params(bufnr), bufnr)
        expect(type(result) == 'table', vim.inspect(result))
        return { lens_count = #result }
    end)
end

test_code_lens(java, 'java', java_service)
test_code_lens(kotlin, 'kotlin', kotlin_facade)

test('JDK definition and read-only class source', 'java', 'textDocument/definition + BufReadCmd', function()
    local position = find_position(java_service, 'public List<String> greetAll', 'List')
    local uris = location_uris(definition(java, java_service, position))
    expect(uris[1] ~= nil, vim.inspect(uris))
    expect(uris[1]:match('^jdt://') ~= nil, vim.inspect(uris))
    return test_archive_open(java_service, uris[1], 'interface List')
end)

test('external Spring definition and class source', 'java', 'textDocument/definition + BufReadCmd', function()
    local position = find_position(java_service, '@Service', 'Service')
    local uris = location_uris(definition(java, java_service, position))
    expect(uris[1] ~= nil, vim.inspect(uris))
    expect(uris[1]:match('^jdt://') ~= nil, vim.inspect(uris))
    return test_archive_open(java_service, uris[1], 'interface Service')
end)

test('JDK definition and Kotlin decompilation', 'kotlin', 'textDocument/definition + decompile', function()
    local position = find_position(kotlin_probe, 'fun randomId(): UUID', 'UUID')
    local uris = location_uris(definition(kotlin, kotlin_probe, position))
    expect(uris[1] ~= nil, vim.inspect(uris))
    expect(uris[1]:match('^jrt://') ~= nil, vim.inspect(uris))
    return test_archive_open(kotlin_probe, uris[1], 'class UUID', function()
        vim.api.nvim_win_set_cursor(0, { position.line + 1, position.character })
        require('fzf-lua').lsp_definitions()
    end)
end)

test('external Spring definition and Kotlin decompilation', 'kotlin', 'textDocument/definition + decompile', function()
    local position = find_position(
        kotlin_controller,
        'fun find(@PathVariable id: Long): ResponseEntity<CustomerView>',
        'ResponseEntity'
    )
    local uris = location_uris(definition(kotlin, kotlin_controller, position))
    expect(uris[1] ~= nil, vim.inspect(uris))
    expect(uris[1]:match('^jar://') ~= nil, vim.inspect(uris))
    return test_archive_open(kotlin_controller, uris[1], 'class ResponseEntity', function()
        vim.api.nvim_win_set_cursor(0, { position.line + 1, position.character })
        require('fzf-lua').lsp_definitions()
    end)
end)

test('nvim-jdtls extended capabilities and commands', 'java', 'client integration', function()
    local extended = java.config.init_options
        and java.config.init_options.extendedClientCapabilities
        or {}
    expect(count_table(extended) >= 5, vim.inspect(extended))
    local commands = vim.api.nvim_buf_get_commands(java_service, {})
    expect(commands.JdtCompile ~= nil, ':JdtCompile is unavailable')
    expect(commands.JdtUpdateConfig ~= nil, ':JdtUpdateConfig is unavailable')
    expect(commands.JdtRestart ~= nil, ':JdtRestart is unavailable')
    return {
        command_count = #(report.servers.java.execute_commands or {}),
        extended_capability_count = count_table(extended),
        neovim_commands = {
            JdtCompile = commands.JdtCompile ~= nil,
            JdtRestart = commands.JdtRestart ~= nil,
            JdtUpdateConfig = commands.JdtUpdateConfig ~= nil,
        },
    }
end)

local function async_hover_burst(client, bufnr, position, count)
    local completed = 0
    local errors = {}
    local nonempty = 0
    for _ = 1, count do
        local sent = client:request(
            'textDocument/hover',
            text_document_position(bufnr, position),
            function(err, result)
                completed = completed + 1
                if err then
                    table.insert(errors, vim.inspect(err))
                elseif hover_text(result) ~= '' then
                    nonempty = nonempty + 1
                end
            end,
            bufnr
        )
        expect(sent, 'Failed to enqueue hover request')
    end
    local done = vim.wait(60000, function()
        return completed == count
    end, 20)
    expect(done, string.format('Only %d/%d requests completed', completed, count))
    expect(#errors == 0, vim.inspect(errors))
    expect(nonempty == count, string.format('Only %d/%d hovers were nonempty', nonempty, count))
    return {
        completed = completed,
        nonempty = nonempty,
    }
end

test('concurrent hover burst', 'java', 'textDocument/hover x25', function()
    return async_hover_burst(java, java_service, java_cross_position, 25)
end)

test('concurrent hover burst', 'kotlin', 'textDocument/hover x25', function()
    return async_hover_burst(kotlin, kotlin_probe, kotlin_cross_position, 25)
end)

test('rapid incremental changes then recovery', 'java', 'textDocument/didChange x20', function()
    return with_restored_buffer(java_probe, function()
        local original = '        return customer.getDisplayName();'
        local alternate = '        return customer.getDisplayName().trim();'
        for index = 1, 20 do
            replace_line(
                java_probe,
                index % 2 == 0 and alternate or original,
                index % 2 == 0 and original or alternate
            )
        end
        vim.wait(500)
        local position = find_position(java_probe, 'return customer.getDisplayName()', 'customer')
        local text = hover_text(request(
            java,
            'textDocument/hover',
            text_document_position(java_probe, position),
            java_probe
        ))
        expect(text:find('Customer', 1, true) ~= nil, text)
        return { changes = 20, recovered_hover = text:sub(1, 300) }
    end)
end)

test('rapid incremental changes then recovery', 'kotlin', 'textDocument/didChange x20', function()
    return with_restored_buffer(kotlin_probe, function()
        local original =
            '    fun customerName(customer: Customer): String = customer.displayName'
        local alternate =
            '    fun customerName(customer: Customer): String = customer.displayName.trim()'
        for index = 1, 20 do
            replace_line(
                kotlin_probe,
                index % 2 == 0 and alternate or original,
                index % 2 == 0 and original or alternate
            )
        end
        vim.wait(500)
        local position = find_position(
            kotlin_probe,
            'fun customerName(customer: Customer)',
            'Customer'
        )
        local text = hover_text(request(
            kotlin,
            'textDocument/hover',
            text_document_position(kotlin_probe, position),
            kotlin_probe
        ))
        expect(text:find('Customer', 1, true) ~= nil, text)
        return { changes = 20, recovered_hover = text:sub(1, 300) }
    end)
end)

test('multi-buffer single-client reuse', 'java', 'workspace lifecycle', function()
    local attached = 0
    for _, bufnr in ipairs({ java_service, java_probe, java_policy, java_port }) do
        if vim.lsp.buf_is_attached(bufnr, java.id) then
            attached = attached + 1
        end
    end
    expect(attached == 4, 'Only ' .. attached .. '/4 Java buffers attached')
    expect(#vim.lsp.get_clients({ name = 'jdtls' }) == 1, 'Multiple JDTLS clients are running')
    return { attached_buffers = attached, client_count = 1 }
end)

test('multi-buffer single-client reuse', 'kotlin', 'workspace lifecycle', function()
    local attached = 0
    for _, bufnr in ipairs({
        kotlin_probe,
        kotlin_controller,
        kotlin_facade,
        kotlin_policy,
        kotlin_exception,
        kotlin_formatter,
    }) do
        if vim.lsp.buf_is_attached(bufnr, kotlin.id) then
            attached = attached + 1
        end
    end
    expect(attached == 6, 'Only ' .. attached .. '/6 Kotlin buffers attached')
    expect(
        #vim.lsp.get_clients({ name = 'kotlin_lsp' }) == 1,
        'Multiple Kotlin LSP clients are running'
    )
    return { attached_buffers = attached, client_count = 1 }
end)

local status_counts = {
    fail = 0,
    pass = 0,
    unsupported = 0,
}
for _, result in ipairs(report.tests) do
    status_counts[result.status] = status_counts[result.status] + 1
end
report.summary = status_counts
report.duration_ms = elapsed_ms(suite_started)
report.finished_at = os.date('!%Y-%m-%dT%H:%M:%SZ')

local detached = {
    java = 0,
    kotlin = 0,
}
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
        if vim.lsp.buf_is_attached(bufnr, java.id) then
            vim.lsp.buf_detach_client(bufnr, java.id)
            detached.java = detached.java + 1
        end
        if vim.lsp.buf_is_attached(bufnr, kotlin.id) then
            vim.lsp.buf_detach_client(bufnr, kotlin.id)
            detached.kotlin = detached.kotlin + 1
        end
    end
end
vim.wait(500)

java:stop()
kotlin:stop()
local graceful = vim.wait(30000, function()
    return java:is_stopped() and kotlin:is_stopped()
end, 100)
if not graceful then
    java:stop(true)
    kotlin:stop(true)
    vim.wait(5000, function()
        return java:is_stopped() and kotlin:is_stopped()
    end, 100)
end

report.cleanup = {
    detached_buffers = detached,
    graceful_shutdown = graceful,
    java_stopped = java:is_stopped(),
    kotlin_stopped = kotlin:is_stopped(),
}
vim.fn.writefile({ vim.json.encode(report) }, output)
print(string.format(
    '[DONE] %s: %d passed, %d failed, %d unsupported in %.1fs; graceful=%s; %s',
    run_name,
    status_counts.pass,
    status_counts.fail,
    status_counts.unsupported,
    report.duration_ms / 1000,
    tostring(graceful),
    output
))

if status_counts.fail > 0 then
    vim.cmd('cquit 2')
else
    vim.cmd('quitall!')
end

-- BEGIN JAVA_KOTLIN_LSP_NOTES.md
-- # Java/Kotlin LSP notes
--
-- ## Archive labels
--
-- Archive URIs remain unchanged internally and are shortened only when displayed:
--
-- | Surface | Display |
-- |---|---|
-- | LSP location picker | `Service.java spring-context-7.0.8.jar:42:5` |
-- | Tabline | `Service.java` |
-- | Statusline | `spring-context-7.0.8.jar › org.springframework.stereotype.Service` |
--
-- Both `jdt://contents/...` and `jar://...!/` are recognized. A source archive such as
-- `spring-context-7.0.8-sources.jar` is displayed as `spring-context-7.0.8.jar`, aligning Kotlin LSP and JDTLS results.
-- `jrt://` is left unchanged.
--
-- The real buffer name and the LSP result URI are never renamed. JDTLS and Kotlin LSP therefore continue receiving the
-- exact URI they returned.
--
-- ### LSP picker implementation
--
-- The structured LSP-item filter gives fzf-lua a synthetic path ending in the archive entry's real filename, followed by
-- a reversible hidden field:
--
-- ```text
-- archive.jar/Service.java:line:column <unit separator> original LSP entry
-- ```
--
-- The normal `path.filename_first` formatter displays this as `Service.java archive.jar:line:column` and selects the Java
-- or Kotlin icon from the filename extension. Fzf displays and searches only that first field. Its `_fmt._from` hook
-- restores the second field before the existing reverse formatter, previewer, navigation action, or quickfix action sees
-- the entry. Ordinary physical file results keep their existing formatting.
--
-- This shared behavior applies to the configured definition, peek, reference, implementation, and type-definition pickers.
--
-- ## Filtering Kotlin-generated JDTLS locations
--
-- All configured LSP location pickers exclude an item only when its filename is a `jdt://` URI containing the literal
-- marker:
--
-- ```text
-- /kotlin_generated=/true
-- ```
--
-- Normal JDK and dependency locations are retained, including `spring-context-7.0.8.jar`, `jakarta.persistence-api`, and
-- `java.base`, because their URIs do not have that marker.
--
-- ### Completeness warning
--
-- Kotlin-generated JDT locations are not necessarily duplicates. In the stress fixture, JDTLS returned one physical
-- `CustomerFacade.kt` URI and four distinct generated locations. Always filtering generated locations can therefore hide
-- real compiled Kotlin usages. This is an accepted tradeoff; there is no complete, unfiltered alternate mapping.
-- END JAVA_KOTLIN_LSP_NOTES.md

-- BEGIN LSP_STRESS_REPORT.md
-- # Mixed Java + Kotlin Spring Boot Neovim LSP stress report
--
-- Date: 2026-07-30
--
-- ## Outcome
--
-- The final stable headless run executed 71 checks:
--
-- - 61 passed
-- - 3 failed reproducibly
-- - 7 were unsupported because the server did not advertise the capability
-- - Both clients detached all buffers and shut down gracefully
-- - No JDTLS or Kotlin LSP process remained after the run
--
-- The three failures are narrow:
--
-- 1. A rename initiated by JDTLS on a Java declaration updates Java files but
--    omits Kotlin source references.
-- 2. Kotlin LSP advertises type hierarchy but returns `nil` for a same-language
--    Kotlin class.
-- 3. Kotlin LSP also returns `nil` for a Kotlin interface implemented by Java.
--
-- There is a working rename mitigation: initiating the rename from a Kotlin usage
-- through Kotlin LSP updates both the Kotlin usage and the Java declaration and
-- implementation.
--
-- ## Artifacts
--
-- - Project: `/tmp/nvim-java-kotlin-spring-lsp-stress`
-- - Headless harness: `/workspace/lsp-stress.lua`
-- - Final raw result: `/tmp/nvim-java-kotlin-spring-lsp-stress/no-silent-guard-final.json`
-- - Cold-JDTLS result: `/tmp/nvim-java-kotlin-spring-lsp-stress/simplify-no-init-settings-cold.json`
--
-- ## Environment and installation
--
-- | Component | Tested version |
-- |---|---|
-- | Neovim | 0.12.4 |
-- | Java | OpenJDK 21.0.11-ea |
-- | JDTLS | 1.60.0 milestone |
-- | Kotlin LSP | LS-262.9593.0 |
-- | Kotlin LSP runtime | bundled JBR 25.0.2 |
-- | Spring Boot | 4.1.0 |
-- | Spring Framework | 7.0.8 |
-- | Kotlin Gradle plugin | 2.3.21 |
-- | Gradle wrapper | 9.5.1 |
--
-- The test `PATH` contained the exact extracted server artifacts represented by
-- the repository Dockerfile:
--
-- - JDTLS archive SHA-256:
--   `e94c303d8198f977930803582738771fd18c52c5492878410bf222b1aa81ef1d`
-- - ARM64 Kotlin LSP SHA-256:
--   `2317831c6e5607d05b7ebc1da655330125ce0e3d66fbf24517dfce442debc14e`
--
-- The Spring Initializr Gradle wrapper installed Gradle 9.5.1. The project passed
-- `./gradlew clean test`, including Spring context startup, JPA initialization,
-- H2, Kotlin compilation, and Java compilation.
--
-- ## Fixture
--
-- The project contains seven Java files and eight Kotlin files under `src/main`.
-- It uses Spring Web MVC, Validation, Data JPA, H2, and Actuator.
--
-- The cross-language graph is intentionally bidirectional:
--
-- - Java `JavaGreetingService` depends on Kotlin `GreetingFormatter`.
-- - Kotlin `CustomerFacade` depends on Java `CustomerRepository` and
--   `GreetingPort`.
-- - Java `ActiveCustomerPolicy` implements Kotlin `CustomerPolicy`.
-- - Java `JavaProbe` depends on Kotlin `CustomerFacade` and `CustomerView`.
-- - Kotlin controllers navigate into Spring Framework classes and Java/JDK
--   classes.
--
-- ## Method
--
-- The harness starts Neovim headlessly with the real repository `init.lua`. It
-- opens Java and Kotlin buffers concurrently, waits for each client, and then
-- polls a cross-language definition until semantic project import is usable.
--
-- Every feature is exercised with an actual LSP request. Results are validated
-- against expected file URIs, symbols, completion labels, edit sets, diagnostics,
-- or source contents. In-memory error and formatting probes are restored without
-- writing invalid source to disk. Rename edits are inspected but not applied.
--
-- Stress cases include 25 concurrent hover requests per server, 20 rapid
-- incremental changes per language, multiple attached buffers, archive source
-- loading through the fzf-lua definition picker, and repeated cold/warm client
-- lifecycles.
--
-- ## Startup and lifecycle
--
-- | Run | Cache state | Semantic readiness |
-- |---|---|---|
-- | Initial Spring run | Both project caches absent | Both usable in about 39.4 s |
-- | Clean JDTLS, warm Kotlin | JDTLS rebuilt, Kotlin reused | Both usable in about 9.3 s |
-- | Final simplified warm run | Both reused | Both usable in about 3.8 s |
--
-- The final feature matrix took 22.1 seconds after startup and shut down
-- gracefully.
--
-- An earlier harness version force-stopped clients with edited buffers attached.
-- On the next start JDTLS reported an unclean workspace and Buildship hit an OSGi
-- bundle-lock timeout. The stalled cache was preserved at
-- `/tmp/jdtls-stalled-cache-20260730`. The final harness sends `didClose`, detaches
-- all buffers, and performs a graceful shutdown. A real crash or `SIGKILL` could
-- still produce this JDTLS recovery case; `:JdtWipeDataAndRestart` is the recovery
-- command supplied by `nvim-jdtls`.
--
-- ## Per-feature results
--
-- Status meanings:
--
-- - PASS: an actual request returned the expected semantic result.
-- - FAIL: the server advertised or performed the base operation, but the tested
--   result was missing.
-- - UNSUPPORTED: the server did not advertise the capability, so a normal Neovim
--   client would not issue the request.
--
-- | Feature | Language | How it was tested | Result |
-- |---|---|---|---|
-- | Server attachment and root | Java | Opened `JavaGreetingService.java`; inspected the attached client, root, command, and `-data` path. | PASS: one JDTLS client, correct root and hashed workspace. |
-- | Server attachment and root | Kotlin | Opened `KotlinProbe.kt`; inspected the attached client, root, and command. | PASS: one Kotlin client, correct root, and stock `intellij-server --stdio` command. |
-- | Clean baseline diagnostics | Java | Read published diagnostics for a compiled source buffer. | PASS: zero errors. |
-- | Clean baseline diagnostics | Kotlin | Issued `textDocument/diagnostic` after project import. | PASS: zero errors; response in 1.76 s. |
-- | Same-language definition | Java | Requested definition of `CustomerStatus` from `ActiveCustomerPolicy`. | PASS: `CustomerStatus.java`. |
-- | Same-language definition | Kotlin | Requested definition of `CustomerFacade` from the controller. | PASS: `CustomerFacade.kt`. |
-- | Java-to-Kotlin definition | Java | Requested `GreetingFormatter` from Java service code. | PASS: `GreetingFormatter.kt`. |
-- | Kotlin-to-Java definition | Kotlin | Requested `Customer` from `KotlinProbe`. | PASS: `Customer.java`. |
-- | Type definition | Java | Requested the type of Java field `formatter`. | PASS: crossed into `GreetingFormatter.kt`. |
-- | Type definition | Kotlin | Requested the type of controller property `customerFacade`. | PASS: `CustomerFacade.kt`. |
-- | Declaration | Java | Requested declaration from Java override `greet` to `GreetingPort`. | PASS: `GreetingPort.java`. |
-- | Cross-language declaration | Java | Requested declaration from Java override `canGreet` to the Kotlin interface. | PASS: `CustomerPolicy.kt`. |
-- | Declaration | Kotlin | Checked server capabilities before requesting. | UNSUPPORTED: not advertised. |
-- | Hover | Java | Hovered the Kotlin `GreetingFormatter` type from Java. | PASS: Kotlin type/source information returned. |
-- | Hover | Kotlin | Hovered Java entity `Customer` from Kotlin. | PASS: entity annotations and class information returned. |
-- | Document symbols | Java | Requested nested symbols for `JavaGreetingService`. | PASS: 8 recursive symbols. |
-- | Document symbols | Kotlin | Requested nested symbols for `CustomerFacade`. | PASS: 9 recursive symbols. |
-- | Workspace symbols | Java | Queried `Customer`. | PASS: 9 symbols. |
-- | Workspace symbols | Kotlin | Queried `Customer`. | PASS: 12 symbols. |
-- | Completion | Java | Changed a buffer to `customer.` and requested triggered completion. | PASS: 16 items including `getDisplayName`. |
-- | Completion | Kotlin | Changed a buffer to `customer.` and requested triggered completion. | PASS: 24 items including `displayName`. |
-- | Same-language signature help | Java | Replaced a line in memory with `decorate(` and tested valid cursor/context combinations. | PASS: `decorate(String value, int repeat) : String`. |
-- | Cross-language signature help | Java | Typed `formatter.format(` where `formatter` is Kotlin. | PASS: `format(Customer customer) : String`. |
-- | Same-language signature help | Kotlin | Requested help inside `customerFacade.find(id)`. | PASS: `find(id: Long): CustomerView`. |
-- | Cross-language signature help | Kotlin | Requested help inside the Java `Customer(...)` constructor. | PASS: Java constructor signature returned. |
-- | Semantic diagnostics | Java | Changed a `String` return to `return 42` in memory and waited for published diagnostics. | PASS: Java type-mismatch error returned. |
-- | Semantic diagnostics | Kotlin | Changed a `String` expression to `42` and pulled diagnostics. | PASS: Kotlin return-type mismatch returned. |
-- | Missing-import quick fix | Java | Inserted an unresolved `ResponseEntity` use and requested code actions with diagnostics. | PASS: Spring `ResponseEntity` import action returned. |
-- | Missing-import quick fix | Kotlin | Removed the `ResponseEntity` import in memory, pulled diagnostics, and requested actions. | PASS: Spring `ResponseEntity` import action returned. |
-- | Organize imports | Java | Requested only `source.organizeImports`. | PASS: organize-imports action returned. |
-- | Organize imports | Kotlin | Requested only `source.organizeImports`. | PASS: organize-imports action returned. |
-- | Formatting | Java | Made a method line deliberately malformed in memory and requested full formatting. | PASS: 4 edits returned. |
-- | Formatting | Kotlin | Made a function line deliberately malformed in memory and requested full formatting. | PASS: 6 edits returned. |
-- | References across languages | Java | Requested references for Java `Customer`. | PASS: 21 results including Kotlin source files. |
-- | References across languages | Kotlin | Requested references for Kotlin `CustomerFacade`. | PASS: 7 results including `JavaProbe.java`. |
-- | Implementation | Java | Requested implementations of Java `GreetingPort`. | PASS: `JavaGreetingService.java`. |
-- | Cross-language implementation | Kotlin | Requested implementations of Kotlin `CustomerPolicy`. | PASS: Java `ActiveCustomerPolicy.java`. |
-- | Prepare rename | Java | Checked `renameProvider.prepareProvider`. | UNSUPPORTED: not advertised. Direct rename is supported. |
-- | Prepare rename | Kotlin | Checked `renameProvider.prepareProvider`. | UNSUPPORTED: not advertised. Direct rename is supported. |
-- | Rename within Java | Java | Previewed rename of `GreetingPort`. | PASS: declaration and `JavaGreetingService` edits returned. |
-- | Java rename including Kotlin callers | Java | Previewed the same rename and required `CustomerFacade.kt` edits. | FAIL: only 2 Java edits; Kotlin use omitted. |
-- | Kotlin rename including Java callers | Kotlin | Previewed rename of Kotlin `CustomerFacade`. | PASS: 7 edits across Kotlin and `JavaProbe.java`. |
-- | Rename Java symbol from Kotlin | Kotlin | Requested rename on the Kotlin use of Java `GreetingPort`. | PASS: 3 edits across Java declaration, Java implementation, and Kotlin use. |
-- | Document highlights | Java | Highlighted `formatter` uses in one document. | PASS: 3 ranges. |
-- | Document highlights | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
-- | Folding ranges | Java | Requested ranges for `JavaGreetingService`. | PASS: 7 ranges. |
-- | Folding ranges | Kotlin | Requested ranges for `CustomerController`. | PASS: 6 ranges. |
-- | Selection ranges | Java | Requested nested selections inside a method argument. | PASS: nested parent ranges returned. |
-- | Selection ranges | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
-- | Semantic tokens | Java | Requested full-document semantic tokens. | PASS: 75 tokens. |
-- | Semantic tokens | Kotlin | Requested full-document semantic tokens. | PASS: 74 tokens. |
-- | Call hierarchy | Java | Prepared `greet`, then requested incoming and outgoing calls. | PASS: 1 incoming and 3 outgoing. |
-- | Call hierarchy | Kotlin | Prepared `CustomerFacade.find`, then requested both directions. | PASS: 2 incoming and 2 outgoing. |
-- | Type hierarchy | Java | Prepared `GreetingPort`, then requested subtypes/supertypes. | PASS: `JavaGreetingService` subtype returned. |
-- | Same-language type hierarchy | Kotlin | Prepared Kotlin `CustomerNotFoundException`, which extends another type. | FAIL: provider advertised, but prepare returned `nil`. |
-- | Cross-language type hierarchy | Kotlin | Prepared Kotlin `CustomerPolicy`, implemented by Java. | FAIL: provider advertised, but prepare returned `nil`. |
-- | Inlay hints | Java | Checked capabilities. | UNSUPPORTED: not advertised in this client session. |
-- | Inlay hints | Kotlin | Enabled parameter hints, called `customerFacade.find(42)`, and requested hints. | PASS: 1 actual hint returned. |
-- | Code lens | Java | Requested code lenses for the service. | PASS: 5 lenses. |
-- | Code lens | Kotlin | Checked capabilities. | UNSUPPORTED: not advertised. |
-- | JDK class source | Java | Navigated `List` to a `jdt://` URI and opened it through `nvim-jdtls`. | PASS: 190 Java lines, nonmodifiable buffer. |
-- | Spring class source | Java | Navigated `@Service` into `spring-context`. | PASS: 57 Java lines, nonmodifiable buffer. |
-- | JDK decompilation | Kotlin | Invoked fzf-lua definition navigation on `UUID`; its preload opened the `jrt://` URI through the Kotlin bridge. | PASS: 55 Java lines in a nonmodifiable virtual buffer. |
-- | Spring source/decompilation | Kotlin | Invoked fzf-lua definition navigation on `ResponseEntity`; its preload opened the `jar://` URI through the Kotlin bridge. | PASS: 667 Java lines in a nonmodifiable virtual buffer. |
-- | `nvim-jdtls` integration | Java | Inspected extended capabilities, server commands, and buffer-local commands. | PASS: 11 extended capabilities, 33 server commands, and `JdtCompile`, `JdtUpdateConfig`, `JdtRestart`. |
-- | Concurrent request burst | Java | Sent 25 asynchronous hover requests before waiting. | PASS: 25/25 completed with nonempty results. |
-- | Concurrent request burst | Kotlin | Sent 25 asynchronous hover requests before waiting. | PASS: 25/25 completed with nonempty results. |
-- | Rapid incremental changes | Java | Sent 20 alternating valid `didChange` updates, then requested hover. | PASS: semantic hover recovered. |
-- | Rapid incremental changes | Kotlin | Sent 20 alternating valid `didChange` updates, then requested hover. | PASS: semantic hover recovered. |
-- | Multi-buffer reuse | Java | Attached four Java buffers and counted clients. | PASS: all four used one JDTLS client. |
-- | Multi-buffer reuse | Kotlin | Attached six Kotlin buffers and counted clients. | PASS: all six used one Kotlin client. |
--
-- ## Configuration changes discovered by testing
--
-- The stress loop found and fixed two missing settings in the repository Neovim
-- configuration:
--
-- 1. `java.signatureHelp.enabled = true`
--    - JDTLS advertises signature help but defaults this preference to `false`.
--    - Before enabling it, every Java signature request returned an empty list.
-- 2. `jetbrains.kotlin["hints.parameters"] = true`
--    - Kotlin LSP requests this configuration through `workspace/configuration`.
--    - Without it, the server accepted inlay requests but returned no hints.
--
-- Both settings are now present in `/workspace/.config/nvim/init.lua`, and their
-- features passed in the final run.
--
-- ## Assessment
--
-- The setup is strong for normal Java/Kotlin Spring work: completion, hover,
-- diagnostics, fixes, formatting, symbols, definitions, declarations,
-- implementations, references, signature help, semantic tokens, call hierarchy,
-- archive navigation, and repeated editing all worked.
--
-- The important operational caveat is refactoring ownership. Cross-language
-- read/navigation is good in both directions, but a rename initiated from a Java
-- buffer is not Kotlin-safe. For a Java symbol referenced by Kotlin, initiate the
-- rename from a Kotlin usage so Kotlin LSP can produce the combined Java/Kotlin
-- workspace edit, or verify Java-initiated rename results before applying them.
--
-- Kotlin type hierarchy is currently unreliable despite being advertised.
-- Unsupported Kotlin declaration/highlight/selection/code-lens features reflect
-- the current Alpha server rather than the Neovim wiring.
-- END LSP_STRESS_REPORT.md
