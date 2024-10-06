set -Eeuf -o pipefail

trap 'rm -f "${outfile}" "${id}.sound" "${id}.sound.converted"' EXIT

# global for use in trap
readonly id=${1:-} url=${2:-}
readonly outfile=${id}.txt

main() {
  local outpath
  outpath=$(mktemp -d)
  cd "${outpath}"

  if [[ -s "${id}.txt" ]]; then
    cat "${outfile}"
    exit
  fi

  source=$(
    curl --location "${url}" |
      xmllint --html --xpath '//audio/source/@src' - 2> /dev/null |
      awk -F'"' '{ print $2 }'
  )

  if [[ ! -s "${id}.sound" ]]; then
    local tmpfile
    tmpfile=$(mktemp)
    curl --location -o "${tmpfile}" "${source}" &&
      mv "${tmpfile}" "${id}.sound"
  fi

  if [[ ! -s "${id}.sound.converted" ]]; then
    ffmpeg -i "${id}.sound" -ar 16000 -f mp3 "${id}.sound.converted"
  fi

  whisper --input "${id}.sound.converted" > "${outfile}"

  # If success, return output to calling script, stripping first 2 lines
  # which are unrelated output (`pcm data loaded`)
  tail -n+3 "${outfile}"
}
main "$@"
