{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    solc.url = "github:hellwolf/solc.nix";
    utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix/monthly"; # Use monthly branch for permanent releases
  };

  outputs = { self, nixpkgs, solc, utils, foundry }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ 
            foundry.overlay
            solc.overlay  
          ];
        };
      in {

        devShell = with pkgs; mkShell {
          buildInputs = [
            # From the foundry overlay
            # Note: Can also be referenced without overlaying as: foundry.defaultPackage.${system}
            foundry-bin
            nodejs
            python3
            typescript
            node2nix
            nodePackages.ts-node
            nodePackages.pnpm

            #solc_0_8_13
            #(solc.mkDefault pkgs solc_0_8_13)

          ];

          # Decorative prompt override so we know when we're in a dev shell
          shellHook = ''
            alias test="forge test --fork-url https://mainnet.optimism.io"
          '';
        };
      });
}
