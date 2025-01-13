# biblioteca.nvim

>[!WARNING]
>
> Project status: Alpha.

biblioteca.nvim is primarily a Neovim plugin for managing citation data. However, the heavy-lifting is implemented in Rust, which is provided both as library and CLI which and can be used independently.

## Features

* Supported bibliography sources: biblatex, bibtex,, CSL-JSON.
* Fuzzy finder sources: fzf.vim, fzf.lua, telescope, vim.ui.select.
    * Configurable fuzzy finder actions
    * Buffer local citations
* nvim-cmp source
* Lua API to work with citation entries.

## Prerequisites

### Required

* `neovim >= 0.10`

### Optional

* [`cargo`](https://doc.rust-lang.org/cargo/),
  required to manually build the Rust library.

## Installation

### [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
{
  'chenlijun99/biblioteca',
  build = "./install.sh",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
    "ibhagwan/fzf-lua",              -- optional
    "L3MON4D3/LuaSnip",              -- optional
  },
  version = '^1', -- Recommended
  lazy = false, -- This plugin is already lazy
}
```

> [!TIP]
>
> It is suggested to pin to tagged releases if you would like to avoid breaking changes.

> [!TIP]
>
> See [`:h biblioteca`](./doc/biblioteca.txt) for a detailed documentation of everything.

## Quick start

### Setup and configuration

```lua
vim.g.biblioteca = {
    sources = {
        my_source_id = {
            type = "biblatex",
            file = "/path/to/file.bib"
            citation_style = {
                style = "ieee",
                locale = "en_US"
            },
        },
        -- ...
    },
    fmt = function(source_id, item_key, item, csl_formatted)
        return "[item_key] {item.shorttitle} {formatted} [source_id]"
    end,
    cache_fmt = true,
    pickers = {
        fzf_vim = {
            -- ...
        },
        fzf_lua = {
            -- ...
        },
        telescope = {
            -- ...
        }
    }
}

require('biblioteca').setup()
-- For integration with L3MON4D3/LuaSnip
require('biblioteca.integrations.luasnip').setup({

})
```

To modify the default configuration, set `vim.g.biblioteca`.

## Usage

```lua
require('biblioteca.pickers.fzf_lua').bibliography()
require('biblioteca.pickers.fzf_vim').bibliography()
require('biblioteca').get_citation_data(<citation key>)
```

## Troubleshooting

### Health checks

For a health check, run `:checkhealth biblioteca`

## Credits

* [obsidian-citation-plugin](https://github.com/hans/obsidian-citation-plugin): source of inspiration. I wanted to rely less on Obsidian.
* [ColinKennedy/nvim-best-practices-plugin-template](https://github.com/ColinKennedy/nvim-best-practices-plugin-template) and [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices): for best practices.
* [Loading a Rust library as a Lua module in Neovim](https://kdheepak.com/blog/loading-a-rust-library-as-a-lua-module-in-neovim/): got me started on Lua-Rust interoperability.
* Examples of good Neovim plugins I took inspiration from:
    * [NeogitOrg/neogit](https://github.com/NeogitOrg/neogit): a nice example showing how a single plugin can support multiple pickers.
    * [mrcjkb/rustaceanvim](https://github.com/mrcjkb/rustaceanvim)
* Of course, credits goes to all the dependencies this repository relies on.

## Related projects

* [rafaqz/citation.vim](https://github.com/rafaqz/citation.vim):
    * Supports bibtex files (via pybtex) and directly reading from the Zotero Sqlite database.
    * Provides Unite.vim sources for citations.
    * Implemented in VimScript.
* [ferdinandyb/bibtexcite.vim](https://github.com/ferdinandyb/bibtexcite.vim)
    * Relies on [bibtool](https://ctan.org/pkg/bibtool) and [fzf-bibtex](https://github.com/msprev/fzf-bibtex).
    * Provides FZF source for citations.
    * Implemented in VimScript.
* [fzf-bibtex](https://github.com/msprev/fzf-bibtex)
    * Documents how to integrate with fzf.vim and fzf.lua. Basically, read from the output cache of the `fzf-bibtex` CLI tool.
* [jalvesaq/zotcite](https://github.com/jalvesaq/zotcite)
    * Supports Zotero. Directly reads from the Zotero sqlite database.
    * Doesn't support bibtex.
    * Provides FZF source for Zotero citations, annotations, etc.
    * Implemented in Lua and Python.

 What is missing?

* Given a citation key, obtain a table containing the data about the citation entry and perform arbitrary operation with the data. E.g. open a literature note, expand a template and fill citation entry data automatically, etc.
* Lack support for arbitrary citation styles.
