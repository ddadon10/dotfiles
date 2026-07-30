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
