#!/usr/bin/env bash
# Build one 3-part weapon and contact-sheet the assembled preview: art/blender/wreview.sh <name> <out.png>
set -e
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
PREVIEW="$tmp/full.glb" "$here/build_all.sh" "$1"
mkdir "$tmp/f"
blender -b --python "$here/preview.py" -- "$tmp/full.glb" "$tmp/f" 4 2>&1 | grep -E "\[preview\]|Error|Traceback"
python3 -I "$here/sheet.py" "$tmp/f" "$2"
rm -rf "$tmp"
