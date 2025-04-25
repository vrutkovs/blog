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
    let
        supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
        nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
        packages = forAllSystems (system:
        let
            pkgs = nixpkgsFor.${system};
            nginxPort = "8000";
            nginxConf = pkgs.substituteAll {
                src = ./nginx.conf;
                nginxPort = "${nginxPort}";
                nginxPath = "${pkgs.nginx}";
                nginxRoot = "${self.packages.${system}.default}";
            };
        in
        {
            default = pkgs.stdenv.mkDerivation {
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
            containerImage = pkgs.dockerTools.buildLayeredImage {
                name = "vrutkovs/blog";
                contents = [ pkgs.fakeNss pkgs.bash pkgs.coreutils pkgs.nginx "${self.packages.${system}.default}" ];
                extraCommands = ''
                  mkdir -p tmp/nginx_client_body
                  mkdir -p var/log/nginx
                '';
                config = {
                    Cmd = [
                        "nginx" "-c" "${nginxConf}"
                    ];
                    ExposedPorts = {
                        "${nginxPort}/tcp" = { };
                    };
                };
            };
        });
        apps = forAllSystems (system:
        let
            pkgs = nixpkgsFor.${system};
        in
        {
            build = utils.lib.mkApp { drv = pkgs.hugo; };
            default = utils.lib.mkApp {
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
        });
        devShells = forAllSystems (system:
        let
            pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = [ pkgs.hugo ];
            shellHook = ''
                mkdir -p themes
                ln -sn "${hugo-coder}" "themes/hugo-coder"
                ln -sn "${hugo-notice}" "themes/hugo-notice"
            '';
          };
        });
    };
}
