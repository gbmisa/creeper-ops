#!/usr/bin/env bash
# Play the Firing Range. Run from godot/. Extra args go after `--`.
exec godot --path . res://scenes/firing_range.tscn -- "$@"
