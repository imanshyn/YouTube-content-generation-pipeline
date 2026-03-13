#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR}"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"
mkdir -p ffmpeg-layer/bin

curl -sL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz -o ffmpeg.tar.xz
tar xf ffmpeg.tar.xz
mv ffmpeg-*-amd64-static/ffmpeg ffmpeg-layer/bin/
strip ffmpeg-layer/bin/ffmpeg

cd ffmpeg-layer
zip -r "$OUTPUT_DIR/ffmpeg-layer.zip" .
