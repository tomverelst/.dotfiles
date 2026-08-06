-- nvim-treesitter main branch (neovim 0.12+)
-- Highlighting is now built-in to neovim; this plugin provides parsers & queries
require('nvim-treesitter').setup()

-- Install parsers
vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
        require('nvim-treesitter').install({ 'javascript', 'typescript', 'lua', 'rust', 'java' })
    end,
})
