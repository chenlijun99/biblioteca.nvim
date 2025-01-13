default:
    @just --list --justfile {{ justfile() }}

# Build Rust library
build-rust-lib mode="debug":
    cargo build {{ if mode == "release" { "--release" } else { "" } }}
    cp ./target/{{mode}}/libbiblioteca.so ./lua/biblioteca_rust.so -f

create-release: (build-rust-lib "release")
    #!/usr/bin/env bash
    set -euxo pipefail

    tag=$(git describe --tags --exact-match 2>/dev/null || echo "")
    if [ -z "$tag" ]; then
        echo "Error: Not on a git tag. Aborting."
        exit 1
    fi

    tar czf biblioteca-linux.tar.gz ./lua/biblioteca_rust.so
    gh release create $tag ./biblioteca-linux.tar.gz --generate-notes

# Type-check Lua sources
lua-typecheck:
    lua-language-server --checklevel=Warning --logpath=./.tmp/lua-language-server/ --configpath=.luarc.json --check ./lua

# Generate Vimdoc documentation for the plugin
docgen:
    mkdir -p ./doc/
    vimcats lua/biblioteca/{init,core/init,core/config}.lua > ./doc/biblioteca.txt
