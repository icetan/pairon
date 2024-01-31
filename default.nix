{ pkgs ? import <nixpkgs> {} }: with pkgs;

let
  inherit (lib) cleanSource makeBinPath;
  inherit (stdenv) mkDerivation isLinux;
  runtimePaths = makeBinPath [
    openssh git coreutils findutils
    (if isLinux then inotify-tools else fswatch)
  ];
in mkDerivation rec {
  version = "0.2.0";
  name = "pairon-${version}";
  buildInputs = [ makeWrapper ];
  src = cleanSource ./.;
  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r -t $out bin lib libexec template editor-plugins
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
    sed -i"" '2iexport PATH="${runtimePaths}:$PATH"' $out/bin/pairon
    sed -i"" 's|#!/bin/sh|#!${dash}/bin/dash|' $out/bin/* $out/libexec/*
    runHook postFixup
  '';
}
