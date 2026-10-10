extends Node
## Autoload "Bus": cross-system events. Systems emit here instead of holding references to
## each other. `log_msg` feeds the HUD event log (kinds: info, good, warn, bad, radio).

signal log_msg(text: String, kind: String)
signal recall(cost: float)
signal operative_down
signal enter_cave
signal exit_cave
signal core_destroyed
signal objective_done(id: String)
signal victory
signal node_destroyed
signal node_hit
signal base_attacked(type: String)  # a non-Node structure took enemy damage
signal base_lost(type: String)      # a non-Node structure was destroyed
signal node_landed
signal structure_built(s)
signal structure_removed(s)
signal unit_trained(type: String, barracks)
signal nest_destroyed(nest)
signal selection_changed
signal tool_changed(type: String)
signal metric(kind: String, data: Dictionary)  # PlayMetrics recorder: one-line reports from any system
signal terrain_changed(world, cells: Array)  # TerrainEdit: heights changed under these cells


func say(text: String, kind := "info") -> void:
	log_msg.emit(text, kind)
