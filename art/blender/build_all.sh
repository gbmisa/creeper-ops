#!/usr/bin/env bash
# Rebuild every creature .glb: art/blender/build_all.sh [name ...]
set -e
cd "$(dirname "$0")/../.."
OUT="$PWD/godot/assets/models"
mkdir -p "$OUT"
names=("$@")
[ ${#names[@]} -eq 0 ] && names=($(ls art/blender/*.py | xargs -n1 basename | sed 's/\.py$//' | grep -v -E '^(lib|preview)$'))
for n in "${names[@]}"; do
  blender -b --python "art/blender/$n.py" -- "$OUT/$n.glb" 2>&1 | grep -E "Error|Traceback" && exit 1
  echo "built $n.glb"
done
