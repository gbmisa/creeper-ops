#!/usr/bin/env bash
# Render build-menu icons into <out_dir> (default godot/assets/icons): art/blender/icons.sh [out_dir]
# Icon names are build-menu ids (beacon = Totem, drop = Drop Pod, operative = soldier stand-in).
set -e
here="$(cd "$(dirname "$0")" && pwd)"
models="$here/../../godot/assets/models"
out="${1:-$here/../../godot/assets/icons}"
mkdir -p "$out"
tmp="$(mktemp -d)"
icon() { blender -b --python "$here/icon.py" -- "$1" "$out/$2.png" 2>&1 | grep -E "\[icon\]|Error|Traceback" || true; }
for w in cannon mortar beam sniper bertha thor terp nullifier; do
  PREVIEW="$tmp/$w.glb" "$here/build_all.sh" "$w" >/dev/null
  icon "$tmp/$w.glb" "$w"
done
for n in collector relay outpost miner reactor storage barracks forge; do icon "$models/$n.glb" "$n"; done
icon "$models/totem.glb" beacon
icon "$models/drop_pod.glb" drop
icon "$models/soldier.glb" operative
rm -rf "$tmp"
