class_name MetricsSummary
extends RefCounted
## Summary maths for PlayMetrics: folds the event list and accumulators into one dictionary.

const ACTIONS := ["placed", "order", "mode"]


static func build(m: PlayMetrics, cause: String) -> Dictionary:
	var built := {}
	var lost := {}
	var by_creeper := 0
	var by_other := 0
	var lost_by := {}
	var deaths := 0
	var incursions := 0
	var actions := 0
	var first_loss := -1.0
	var node_wet := false
	var prev_mode := "command"
	for e in m.events:
		match e.kind:
			"built":
				built[e.type] = int(built.get(e.type, 0)) + 1
			"structure_lost":
				lost[e.type] = int(lost.get(e.type, 0)) + 1
				lost_by[e.get("by", "unknown")] = int(lost_by.get(e.get("by", "unknown"), 0)) + 1
				if e.wet:
					by_creeper += 1
				else:
					by_other += 1
				if first_loss < 0.0:
					first_loss = e.t
				if e.type == "node":
					node_wet = e.wet
			"operative_down":
				deaths += 1
			"mode":  # surface -> cave is the same incursion
				if prev_mode == "command" and e.mode != "command":
					incursions += 1
				prev_mode = e.mode
		if ACTIONS.has(e.kind):
			actions += 1
	var modes: Dictionary = m.acc.modes
	var away := float(modes.get("surface", 0.0)) + float(modes.get("cave", 0.0))
	var last: Dictionary = m.samples.back() if not m.samples.is_empty() else {}
	return {
		"level": Levels.current(), "level_name": m.g.level.name,
		"result": "won" if cause == "victory" else "lost" if cause == "node_destroyed" else "unfinished",
		"ended": "quit" if cause == "quit" else "end", "cause": cause,
		"node_killed_by": ("creeper" if node_wet else "raiders") if cause == "node_destroyed" else "",
		"duration": snappedf(m.t, 0.1), "time_in_mode": modes,
		"operative_deaths": deaths, "incursions": { "count": incursions, "time": snappedf(away, 0.1) },
		"built_by_type": built, "lost_by_type": lost, "lost_by": lost_by,
		"lost_to_creeper": by_creeper, "lost_to_other": by_other,
		"peak_creeper_cells": m.acc.peak_cells, "node_hits": m.acc.node_hits,
		"full_bank_time": snappedf(m.acc.full, 0.1), "starved_time": snappedf(m.acc.starved, 0.1),
		"first_loss": first_loss, "pressure_end": last.get("pressure", 0.0),
		"actions": actions, "apm": snappedf(actions / maxf(m.t / 60.0, 0.01), 0.1),
	}
