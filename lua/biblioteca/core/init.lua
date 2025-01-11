local M = {}

local rust_api = require('biblioteca.core.rust')

---@alias biblioteca.CitationItems table<string, table<string, biblioteca.CitationItem>>

---@type biblioteca.CitationItems
local cached_citation_items = {}

--- Get all the citation items
---
---@param config biblioteca.Opts
---@param cb fun(citation_items: biblioteca.CitationItems)
function M.get_all_citation_items(config, cb)
    local function worker_task(source_type, path, style, locale)
        local rust = require('biblioteca.core.rust')
        return rust.process_source(source_type, path, style, locale)
    end

    local pending = {}
    local function complete_cb(source_id, result)
        pending[source_id] = nil
        cached_citation_items[source_id] = vim.json.decode(result, {
            object = true,
            array = true,
        })
        if next(pending) == nil then
            cb(cached_citation_items)
        end
    end

    for source_id, source in pairs(config.sources) do
        local request = { source.type, source.path, (source.citation or {}).style, (source.citation or {}).locale }
        if rust_api.is_source_cache_valid(unpack(request)) then
            if type(cached_citation_items[source_id]) ~= 'table' then
                local result = rust_api.process_source(unpack(request))
                cached_citation_items[source_id] = vim.json.decode(result, {
                    object = true,
                    array = true,
                })
            end
        else
            pending[source_id] = true
            local work = vim.uv.new_work(worker_task, function(result)
                complete_cb(source_id, result)
            end)
            work:queue(unpack(request))
        end
    end

    -- If all the cache is still valid
    if next(pending) == nil then
        cb(cached_citation_items)
    end
end

function M.get_citation_item(config, source_id, item_key, cb)
    M.get_all_citation_items(config, function(items)
        cb((items[source_id] or {})[item_key])
    end)
end

---@return biblioteca.CitationItems
function M.get_cached_citation_items()
    return cached_citation_items
end

---@return biblioteca.CitationItem?
function M.get_cached_citation_item(source_id, item_key)
    return (cached_citation_items[source_id] or {})[item_key]
end

return M
