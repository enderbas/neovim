-- Neovim 0.11 Telescope hatası için yama (shim)
if not vim.treesitter.ft_to_lang then
    vim.treesitter.ft_to_lang = vim.treesitter.language.get_lang
end
-- 1. Temel Ayarlar ve Leader Key
vim.g.mapleader = " "           -- Boşluk tuşunu Leader yap
vim.opt.number = true           -- Satır numaraları
vim.opt.tabstop = 4             -- Tab 4 boşluk
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true        -- Boşluk kullan
vim.opt.termguicolors = true    -- Gerçek renk desteği
vim.opt.clipboard = "unnamedplus" -- Sistem panosu ile entegrasyon
vim.opt.autowrite = true    -- Bazı komutlar çalıştırıldığında kaydet
vim.opt.autowriteall = true -- Dosyadan ayrılırken (buffer switch) kaydet

-- 2. Eklenti Yöneticisi (lazy.nvim) Kurulumu
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Eklentileri Yükle
require("lazy").setup({
    -- Görünüm
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "nvim-tree/nvim-web-devicons" },

    -- C++ Sözdizimi (Treesitter)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = {
            ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query" },
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            indent = { enable = false },
        },
        config = function(_, opts)
            local status_ok, configs = pcall(require, "nvim-treesitter.configs")
            if status_ok then configs.setup(opts) else require("nvim-treesitter").setup(opts) end
        end,
    },

    -- LSP (Language Server Protocol)
    { "neovim/nvim-lspconfig" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },

    -- Otomatik Tamamlama
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "L3MON4D3/LuaSnip" },

    -- Araçlar
    { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
    { "nvim-tree/nvim-tree.lua" },
    { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
    { 'numToStr/Comment.nvim', opts = {} }, -- Hızlı yorum satırı (gcc)
    { "stevearc/dressing.nvim", opts = {} },
    {
    'akinsho/toggleterm.nvim',
    version = "*",
    opts = {
        open_mapping = [[<c-\>]], -- Ctrl + \ ile terminali açıp kapatabilirsin
        direction = 'float',      -- Terminal ortada yüzen bir pencere olsun
    }
},
})

-- 4. Renk Şemasını Aktif Et
vim.cmd.colorscheme "catppuccin"

-- 5. LSP Ayarları (Neovim 0.11+)
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "clangd" } })

local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('clangd', {
    default_config = {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--compile-commands-dir=build",
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        capabilities = capabilities,
    }
})
vim.lsp.enable('clangd')

-- 6. nvim-cmp (Otomatik Tamamlama) Ayarları
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

-- ÖNEMLİ: Autopairs ve Cmp Entegrasyonu
-- Bir fonksiyon seçtiğinde parantezleri otomatik ekler
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

-- 7. Nvim-Tree (Dosya Gezgini) Ayarları
require("nvim-tree").setup({
    sort_by = "case_sensitive",
    view = { width = 30 },
    renderer = { group_empty = true },
    -- Git entegrasyonu ayarları
    git = {
        enable = true,
        ignore = true, -- .gitignore içindeki dosyaları GİZLER
        timeout = 400,
    },
    -- İkonların ve diğer görsellerin ayarları
    renderer = {
        highlight_git = true, -- Değişen dosyaları renklendirir
        icons = {
            show = {
                git = true,
            },
        },
    },
    -- Gizli dosyalar (nokta ile başlayanlar vb.) için filtre
    filters = {
        dotfiles = false, -- .git gibi dosyaları da gizlemek istersen true yapabilirsin
        custom = { "^.git$" }, -- Sadece .git klasörünü gizle
    },
})

-- 8. Kısayollar
-- F5: Derle ve Çalıştır
--vim.keymap.set('n', '<F5>', ':w <CR> :!g++ -O3 % -o %< && ./%< <CR>', { desc = "Derle ve Çalıştır" })
vim.keymap.set('n', '<F5>', function()
    vim.cmd("w") -- Önce dosyayı kaydet
    -- TermExec komutu ile terminalde derle ve çalıştır
    -- g++ -O3 (DosyaAdı) -o (ÇıktıAdı) && ./(ÇıktıAdı)
    vim.cmd('TermExec cmd="g++ -O3 % -o %< && ./%<"')
end, { desc = "ToggleTerm ile Derle ve Çalıştır" })
-- Space + e: Dosya Gezgini
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Explorer" })
-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})

-- Hata ve Uyarılar Arasında Gezinti
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Önceki hata/uyarı" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Sonraki hata/uyarı" })

-- Hata Detayını Gör (İmleç hatanın üzerindeyken popup açar)
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Hata detayını göster" })

-- Tüm hataları bir listede gör (Quickfix List)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, { desc = "Tüm hataları listele" })
-- Kod düzeltme (Code Action) menüsünü açar
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "Kod düzeltmesini uygula" })
-- Değişkenin ismini projenin her yerinde değiştirir (Rename)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Değişkeni her yerde yeniden adlandır" })
-- İmlecin altındaki sembolün nerede kullanıldığını listeler (References)
vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, { desc = "Kullanımları göster" })

-- 9. Otomatik Formatlama (Clang-Format)
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.cpp", "*.h", "*.hpp", "*.c" },
    callback = function() vim.lsp.buf.format({ async = false }) end,
})

-- 12. Diagnostic (Hata/Uyarı) Görünüm Ayarları
vim.diagnostic.config({
    virtual_text = true,           -- Satırın sonunda hatayı yazı olarak göster
    signs = true,                  -- Satır başında ikon göster
    update_in_insert = false,      -- Yazarken değil, yazma bitince (Esc) güncelle
    underline = true,              -- Hatalı kodun altını çiz
    severity_sort = true,          -- Hataları öncelik sırasına göre göster
    float = {
        border = "rounded",        -- Hata penceresi kenarlığı yuvarlak olsun
        source = "always",         -- Hatanın hangi kaynaktan (clangd vb.) geldiğini yaz
    },
})

-- Sol taraftaki işaretleri (Sign Column) ikonlarla değiştirme
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Otomatik Kaydetme (FocusLost: Pencere odağı gidince, BufLeave: Dosya değişince)
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
    callback = function()
        -- Eğer dosya değiştirilmişse ve kaydedilebilir bir dosyaysa kaydet
        if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! wall")
        end
    end,
})
