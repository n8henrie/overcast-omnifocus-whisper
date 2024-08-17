# overcast-omnifocus-whisper

This is a hodgepodge of scripts that work together to:
- create an OmniFocus task with a timestamped link to the currently playing Overcast track as the note
- filter OmniFocus for tasks with these Overcast links at the beginning of the note
- make a request that uses this link to download the underlying audio file
- converts the file with ffmpeg to a whisper-compatible format
- uses a rust-based whisper implementation to transcribe the audio file
- replaces the task note with this transcription

The idea is that I can:
- set this script to run in a cron job
- use my `overcast bookmark` iOS shortcut when I am on the go and hear an
  interesting podcast segment
- some time later return to find a timestamped transcription of the podcast in
  the task note to figure out what I thought was so interesting at the time

The parts of script:
- My iOS shortcut is available at [https://www.icloud.com/shortcuts/24cf4a7790fe4cdca3a8ca0eeeb9e462](); I'm not sure if there is a way to include its source contents
- `whisper` is from [https://github.com/huggingface/candle](), compiled with a few features to make it a little faster
- `run.sh` accepts an OmniFocus task ID and Overcast URL to:
  - downloads the audio file
  - convert with ffmpeg
  - performs the transcription with `whisper`
  - copy the transcript to stdout
- `overcast-omnifocus-whisper.js` is the primary entrypoint, a JXA script that contains an embedded OmniFocus Automation script to:
  - retrieve tasks that contain an Overcast URL in the note
  - run `run.sh` and collect the output
  - overwrite the task note with a note that contains the transcript

nix (+ flake) users should be able to run all of this machinery with minimal effort: `nix run github:n8henrie/overcast-omnifocus-whisper`
