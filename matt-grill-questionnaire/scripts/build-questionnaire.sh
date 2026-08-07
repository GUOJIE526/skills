#!/bin/sh
# Build a Matt grill questionnaire from a JSON payload.
# Usage: sh scripts/build-questionnaire.sh <payload.json> [out.html]
#
# This script only splices text: it never validates the payload and never opens a
# browser. Payload rules live in the renderer, opening lives with the agent.
# See docs/adr/0001-only-out-of-the-box-runtimes.md.
set -e

DATA="$1"
OUT="$2"
[ -n "$DATA" ] || { echo "usage: build-questionnaire.sh <payload.json> [out.html]" >&2; exit 1; }
[ -f "$DATA" ] || { echo "payload not found: $DATA" >&2; exit 1; }

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$DIR/../assets/questionnaire-template.html"

if [ -z "$OUT" ]; then
  # The PID stops two builds in the same second from overwriting each other, and
  # unlike a millisecond stamp it cannot collide at all: one build is one process.
  # The PowerShell script names its files exactly the same way.
  OUT="${TMPDIR:-/tmp}/grill-questionnaire-$(date +%Y%m%d-%H%M%S)-$$.html"
fi

# In valid JSON '<' can only occur inside a string, so replacing every one of them
# is safe and stops the payload from closing the <script> element early.
if ! awk -v datafile="$DATA" '
  # Built with split/concat rather than gsub: awk implementations disagree on how
  # many backslashes a gsub replacement needs, and getting it wrong emits a doubled
  # backslash, which JSON.parse then reads as literal text instead of "<".
  # 92 is a backslash; sprintf keeps the escape unambiguous.
  BEGIN { BS = sprintf("%c", 92) }
  function escape(text,   parts, count, i, out) {
    count = split(text, parts, "<")
    out = parts[1]
    for (i = 2; i <= count; i++) out = out BS "u003c" parts[i]
    return out
  }
  state == 0 && /<script id="questionnaire-data"/ {
    print
    while ((getline line < datafile) > 0) { print escape(line); lines++ }
    close(datafile)
    state = 1
    next
  }
  state == 1 { if ($0 ~ /<\/script>/) { print; state = 2 } ; next }
  { print }
  END { if (state != 2 || lines == 0) exit 3 }
' "$TEMPLATE" > "$OUT"; then
  rm -f "$OUT"
  echo "build failed: template marker missing, or payload empty/unreadable" >&2
  exit 1
fi

echo "$OUT"

# The path goes out before the launcher runs, and a launcher that fails must not
# change the exit status: the file is already built and its path is what matters.
if command -v open >/dev/null 2>&1; then
  open "$OUT" || echo "could not open a browser; the path above is ready to use" >&2
fi
