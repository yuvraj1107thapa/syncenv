#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
GUI_DIR="$ROOT_DIR/src/gui"

mkdir -p "$DIST_DIR"

cd "$GUI_DIR"

for arch in amd64 arm64; do
  rm -rf build/bin
  PATH="$HOME/go/bin:$PATH" \
  CGO_ENABLED=1 \
  CGO_LDFLAGS="-framework UniformTypeIdentifiers" \
  wails build -clean -platform "darwin/${arch}"

  install -m 755 \
    "build/bin/syncenv.app/Contents/MacOS/syncenv-gui" \
    "$DIST_DIR/syncenv-gui-macos-${arch}"

  stage_dir="$(mktemp -d)"
  cp -R build/bin/syncenv.app "$stage_dir/syncenv.app"
  hdiutil create \
    -volname "syncenv" \
    -srcfolder "$stage_dir" \
    -ov \
    -format UDZO \
    "$DIST_DIR/syncenv-gui-macos-${arch}.dmg"
  rm -rf "$stage_dir"
done
