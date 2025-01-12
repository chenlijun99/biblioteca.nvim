# ADR: Who does what

I.e. responsibility separation between Lua and Rust.

* Parsing large biblatex files may take quite a bit of time (a few seconds).
    * => Multithreading is needed to avoid blocking the UI.
    * => Caching is needed.

## Multithreading

Following choices and sub-choices have been identified:

1. Rust does multithreading.
    * ❌ Further complexity by having to expose async Lua API.
    * No real benefits
2. Lua does multithreading.
    1. Using `:help lua-loop-threading`.
    2. Using `:help luv-thread-pool-work-scheduling`.

Conclusion: use approach 2.2.

## Caching

### Persistent caching?

1. Yes
    * ✅ Efficiency.
      * How much does loading cache from FS cost?
      * Considering
    * ❌ Further complexity
2. No
    * ✅ Simplicity
    * ❌ First use will be slow, unless we compute everything eagerly (in background) upon start. But users may want to lazy load the plugin itself.

Conclusion: approach 1.

### Cache what?

1. Lua tables. By loading a Lua file that contains the table.
    * ❌ Hmm, doesn't feel secure.
2. JSON
    * How much time does loading a potentially large JSON file with `:help vim.json.decode` take?
        * I don't think it's relevant. I think it will be faster than the Lua interpreter parsing the Lua table.
    * ✅ Maybe can keep the whole parsed results out of RAM and use something like `jq` to feed results to pickers. Especially relevant for `fzf.vim` picker.
3. Sqlite
    * ✅ Good time to learn Sqlite.
    * ❌❌ One more dependency

