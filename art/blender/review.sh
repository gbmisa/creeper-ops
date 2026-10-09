#!/usr/bin/env bash
# Build one creature, render its clips, write a contact sheet: art/blender/review.sh <name> <out.png>
set -e
here="$(cd "$(dirname "$0")" && pwd)"
"$here/build_all.sh" "$1"
tmp="$(mktemp -d)"
blender -b --python "$here/preview.py" -- "$here/../../godot/assets/models/$1.glb" "$tmp" 4 2>&1 | grep -E "\[preview\]|Error|Traceback"
python3 -I "$here/sheet.py" "$tmp" "$2"
rm -rf "$tmp"
