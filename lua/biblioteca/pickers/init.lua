local core = require('biblioteca.core')

local M = {}

---@class biblioteca.pickers.SelectedCitationItem
---@field source_id string
---@field item_key string
---@field item biblioteca.CitationItem

--- Parse selected lines into citation items
---@param selected string[]
---@return biblioteca.pickers.SelectedCitationItem[]
function M.parse_selected(selected)
    local result = {}

    for _, line in ipairs(selected) do
        local it = vim.split(line, ':')

        local source_id = it[1]
        assert(type(source_id) == 'string')
        local item_key = it[2]
        assert(type(item_key) == 'string')
        local item = core.get_cached_citation_item(source_id, item_key)

        table.insert(result, { source_id = source_id, item_key = item_key, item = item })
    end
    return result
end

return M
