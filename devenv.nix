{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    just
    vimcats
    # TOML formatter
    taplo
    # Markdown linter & formatter
    markdownlint-cli2
    rustfmt
    clippy
    gh
    gnutar
  ];

  # https://devenv.sh/languages/
  languages.rust = {
    enable = true;
  };
  languages.lua.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    hello
    git --version
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks = {
    #docgen = {
    #enable = true;
    #name = "docgen";
    #entry = "just docgen";
    #files = "\\.(lua)$";
    #pass_filenames = false;
    #};
    lua-typecheck = {
      enable = true;
      name = "lua-typecheck";
      entry = "just lua-typecheck";
      files = "\\.(lua)$";
      pass_filenames = false;
    };
    rustfmt.enable = true;
    clippy.enable = true;
  };

  # See full reference at https://devenv.sh/reference/options/
  # Use Nixpkgs official cache
  cachix.enable = false;
}
