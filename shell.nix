{ pkgs ? import <nixpkgs> {} }:

let
  sbclWithDeps = pkgs.sbcl.withPackages (ps: [
    ps.fiveam
  ]);
in
pkgs.mkShell {
  buildInputs = [ sbclWithDeps pkgs.gcc ];
}
