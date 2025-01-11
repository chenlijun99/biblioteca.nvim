# ADR: CLI design

Along the Rust library, I'm also developing a CLI, mainly for debugging purposes.

## Argument parsing

I'm using the `clap` crate.

Should I use the derive API or the builder API?

1. Derive API
    * ✅ Low boilerplate.
    * ❌ I "pollute" structs in `lib.rs` with stuff that concerns only `main.rs`.
        * Is this something common in the Rust community or is it frowned upon?
        * If it's a matter of code size (which actually doesn't matter for my application), then I could use feature flags to enable the `crate` macros only if `lib.rs` is being built for `rlib` and the `cli` feature is enabled.
2. Builder API
    * ❌ High boilerplate

Conclusion: use approach 2. The boilerplate is really too much...
