{ pkgs ? import <nixpkgs> {} }: with pkgs;

let
  inherit (lib) cleanSource makeBinPath;
  inherit (stdenv) mkDerivation isLinux;
in mkDerivation rec {
  version = "0.1.1";
  name = "pairon-${version}";
  buildInputs = [ makeWrapper ];
  src = cleanSource ./.;
  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/src
    cp -r pairon* *.sh template editor-plugins $out/src
    makeWrapper $out/src/pairon $out/bin/pairon \
      --prefix PATH : ${makeBinPath [
        openssh git coreutils
        (if isLinux then inotify-tools else fswatch)
      ]}
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
    sed -i"" 's|#!/bin/sh|#!${dash}/bin/dash|' `find $out/src -type f -executable -maxdepth 1`
    runHook postFixup
  '';
}
