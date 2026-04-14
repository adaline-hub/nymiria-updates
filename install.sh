#!/usr/bin/env sh
# Nymiria Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/adaline-hub/nymiria-updates/main/install.sh | sh

set -e

VERSION="1.0.6"
REPO="adaline-hub/nymiria-updates"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "Nymiria v${VERSION} Installer"
echo "Detected: ${OS} / ${ARCH}"
echo ""

install_macos() {
  if [ "$ARCH" != "arm64" ]; then
    echo "Error: macOS installer currently supports Apple Silicon (M1/M2/M3) only."
    echo "Intel Mac support is coming in a future release."
    echo ""
    echo "For Homebrew users (Apple Silicon):"
    echo "  brew tap adaline-hub/nymiria"
    echo "  brew install --cask nymiria"
    exit 1
  fi

  DMG="Nymiria_${VERSION}_aarch64.dmg"
  URL="${BASE_URL}/${DMG}"
  TMPDIR="$(mktemp -d)"
  DEST="${TMPDIR}/${DMG}"

  echo "Downloading ${DMG}..."
  curl -L --progress-bar "${URL}" -o "${DEST}"

  echo "Mounting disk image..."
  MOUNT="$(hdiutil attach "${DEST}" -nobrowse -quiet | tail -1 | awk '{print $NF}')"

  echo "Installing Nymiria.app to /Applications..."
  cp -R "${MOUNT}/Nymiria.app" /Applications/

  echo "Unmounting..."
  hdiutil detach "${MOUNT}" -quiet

  rm -rf "${TMPDIR}"

  echo ""
  echo "Nymiria installed successfully."
  echo "Open it from /Applications/Nymiria.app"
  echo ""
  echo "Note: On first launch, macOS may show a security warning."
  echo "If so: System Settings → Privacy & Security → Open Anyway"
}

install_linux_deb() {
  DEB="Nymiria_${VERSION}_amd64.deb"
  URL="${BASE_URL}/${DEB}"
  TMPDIR="$(mktemp -d)"
  DEST="${TMPDIR}/${DEB}"

  echo "Downloading ${DEB}..."
  curl -L --progress-bar "${URL}" -o "${DEST}"

  echo "Installing via dpkg (requires sudo)..."
  sudo dpkg -i "${DEST}"

  rm -rf "${TMPDIR}"

  echo ""
  echo "Nymiria installed. Run: nymiria"
}

install_linux_appimage() {
  APPIMAGE="Nymiria_${VERSION}_amd64.AppImage"
  URL="${BASE_URL}/${APPIMAGE}"
  DEST="${HOME}/.local/bin/nymiria"

  mkdir -p "${HOME}/.local/bin"

  echo "Downloading ${APPIMAGE}..."
  curl -L --progress-bar "${URL}" -o "${DEST}"
  chmod +x "${DEST}"

  echo ""
  echo "Nymiria installed to ${DEST}"
  echo "Make sure ~/.local/bin is in your PATH, then run: nymiria"
}

install_linux() {
  if [ "$ARCH" != "x86_64" ]; then
    echo "Error: Linux installer supports x86_64 only at this time."
    exit 1
  fi

  # Prefer .deb if dpkg is available
  if command -v dpkg >/dev/null 2>&1; then
    install_linux_deb
  else
    echo "dpkg not found — installing as AppImage..."
    install_linux_appimage
  fi
}

case "$OS" in
  Darwin)  install_macos ;;
  Linux)   install_linux ;;
  *)
    echo "Unsupported OS: ${OS}"
    echo "Download manually: https://github.com/${REPO}/releases/latest"
    exit 1
    ;;
esac
