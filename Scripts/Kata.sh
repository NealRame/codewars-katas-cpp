#! /usr/bin/env bash

# stop script with non-zero exit code if anything go wrong
set -e

# stop script with non-zero exit code when trying to reference an undefined
# variable
set -u

# If any command in a pipeline fails, that return code will be used as the
# return code of the whole pipeline
set -o pipefail

SOURCES_DIR="${SOURCES_DIR:-$PWD}"
KATA_NAME="${1// }"

KATAS_DIR="$SOURCES_DIR/Katas"
KATA_CPP="$KATAS_DIR/${KATA_NAME}.cpp"
KATA_LST="$SOURCES_DIR/.katas"

mkdir -p "$KATAS_DIR"
[ -f "$KATA_CPP" ] || cat > "$KATA_CPP" <<EOF
// begin of kata --------------------------------------------------------------

// end of kata ✄ --------------------------------------------------------------

#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>

TEST_CASE( "Kata: " "$KATA_NAME" ) {
    // Put your tests below
}

EOF

touch "$KATA_LST"
grep -q "$KATA_NAME" "$KATA_LST" || echo "$KATA_NAME" >> "$KATA_LST"
