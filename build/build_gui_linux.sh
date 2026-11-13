#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
SRC_DIR="$ROOT_DIR/src"
VERSION="${GITHUB_REF_NAME#v}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"
NATIVE_ARCH="$(dpkg --print-architecture)"

mkdir -p "$DIST_DIR"

case "$TARGET_ARCH" in
  amd64|arm64)
    ;;
  *)
    echo "Unsupported TARGET_ARCH for Linux GUI build: $TARGET_ARCH" >&2
    exit 1
    ;;
esac

if [[ "$TARGET_ARCH" != "$NATIVE_ARCH" ]]; then
  echo "Linux GUI packaging requires a native $TARGET_ARCH runner, but this runner is $NATIVE_ARCH." >&2
  exit 1
fi

cd "$SRC_DIR/gui/frontend"
npm ci
npm run build

cd "$SRC_DIR"
CGO_ENABLED=1 GOARCH="$TARGET_ARCH" go build -tags desktop,production,webkit2_41 -ldflags "-s -w" \
  -o "$DIST_DIR/syncenv-gui-linux-${TARGET_ARCH}" ./gui

for arch in "$TARGET_ARCH"; do
  package_root="$ROOT_DIR/packaging/linux-${arch}"
  payload_dir="${package_root}/payload"
  deb_root="${package_root}/deb"

  rm -rf "$package_root"
  mkdir -p \
    "$payload_dir" \
    "$deb_root/DEBIAN" \
    "$deb_root/opt/syncenv" \
    "$deb_root/usr/bin" \
    "$deb_root/usr/share/applications" \
    "$deb_root/usr/share/icons/hicolor/512x512/apps"

  cp "$DIST_DIR/syncenv-gui-linux-${arch}" "$payload_dir/syncenv-gui"
  chmod 755 "$payload_dir/syncenv-gui"
  cp "$SRC_DIR/gui/build/appicon.png" "$payload_dir/syncenv-gui.png"

  cat > "$payload_dir/syncenv-gui.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=syncenv
Comment=Distributed secrets synchronization for local networks
Exec=__SYNCENV_GUI_EXEC__
Icon=__SYNCENV_GUI_ICON__
Terminal=false
Categories=Utility;Development;
Keywords=env;sync;secrets;
StartupWMClass=syncenv-gui
EOF

  cp "$payload_dir/syncenv-gui" "$deb_root/opt/syncenv/syncenv-gui"
  ln -s /opt/syncenv/syncenv-gui "$deb_root/usr/bin/syncenv-gui"
  cp "$payload_dir/syncenv-gui.png" "$deb_root/usr/share/icons/hicolor/512x512/apps/syncenv-gui.png"
  sed \
    -e 's#__SYNCENV_GUI_EXEC__#/opt/syncenv/syncenv-gui#' \
    -e 's#__SYNCENV_GUI_ICON__#syncenv-gui#' \
    "$payload_dir/syncenv-gui.desktop" > "$deb_root/usr/share/applications/syncenv-gui.desktop"

  cat > "$deb_root/DEBIAN/control" <<EOF
Package: syncenv-gui
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${arch}
Maintainer: Yuvraj Thapa <yuvraj1107thapa@users.noreply.github.com>
Depends: libgtk-3-0, libwebkit2gtk-4.1-0 | libwebkit2gtk-4.0-37
Description: syncenv desktop GUI
 Distributed secrets synchronization for local networks.
EOF

  cat > "$deb_root/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF

  cat > "$deb_root/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF

  chmod 755 "$deb_root/DEBIAN/postinst" "$deb_root/DEBIAN/postrm"

  dpkg-deb --build "$deb_root" "$DIST_DIR/syncenv-gui-linux-${arch}.deb"
done
