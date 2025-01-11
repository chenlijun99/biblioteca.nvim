local M = {}

---
---@param item biblioteca.CitationItem
---@return string?
function M.best_effort_get_title(item)
    if type(item.entry.title) == 'string' then
        return item.entry.title
    elseif type(item.entry.title) == 'table' then
        if type(item.entry.title.value) == 'string' then
            return item.entry.title.value
        elseif type(item.entry.title.short) == 'string' then
            return item.entry.title.short
        end
    end
end

return M
