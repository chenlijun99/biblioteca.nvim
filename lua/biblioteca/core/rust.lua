---@mod biblioteca.core.rust
---
---@brief [[
---
---Rust functions used by this plugin
---
---@brief ]]
---
---We expect biblioteca_rust.so to be located in `<project_root>/lua/`.
---
---
---@class biblioteca.CitationItem
---@field entry table Contains fields of the citation item. Varies depending on the source type.
---@field csl_formatted_citation string? The citation item, formatted according to the specified CSL style and locale (if any).

local rust = require('biblioteca_rust')
return rust
