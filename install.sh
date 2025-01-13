#!/usr/bin/env bash
# Credits: mostly copied from https://github.com/krivahtoo/silicon.nvim/tree/main

set -e

# get current version from Cargo.toml
get_version() {
  cat Cargo.toml | grep '^version =' | sed -E 's/.*"([^"]+)".*/\1/'
}

# compile from source
build() {
  echo "Building biblioteca.nvim from source..."

  cargo build --release

  if [ "$(uname)" == "Darwin" ]; then
    mv target/release/libbiblioteca.dylib lua/biblioteca_rust.so
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    mv target/release/libbiblioteca.so.so lua/biblioteca_rust.so
  elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    mv target/release/biblioteca.so.dll lua/biblioteca_rust.dll
  fi
}

# download the biblioteca.nvim (of the specified version) from Releases
download() {
  echo "Downloading biblioteca.nvim library: " $1
  if [ "$(uname)" == "Darwin" ]; then
    arch_name="$(uname -m)"
    curl -fsSL https://github.com/chenlijun99/biblioteca.nvim/releases/download/$1/biblioteca-mac-${arch_name}.tar.gz | tar -xz
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    curl -fsSL https://github.com/chenlijun99/biblioteca.nvim/releases/download/$1/biblioteca-linux.tar.gz | tar -xz
  elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # curl -fsSL https://github.com/chenlijun99/biblioteca.nvim/releases/download/$1/biblioteca-win.zip --output biblioteca-win.zip
    # unzip biblioteca-win.zip
    echo "Windows build is not available yet."

    build
  fi
}

case "$1" in
  build)
    build
    ;;
  *)
    version="v$(get_version)"
    download $version

    ;;
esac