* Consideration about JSON
    * Neovim uses [`lua-cjson`](https://github.com/mpx/lua-cjson) for `vim.json`.
    * From Neovim source code: `lua_cjson.c`.

    > Note: Decoding is slower than encoding. Lua spends significant
    > time (30%) managing tables when parsing JSON since it is
    > difficult to know object/array sizes ahead of time.

Conclusion: approach 2.

### Who does the caching

1. Rust takes care of caching.
    * ❌ Ideally, the more dumb, stateless, side-effect-free, I/O free the Rust code is, the better.
        * 😑 But for performance, I pass only the sources info from Lua to Rust, instead of the source contents. Rust then reads from the sources (e.g. FS).
    * ✅ Since Rust already has to read the sources by itself, it can also determine whether the cache is up-to-date.
    * ✅ In case I want to use the Rust crate for something else in the future, having caching built-makes it reusable.
    * ✅ Neovim uses `:help vim.json` from JSON. We could use faster JSON crates for encoding the results in JSON.
        * Also, more flexible JSON crates where we don't need to read the whole JSON file to determine whether it is up-to-date.
2. Rust returns the parsed results to Lua. Lua takes care of caching.
    * ❌ Nope. As one can expect, cannot share Lua tables among threads.
        * Well, the Lua worker thread could do everything that the Rust code does.
    * ❌❌ What about atomicity? E.g. in case of multiple Neovim instances. There are Rust libraries for that, but on Lua I don't what to deal with that.
    * ✅ Elegant. Rust code is closer to dumb computation functions.

Conclusion: approach 1.

### What and how does the Rust code return results to the Lua code?

1. Rust returns path to processed result. Lua reads it back from FS.
    1. Lua specifies the destination file
        * => No need to have source id at Rust level. Rust only checks that destination file is up-to-date.
        * ✅ More natural to also make the Rust code output to elsewhere. Easier testing.
    2. Rust specifies the destination file
        * ❌ Ideally the library should not control where things are stored.
    * ❌ If using FS for data exchange, what about concurrency and atomicity? While on Rust we could use crates to atomically write to FS (using atomic `rename`), what about reading a file that is then overwritten by an `rename`? Probably, as long as we have the file handle, the file content are still kept by the FS, at least in Linux.
        * But is it portable? Apparently no. On windows we need to specify `FILE_SHARE_DELETE`.   Apparently, by default libuv's FS API uses it to keep the Unix semantics. So, I guess that's not a problem.
2. Rust fills and returns the Lua table.
    * ❌❌ Nope. As one can expect, cannot share Lua tables among threads.
    * ✅ Could use faster JSON decoding functions.
    * ✅ Elegant. Lua code doesn't need to care about caching.
    * ❓ Is filling table from Rust via `mlua` faster/slower than filling it using `vim.json`?
        * ✅ In Rust, once we have decoded the JSON, we already know the size of stuff and could create Lua tables more efficiently.
3. Rust returns the serialized JSON string.
    * ✅ Elegant. Lua code doesn't need to care about Rust-side caching.
        * ❌ Okay, if we want to avoid this unnecessary string copying, etc. still need to be aware of Rust-side caching.

* Overall considerations:
    * Leaky abstraction. The higher level is the knowledge about caching, the better for performance.
    * 🔍 FS only for caching vs also as part of Rust/Lua interface depends also on the pickers. If it is better to implement picker sources by reading from file vs by reading from in-memory Lua table.
        * Looking at both fzf.vim and fzf.lua, the conclusion is that we need to keep the entries in memory to be ready to give information about a specific entry. Also, in case we want to support something like `nvim-cmp`.
            * For fzf-lua the table alone is likely sufficient, we can use Lua coroutine to push values to fzf-lua.
            * For fzf.vim we need to first convert the table into a Vimscript array of strings and then feed to fzf.vim. => It would be better to directly feed from file.

Conclusion: approach 1.1. Since it would be better to feed from file. but I would like to also allow users to provide Lua function to format citation entries as they please, so the Lua side will also write to a file the properly formatted output that can be directly feed to pickers.

* Q: how to pass user-provided functions to Lua worker thread?
  A: Can't. => Will have to be done in the main-threading, in a chunked non-blocking way.
* Q: Lua is writing to file... What about atomicity?
  A: Implement atomic rename trick.
* Q: But... the user-provided Lua function could be impure, which makes caching to file harder/the wrong thing to do.
  A: Allow user to specify whether function is pure/when to invalidate the result. I honestly don't see a reason why they would want to pass impure functions. I expose a function interface just because I'm too lazy to implement a small template DSL.

### How does cache invalidation happen?

1. Eagerly, via file watching.
    * ✅ Better user experience.
    * ❌ More code to write in Lua for file watching. I don't think doing file watching in Rust is a good idea.
2. Lazy, on each read from source, check if cache up-to-date.
    * ✅ In my experience, citation sources don't change so frequently.

Conclusion: approach 2.

### Crates for caching in Rust

* [`cached`](https://github.com/jaemk/cached)
    * Disk cache uses [sled](https://github.com/spacejam/sled), which doesn't support multiple open instances. Deal-breaker, since biblioteca.nvim must be usable from multiple Neovim instances.
* [`cacache`](https://github.com/zkat/cacache-rs)
    * The API is a bit more manual, but so far works pretty well.

## End-result

How biblioteca.nvim as Neovim plugin could work:

1. User requests citation data
2. Main-thread Lua calls Rust library to check whether the result is still up-to-date.
3. If not, main-thread Lua spawns worker-thread Lua and clears any cached data.
4. In the meantime, main-thread Lua can already start the picker. E.g. `require 'fzf-lua'.fzf_exec`, using shell command as input. Where the shell command is `tail -f <tmp_output_file>`. `tmp_output_file` will be filled.
5. Worker-thread Lua calls Rust library to process the sources and output them to a certain path.
6. Main-thread Lua loads the processed JSON result.
7. Main-thread Lua starts to process each entry according to user function and write to `tmp_output_file`.
8. `tmp_output_file` is renamed to a cached file and may be re-used the next time in case no invalidation happens.

How people could use the Rust CLI tool:

1. `biblioteca --cached <source> <csl_style> ... | jq ... | fzf`.

So, our Neovim plugin mainly features caching of the later output formatting stage. Though, I have the suspicion it isn't really necessary. I mean, typically a few string concatenation repeated for maximum tens of thousands of entries.
