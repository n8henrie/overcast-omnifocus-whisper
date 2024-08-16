{
  rustPlatform,
  fetchFromGitHub,
  darwin,
  stdenv,
  lib,
}:
let
  pname = "whisper";
in
rustPlatform.buildRustPackage {
  inherit pname;
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "candle";
    rev = "69fdcfe96ac05213b3b166140774f38a99de0b54";
    hash = "sha256-tAaca3dxYZmUWvCj9hxmkCOyxc1Fd7hnL+LZrZGkQww=";
  };
  cargoLock.lockFile = ./Cargo.lock;
  buildAndTestSubdir = "candle-examples";
  buildFeatures = lib.optionals stdenv.isDarwin [
    "accelerate"
    "metal"
    "symphonia"
  ];
  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';
  cargoBuildFlags = [ "--example whisper" ];
  buildInputs = lib.optionals stdenv.isDarwin (
    with darwin.apple_sdk.frameworks;
    [
      Accelerate
      Metal
      MetalPerformanceShaders
      Security
    ]
  );
  postInstall =
    let
      cargoTarget = rustPlatform.cargoInstallHook.targetSubdirectory;
    in
    ''
      install -D target/${cargoTarget}/release/examples/${pname} $out/bin/${pname}
    '';

}
