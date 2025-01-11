---@mod biblioteca.config plugin configuration
---
---@brief [[
---
---To configure biblioteca, set the variable `vim.g.biblioteca`,
---which is a `biblioteca.Opts` table, in your neovim configuration.
---
---Example:
---
--->lua
------@type biblioteca.Opts
---vim.g.biblioteca = {
---   ---@type biblioteca.source.Opts
---   sources = {
---     {
---       type = "biblatex",
---       path = "/path/to/biblatex"
---     },
---     -- ...
---   },
---   ---@type biblioteca.picker.Opts
---   pickers = {
---     -- ...
---   },
--- }
---<
---
---@brief ]]

local log = require('biblioteca.core._log')
local util = require('biblioteca.core._util')
local pathlib = require('plenary.path')

local M = {}

---@enum (key) biblioteca.source.SourceType
M.SOURCE_TYPE = {
    BIBTEX = 'bibtex',
    BIBLATEX = 'biblatex',
    CSL_JSON = 'csl-json',
}

---@class biblioteca.source.CitationStyle
---@field style string The citation style (e.g., "ieee").
---@field locale string? The locale for citations (e.g., "en_US").

---@class biblioteca.source.Opts
---@field type biblioteca.source.SourceType The type of source (e.g., "biblatex").
---@field path string The path to the source file.
---@field citation biblioteca.source.CitationStyle? The citation style configuration.

---@class (exact) biblioteca.Opts Plugin configuration
---@field sources table<string, biblioteca.source.Opts> Sources options
---@field fmt fun(source_id: string, item_key: string, item: biblioteca.CitationItem): string A formatter function.
---@field cache_fmt boolean Whether to cache formatted results.
---@field pickers biblioteca.pickers.Opts? Pickers options
---
---@class (exact) biblioteca.pickers.Opts
---Configurations for the fzf_lua picker
---@field fzf_lua biblioteca.pickers.fzf_lua.Opts?
---
---@class biblioteca.pickers.fzf_lua.Opts
---All the options accepted by fzf.lua are allowed (https://github.com/ibhagwan/fzf-lua#customization)
---Only exception
---@field actions biblioteca.pickers.fzf_lua.Opts?

---Validate source object
---
---@param key string
---@param input table
---@return biblioteca.source.Opts?
local function parse_source(key, input)
    local result = {}
    -- Validate `type` field
    local source_type = input.type
    if not source_type or not M.SOURCE_TYPE[source_type:upper()] then
        log.error(string.format("Source %s: invalid or missing 'type' field: %s", key, tostring(source_type)))
        return
    end
    result.type = source_type

    -- Validate `path` field
    local path = input.path
    if type(path) ~= 'string' or path == '' then
        log.error(string.format("Source %s: invalid or missing 'path' field: %s", key, tostring(path)))
        return
    end
    local p = pathlib.new(pathlib.new(path):expand())
    if not p:exists() then
        log.error(string.format("Source %s: specified path '%s' doesn't exist", key, tostring(p)))
        return
    end
    result.path = p:expand()

    -- Validate `citation` field
    local citation = input.citation
    if type(citation) == 'table' then
        -- Validate `style` field in `citation`
        if type(citation.style) ~= 'string' or citation.style == '' then
            log.error(
                string.format(
                    "Source %s: citation style 'style' must be a non-empty string, got: %s",
                    key,
                    tostring(citation.style)
                )
            )
            return
        end

        -- Validate `locale` field in `citation`
        if citation.locale ~= nil and (type(citation.locale) ~= 'string' or citation.locale == '') then
            log.error(
                string.format(
                    "Source %s: citation style 'locale' must be a non-empty string, got: %s",
                    key,
                    tostring(citation.locale)
                )
            )
            return
        end
    end
    result.citation = citation

    return result
end

---@return biblioteca.Opts
local function parse_configs(inputs)
    local merged = {}

    -- Start with an empty structure for merging
    merged.sources = {}
    merged.pickers = {}

    for _, input in ipairs(inputs) do
        if type(input) ~= 'table' then
            input = {}
        end

        -- Merge sources
        if type(input.sources) == 'table' then
            for k, v in pairs(input.sources) do
                if type(v) == 'table' then
                    local source = parse_source(k, v)
                    if source then
                        merged.sources[k] = source
                    end
                end
            end
        end

        -- Merge formatter function
        if type(input.fmt) == 'function' then
            merged.fmt = input.fmt
        end

        -- Merge cache_fmt
        if type(input.cache_fmt) == 'boolean' then
            merged.cache_fmt = input.cache_fmt
        end

        -- Merge pickers
        if type(input.pickers) == 'table' then
            for k, v in pairs(input.pickers) do
                if type(v) == 'table' then
                    merged.pickers[k] = v
                end
            end
        end
    end

    return merged
end

-- Default configuration
---@type biblioteca.Opts
local DEFAULT_CONFIG = {
    sources = {},
    fmt = function(source_id, item_key, item)
        return string.format(
            '@%s %s [%s] in [%s]',
            util.ansi_codes.red(item_key),
            item.csl_formatted_citation or '',
            util.ansi_codes.green(item.entry.type) or '',
            util.ansi_codes.green(source_id)
        )
    end,
    cache_fmt = true,
}

-- Single source of truth that returns the configuration applicable to the current
-- buffer
--
-- It parses (alla [Parse, don’t validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate))
-- the user-provided configurations (taking into account both vim.g.biblioteca and vim.b.biblioteca).
--
---@return biblioteca.Opts
function M.parse_current_config()
    return parse_configs {
        DEFAULT_CONFIG,
        vim.g.biblioteca,
        vim.b.biblioteca,
    }
end

return M
