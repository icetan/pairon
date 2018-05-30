{ pkgs ? import <nixpkgs> {} }: with pkgs;

let
  inherit (lib) cleanSource makeBinPath;
in stdenv.mkDerivation rec {
  version = "0.0.0";
  name = "pairon-${version}";
  buildInputs = [ makeWrapper ];
  src = cleanSource ./.;
  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r . $out/src
    makeWrapper $out/src/pairon $out/bin/pairon \
      --prefix PATH : ${makeBinPath [ openssh git ]}
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
    sed -i"" 's|#!/bin/sh|#!${dash}/bin/dash|' `find $out/src -type f -executable -maxdepth 1`
    runHook postFixup
  '';
}
