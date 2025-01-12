local M = {}

local rust_api = require('biblioteca.core.rust')
local pathlib = require('plenary.path')

local rust_cache_dir = vim.fn.stdpath('cache') .. '/biblioteca/rust_cache'
pathlib.new(rust_cache_dir):mkdir { parents = true, exists_ok = true }

---@alias biblioteca.CitationItems table<string, table<string, biblioteca.CitationItem>>

---@type biblioteca.CitationItems
local cached_citation_items = {}

--- Get all the citation items
---
---@param config biblioteca.Opts
---@param cb fun(citation_items: biblioteca.CitationItems)
function M.get_all_citation_items(config, cb)
    local function worker_task(cache_dir, source_type, source_path, csl_style, csl_locale)
        local rust = require('biblioteca.core.rust')
        local request = {
            cache_dir = cache_dir,
            source_type = source_type,
            source_path = source_path,
            csl_style = csl_style,
            csl_locale = csl_locale,
        }
        return rust.process_source(request)
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
        local request = {
            cache_dir = rust_cache_dir,
            source_type = source.type,
            source_path = source.path,
            csl_style = (source.citation or {}).style,
            csl_locale = (source.citation or {}).locale,
        }
        if rust_api.is_source_cache_valid(request) then
            if type(cached_citation_items[source_id]) ~= 'table' then
                local result = rust_api.process_source(request)
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
            work:queue(
                request.cache_dir,
                request.source_type,
                request.source_path,
                request.csl_style,
                request.csl_locale
            )
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
