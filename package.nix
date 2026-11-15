{
  lib,
  writeShellApplication,
  makeBinaryWrapper,
  runCommandLocal,
  curl,
  ffmpeg-headless,
  libxml2,
  cacert,
  whisper,
}:
let
  name = "overcast-omnifocus-whisper";
  script = writeShellApplication {
    inherit name;
    runtimeInputs = [
      curl
      ffmpeg-headless
      libxml2
      cacert
      whisper
    ];
    text = "${./overcast-omnifocus-whisper.js} ${./transcribe.sh}";
  };
in
# Useless wrapping so I can set MacOS privacy prefs on a binary
runCommandLocal name
  {
    nativeBuildInputs = [ makeBinaryWrapper ];
    meta.mainProgram = name;
  }
  ''
    mkdir -p $out/bin
    cp ${lib.getExe script} $out/bin
    wrapProgram $out/bin/${name}
  ''
