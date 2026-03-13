#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR/..}"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

PLATFORM_ARGS="--platform manylinux2014_x86_64 --only-binary=:all: --python-version 3.12 --implementation cp"

pip3 install -r "$SCRIPT_DIR/requirements.txt" cffi -t "$WORK_DIR/python" --quiet $PLATFORM_ARGS

cd "$WORK_DIR"
zip -r "$OUTPUT_DIR/layer.zip" python
