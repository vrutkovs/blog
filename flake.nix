{
  description = "Blog";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    hugo-coder = {
        url = "github:luizdepra/hugo-coder";
        flake = false;
    };
    hugo-notice = {
        url = "github:martignoni/hugo-notice";
        flake = false;
    };
  };
  outputs = { self, nixpkgs, utils, hugo-coder, hugo-notice, ... }:
  utils.lib.eachDefaultSystem
    (system:
    let
        pkgs = import nixpkgs {
        inherit system;
        };
    in
    {
        packages.hugo-blog = pkgs.stdenv.mkDerivation rec {
            name = "hugo-blog";
            src = self;
            configurePhase = ''
                mkdir -p "themes/hugo-coder"
                cp -rvf ${hugo-coder}/* "themes/hugo-coder"
                mkdir -p "themes/hugo-notice"
                cp -rvf ${hugo-notice}/* "themes/hugo-notice"
            '';
            buildPhase = ''
                ${pkgs.hugo}/bin/hugo --minify
            '';
            installPhase = "cp -r public $out";
        };
        packages.default = self.packages.${system}.hugo-blog;

        apps = rec {
        build = utils.lib.mkApp { drv = pkgs.hugo; };
        serve = utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "hugo-serve" ''
                mkdir -p themes
                ln -sn "${hugo-coder}" "themes/hugo-coder"
                ln -sn "${hugo-notice}" "themes/hugo-notice"
                ${pkgs.hugo}/bin/hugo serve
            '';
        };
        newpost = utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "new-post" ''
                ${pkgs.hugo}/bin/hugo new content posts/"$1".md
            '';
        };
        default = serve;
        };

        devShells.default =
        pkgs.mkShell {
            buildInputs = [ pkgs.hugo ];
            shellHook = ''
                mkdir -p themes
                ln -sn "${hugo-coder}" "themes/hugo-coder"
                ln -sn "${hugo-notice}" "themes/hugo-notice"
            '';
        };
    });
}
