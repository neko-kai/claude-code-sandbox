{
  description = "A macOS sandbox configuration for Claude Code that restricts filesystem access";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        claude-sandbox = pkgs.stdenv.mkDerivation {
          pname = "claude-sandbox";
          version = "0.1.0";

          src = ./.;

          buildInputs = [ pkgs.bash ];

          installPhase = ''
            runHook preInstall
            PREFIX=$out bash ./install
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A macOS sandbox configuration for Claude Code";
            longDescription = ''
              A macOS sandbox-exec profile that limits Claude Code's access to your
              filesystem. It prevents Claude Code from reading your home directory
              (except for the current working directory) and restricts writes to
              only the target directory and temporary locations.
            '';
            license = licenses.mit;
            platforms = platforms.darwin;
            mainProgram = "claude-sandbox";
          };
        };
      in
      {
        packages = {
          default = claude-sandbox;
          inherit claude-sandbox;
        };

        apps.default = {
          type = "app";
          program = "${claude-sandbox}/bin/claude-sandbox";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.bash ];

          shellHook = ''
            echo "claude-code-sandbox development shell"
            echo "Run './install' to install to ~/.local/bin, or 'nix build' to build with Nix"
          '';
        };
      }
    );
}
