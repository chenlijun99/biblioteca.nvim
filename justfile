default:
    @just --list --justfile {{ justfile() }}

# Build Rust library
build-rust-lib mode="debug":
    cargo build {{ if mode == "release" { "--release" } else { "" } }}
    ln -s ../target/{{mode}}/libbiblioteca.so ./lua/biblioteca_rust.so -f

# Type-check Lua sources
lua-typecheck:
    lua-language-server --checklevel=Warning --logpath=./.tmp/lua-language-server/ --configpath=.luarc.json --check ./lua

# Generate Vimdoc documentation for the plugin
docgen:
    mkdir -p ./doc/
    vimcats lua/biblioteca/{init,core/init,core/config}.lua > ./doc/biblioteca.txt
