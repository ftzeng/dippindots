-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Telescope integrations
  nmap('<leader>r', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('<leader>s', require('telescope.builtin').lsp_workspace_symbols, 'Search Workspace [S]ymbols')
  vim.keymap.set({'n'}, '<leader>d', function()
    require('telescope.builtin').diagnostics({
        line_width = 120,
        no_sign = true,
        severity = 'error', -- Only show errors
    })
  end, { desc = 'List diagnostics' })

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })

  -- Semantic tokens not well supported,
  -- suggested to have it disabled for now.
  client.server_capabilities.semanticTokensProvider = nil
end

-- Enable the following language servers
local servers = {
  pyright = {},
  rust_analyzer = {},
  tsserver = {},
  cssls = {},
  bashls = {},
}

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
    }
  end,
}

-- Omnisharp/C#/Unity
local pid = vim.fn.getpid()
local omnisharp_bin = "/opt/omnisharp-roslyn/run"
require('lspconfig').omnisharp.setup{
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    },
    cmd = { omnisharp_bin, "--languageserver" , "--hostPID", tostring(pid) };
}