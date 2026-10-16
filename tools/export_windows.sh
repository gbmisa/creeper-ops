#!/usr/bin/env bash
# Windows playtest build: copies the art/gen data the game reads from outside godot/ into res://export_data,
# exports with the "Windows" preset (starts in the Firing Range), and zips it. Usage: tools/export_windows.sh <out_dir>
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:?usage: export_windows.sh <out_dir>}"
mkdir -p "$root/godot/export_data" "$out/CreeperOps"
for f in mounts.json reload_hands.json; do  # reload_hands.json is optional
  [ -f "$root/art/gen/$f" ] && cp "$root/art/gen/$f" "$root/godot/export_data/"
done
echo "$(git -C "$root" rev-parse --short HEAD) $(date +%Y-%m-%d)" > "$root/godot/export_data/build.txt"
godot --headless --path "$root/godot" --export-release "Windows" "$out/CreeperOps/CreeperOps.exe"
(cd "$out" && rm -f CreeperOps.zip && zip -qr CreeperOps.zip CreeperOps)
echo "built $out/CreeperOps.zip"
