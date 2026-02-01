-- ========================================================================== --
-- 0. NEOVIM 0.11 UYUMLULUK YAMASI                                            --
-- ========================================================================== --
if not vim.treesitter.ft_to_lang then
    vim.treesitter.ft_to_lang = vim.treesitter.language.get_lang
end

-- ========================================================================== --
-- 1. TEMEL AYARLAR                                                           --
-- ========================================================================== --
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Otomatik Kaydetme
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- Whitespace Görünümü
vim.opt.list = true
vim.opt.listchars = {
    tab = '» ',
    trail = '×',
    nbsp = '␣',
    leadmultispace = '│   ',
}

-- ========================================================================== --
-- 2. EKLENTİ YÖNETİCİSİ (LAZY.NVIM)                                          --
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "nvim-tree/nvim-web-devicons" },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
    
    -- C++ Sözdizimi (Treesitter)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local status_ok, configs = pcall(require, "nvim-treesitter.configs")
            if not status_ok then return end
            configs.setup({
                ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc" },
                highlight = { enable = true },
                indent = { enable = false },
            })
        end,
    },

    { "neovim/nvim-lspconfig" },
    { "williamboman/mason.nvim", config = true },
    { "williamboman/mason-lspconfig.nvim" },

    { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp", "L3MON4D3/LuaSnip" } },

    { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
    { "nvim-tree/nvim-tree.lua" },
    { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
    { 'numToStr/Comment.nvim', opts = {} },
    { "stevearc/dressing.nvim", opts = {} },
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        opts = { open_mapping = [[<c-\>]], direction = 'float' }
    },
})

-- ========================================================================== --
-- 3. TEMA VE GÖRSEL AYARLAR                                                  --
-- ========================================================================== --
vim.cmd.colorscheme "catppuccin"

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "always" },
})

-- ========================================================================== --
-- 4. LSP VE CLANGD YAPILANDIRMASI (NEOVIM 0.11 API)                          --
-- ========================================================================== --
local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("mason-lspconfig").setup({ ensure_installed = { "clangd" } })

vim.lsp.config('clangd', {
    default_config = {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--compile-commands-dir=build",
            "--fallback-style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}"
        },
        capabilities = capabilities,
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    }
})
vim.lsp.enable('clangd')

-- LSP BAĞLANDIĞINDA ÇALIŞACAK KISAYOLLAR
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local opts = { buffer = bufnr }

        -- F4: Header/Source Geçişi (Direct LSP Request - Hatasız Versiyon)
        if client and client.name == "clangd" then
            vim.keymap.set('n', '<F4>', function()
                vim.lsp.buf_request(bufnr, 'textDocument/switchSourceHeader', { uri = vim.uri_from_bufnr(bufnr) }, function(err, result)
                    if err then 
                        vim.notify("LSP Hatası: " .. tostring(err), vim.log.levels.ERROR)
                        return 
                    end
                    if not result then
                        vim.notify("İlgili header/source dosyası bulunamadı.", vim.log.levels.WARN)
                        return
                    end
                    vim.api.nvim_command('edit ' .. vim.uri_to_fname(result))
                end)
            end, { buffer = bufnr, desc = "Header/Source Geçişi" })
        end

        -- Standart LSP Kısayolları
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    end,
})

-- ========================================================================== --
-- 5. TAMAMLAMA (CMP) AYARLARI                                                --
-- ========================================================================== --
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
        end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'luasnip' } }, { { name = 'buffer' } })
})

cmp.event:on('confirm_done', require('nvim-autopairs.completion.cmp').on_confirm_done())

-- ========================================================================== --
-- 6. NVIM-TREE AYARLARI                                                      --
-- ========================================================================== --
require("nvim-tree").setup({
    view = { width = 30 },
    git = { enable = true, ignore = true },
    renderer = {
        highlight_git = true,
        icons = { show = { git = true } },
    },
    filters = { custom = { "^.git$" } },
})

-- ========================================================================== --
-- 7. KISAYOLLAR (KEYMAPS)                                                    --
-- ========================================================================== --
vim.keymap.set('n', '<F5>', function()
    vim.cmd("w")
    vim.cmd('TermExec cmd="g++ -O3 % -o %< && ./%<"')
end, { desc = "Derle ve Çalıştır" })

-- İmleç Geçmişi Gezintisi (VS Code Tarzı)
vim.keymap.set('n', '<A-Left>', '<C-o>', { desc = "Geri Git (Jump List)" })
vim.keymap.set('n', '<A-Right>', '<C-i>', { desc = "İleri Git (Jump List)" })

vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

local bt = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', bt.find_files)
vim.keymap.set('n', '<leader>fg', bt.live_grep)
vim.keymap.set('n', '<leader>fb', bt.buffers)
vim.keymap.set('n', 'gr', bt.lsp_references)

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float)

-- ========================================================================== --
-- 8. OTOMATİK İŞLEMLER (AUTOCMDS)                                            --
-- ========================================================================== --
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.cpp", "*.h", "*.hpp", "*.c" },
    callback = function() vim.lsp.buf.format({ async = false }) end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
    callback = function()
        if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! wall")
        end
    end,
})
