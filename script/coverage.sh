#!/bin/sh
# Generate test coverage statistics for Go packages.
#
# Works around the fact that `go test -coverprofile` currently does not work
# with multiple packages, see https://code.google.com/p/go/issues/detail?id=6909
#
# Usage: script/coverage [--html]
#
#     --html  Additionally create HTML report and open it in browser
#
[ -z "$COVER" ] && COVER=.cover
profile="$COVER/cover.out"
mode=count

generate_cover_data() {
  [ -d "${COVER}" ] && rm -rf "${COVER}/*"
  [ -d "${COVER}" ] || mkdir -p "${COVER}"
  glide install

  for pkg in "$@"; do
    f="${COVER}/$(echo $pkg | tr / -).cover"
    tf="${COVER}/$(echo $pkg | tr / -)_tests.xml"
    go test -v -covermode="$mode" -coverprofile="$f" "$pkg" | go-junit-report > "$tf"
  done

  echo "mode: $mode" >"$profile"
  grep -h -v "^mode:" "${COVER}"/*.cover >>"$profile"
}

show_cover_report() {
  go tool cover -${1}="$profile" -o "${COVER}/coverage.html"
}

push_to_coveralls() {
  if [ -z "$COVERALLS_TOKEN" ]; then
    echo "Need to set COVERALLS_TOKEN environment variable"; exit 1
  fi
  echo "Pushing coverage statistics to coveralls.io"
  goveralls -coverprofile="$profile" -service=circle-ci -repotoken=$COVERALLS_TOKEN
}

generate_cover_data $(go list ./... | grep -v vendor)

case "$1" in
  "")
    ;;
  --html)
    show_cover_report html ;;
  --coveralls)
    push_to_coveralls ;;
  --help)
    echo >&2 "usage: $0 --coveralls|--html"; exit 0 ;;
  *)
    echo >&2 "error: invalid option: $1"; exit 1 ;;
esac
