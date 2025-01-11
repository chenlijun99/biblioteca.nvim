# ADR: Citation item format

* We need to have a citation item format that contains enough useful information for Neovim users.
    * E.g. personally, given a citation key, I want to get at least the title and the type of the citation item as I need to fill them in my literature note.
* I'm aware of:
    * Bibtex and Biblatex
    * [CFF (Citation File Format)](https://citation-file-format.github.io/)
    * [CSL-JSON](https://citeproc-js.readthedocs.io/en/latest/csl-json/markup.html)
    * [hayagriva](https://github.com/typst/hayagriva/blob/main/docs/file-format.md)
* Should I study them and try to find a common denominator? Well... history teaches us: https://xkcd.com/927/.
* A minimal common denominator that satisfies my needs is certainly possible, after all I only need title and citation item type. But what if users start requesting additional fields. Slowing, we'll end up with a citation format that tries to be a common denominator between the various citation formats, with most fields marked as optional because they are supported only in some of all the formats.
* Conclusion: just entirely expose whatever the underlying Rust library that I use to parse bibliography sources exposes.
    * => Breaking changes in the Rust library will also be breaking change for the plugin. Admittedly not very elegant, but I don't want to do the dirty work of maintaining a citation format compatibility layer. Let's push this to the users :).
    * Possible use-case: an Neovim user may not care about specific fields. They just wants all fields, as many as described in the original bibliography source.
