local core = require('biblioteca.core')
local config = require('biblioteca.core.config')
local log = require('biblioteca.core._log')

local fzf_lua = require('fzf-lua')

local M = {}

function M.bibliography()
    local c = config.parse_current_config()

    local opts = {
        fzf_opts = {
            ['--wrap'] = true,
            ['--with-nth'] = '3..',
            ['--delimiter'] = ':',
        },
    }
    opts = vim.tbl_deep_extend('error', opts, c.pickers.fzf_lua or {})

    fzf_lua.fzf_exec(function(fzf_cb)
        core.get_all_citation_items(c, function(citation_items)
            local source_cnt = 0
            local entry_cnt = 0
            for source_id, items in pairs(citation_items) do
                source_cnt = source_cnt + 1
                for key, item in pairs(items) do
                    local s = string.format('%s:%s:%s', source_id, key, c.fmt(source_id, key, item))
                    fzf_cb(s)
                    entry_cnt = entry_cnt + 1
                end
            end
            if source_cnt == 0 then
                log.warn('No source specified')
            elseif entry_cnt == 0 then
                log.warn('No citation items available')
            end
            fzf_cb()
        end)
    end, opts)
end

return M
