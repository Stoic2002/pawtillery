#!/usr/bin/env bash
# Local CI: codegen, static analysis, tests. Fails on the first error.
# Uses $FLUTTER if set, else `flutter` on PATH, else the fvm 3.41.7 install.
set -euo pipefail
cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-$(command -v flutter || echo "$HOME/fvm/versions/3.41.7/bin/flutter")}"
"$FLUTTER" pub get
"$FLUTTER" gen-l10n
"$FLUTTER" analyze --fatal-infos
"$FLUTTER" test
