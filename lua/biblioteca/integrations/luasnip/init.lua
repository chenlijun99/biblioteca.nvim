-- https://www.reddit.com/r/neovim/comments/y1hut5/call_a_luasnip_snippet_from_lua_script/?rdt=61034
--
local luasnip = require('luasnip')

local M = {}

--- Setup LuaSnip namespace for biblioteca
---@param fn_get_current_item
function M.setup(opts)
    luasnip.env_namespace('BIBLIOTECA', {
        vars = {
            ITEM_TITLE = 'TODO',
            ITEM_KEY = 'TODO',
        },
    })
end


return M
