#!/usr/bin/env bash
# Parse-check every GDScript file; prints only files with errors. Run from godot/.
fail=0
for f in $(find scripts -name '*.gd' | sort); do
  out=$(timeout 60 godot --headless --path . --check-only --script "res://$f" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR:|at: " | grep -vE "Failed to compile depended|Identifier not found: (Bus|Sfx)|Failed to load script|gdscript_resource_format|^ +at: GDScript::reload \(res://[^)]*:0\)" )
  if [ -n "$out" ]; then echo "== $f"; echo "$out" | head -6; fail=1; fi
done
exit $fail
