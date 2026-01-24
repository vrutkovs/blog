{
  description = "Blog";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    hugo-coder = {
        url = "github:luizdepra/hugo-coder/cb13ec4671611990420f29321c4430e928a67518";
        flake = false;
    };
    hugo-notice = {
        url = "github:martignoni/hugo-notice/7d311565755215e2d3bab57938bdbcf1194f11e4";
        flake = false;
    };
  };
  outputs = { self, nixpkgs, utils, hugo-coder, hugo-notice, ... } :
    let
        supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
        nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
        packages = forAllSystems (system:
        let
            pkgs = nixpkgsFor.${system};
            nginxPort = "8000";
            nginxConf = pkgs.writeText "nginx.conf" (builtins.replaceStrings
              [ "@nginxPort@" "@nginxPath@" "@nginxRoot@" ]
              [ nginxPort "${pkgs.nginx}" "${self.packages.${system}.default}" ]
              (builtins.readFile ./nginx.conf)
            );
        in
        {
            default = pkgs.stdenv.mkDerivation {
                name = "hugo-blog";
                src = self;
                buildInputs = [ pkgs.git ];
                configurePhase = ''
                    mkdir -p "themes/hugo-coder"
                    cp -rvf ${hugo-coder}/* "themes/hugo-coder"
                    mkdir -p "themes/hugo-notice"
                    cp -rvf ${hugo-notice}/* "themes/hugo-notice"
                '';
                buildPhase = ''
                    mkdir -p data
                    echo "git_hash_short: ${self.shortRev}" > data/git.yml
                    ${pkgs.hugo}/bin/hugo --minify
                '';
                installPhase = "gzip -k -6 $(find public -type f) && cp -r public $out && cp -r data $out";
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
