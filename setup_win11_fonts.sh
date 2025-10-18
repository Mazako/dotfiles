#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Pass ISO file for Windows!"
  exit 1
fi

if ! command -v 7z &>/dev/null; then
  echo "Install 7z please"
  exit 1
fi

TMPDIR=$(mktemp -d)
FONTDIR="$HOME/.local/share/fonts"

if [ ! -d "$FONTDIR" ]; then
  mkdir -p "$FONTDIR"
fi

cd "$TMPDIR"

7z e "$1" sources/install.wim
7z e install.wim 1/Windows/{Fonts/"*".{ttf,ttc},System32/Licenses/neutral/"*"/"*"/license.rtf} -ofonts/

cp -v fonts/*.ttf fonts/*.ttc "$FONTDIR" 2>/dev/null || true
fc-cache -fv "$FONTDIR"

cd ~
rm -rf "$TMPDIR"

echo "Done!"