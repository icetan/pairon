{
  description = "Editor agnostic realtime pair programing with git as backend (PoC)
";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default =
        let
          pkgs = import nixpkgs { inherit system; };
        in
        import ./. { inherit pkgs; };
    });
}
