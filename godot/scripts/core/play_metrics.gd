class_name PlayMetrics
extends RefCounted
## Records how a mission was played (events, periodic samples, a summary) and writes one JSON
## per mission to user://metrics/. Recording only: it reads game state and never changes it.
## Systems report with `Bus.metric.emit(kind, data)`; common Bus signals are listened to here.
## Summary maths live in MetricsSummary. Tests and debug runs set `persist = false`; a sim
## writes only when given `--metrics=<file or folder>` (`out_path`).

static var persist := true
static var out_path := ""

var g  # Game (read only)
var t := 0.0                 # mission seconds, advanced by tick()
var events: Array = []
var samples: Array = []
var acc := { "modes": {}, "full": 0.0, "starved": 0.0, "peak_cells": 0, "node_hits": 0 }
var saved_path := ""
var done := false
var _next_sample := Config.METRICS_SAMPLE
var _last_hit := -999.0
var _conns: Array = []


func _init(game) -> void:
	g = game
	_listen(Bus.metric, _on_metric)
	_listen(Bus.structure_built, func(s): _event("built", { "type": s.type }))
	_listen(Bus.node_hit, _on_node_hit)
	_listen(Bus.operative_down, func(): _event("operative_down", {}))
	_listen(Bus.unit_trained, func(type, _b): _event("unit_trained", { "type": type }))
	_listen(Bus.nest_destroyed, func(n): _event("nest_destroyed", { "name": str(n.name) if "name" in n else "" }))
	_listen(Bus.objective_done, func(id): _event("objective_done", { "id": id }))


func _listen(sig: Signal, fn: Callable) -> void:
	sig.connect(fn)
	_conns.append([sig, fn])


func tick(dt: float) -> void:
	if done or not Config.METRICS_ON:
		return
	t += dt
	var m: Dictionary = acc.modes
	m[g.mode] = float(m.get(g.mode, 0.0)) + dt
	var e: Economy = g.economy
	if e.energy >= e.max_energy * 0.98:
		acc.full += dt
	if e.energy < 1.0 and g.structures.packets.demand_rate > 0.0:
		acc.starved += dt
	while t >= _next_sample:
		_next_sample += Config.METRICS_SAMPLE
		samples.append(sample())


func sample() -> Dictionary:
	var sm: StructureManager = g.structures
	var by_type := {}
	for s in sm.list:
		by_type[s.type] = int(by_type.get(s.type, 0)) + 1
	var cells := 0
	for d in g.surface.creeper.depth:
		if d > Config.MIN_DEPTH:
			cells += 1
	acc.peak_cells = maxi(int(acc.peak_cells), cells)
	var node: Structure = sm.command_node()
	return { "t": snappedf(t, 0.1), "pressure": snappedf(Pressure.value(g.level, t), 0.001),
		"energy": snappedf(g.economy.energy, 0.1), "max_energy": g.economy.max_energy,
		"income": snappedf(g.economy.income, 0.01), "wasted": snappedf(g.economy.wasted, 0.01),
		"ore": g.stockpile.ore, "salvage": g.stockpile.salvage, "structures": by_type,
		"units": g.units.list.size(), "raiders": g.hazards.nests.raiders.list.size(),
		"creeper_cells": cells, "node_hp": snappedf(node.hp / float(node.def.hp), 0.01) if node else 0.0,
		"mode": g.mode }


func _event(kind: String, data: Dictionary) -> void:
	if done or not Config.METRICS_ON:
		return
	var row := { "t": snappedf(t, 0.1), "kind": kind }
	row.merge(data)
	events.append(row)


func _on_metric(kind: String, data: Dictionary) -> void:
	_event(kind, data)


func _on_node_hit() -> void:
	acc.node_hits += 1
	if t - _last_hit >= Config.METRICS_HIT_GAP:
		_last_hit = t
		var node: Structure = g.structures.command_node()
		_event("node_hit", { "hp": snappedf(node.hp / float(node.def.hp), 0.01) if node else 0.0 })


## Ends the mission record and writes it. Safe to call repeatedly; only the first call counts.
func finish(cause: String) -> void:
	if done:
		return
	if Config.METRICS_ON and t > 0.0:
		samples.append(sample())
		_event(cause, {})
	done = true
	for c in _conns:
		if (c[0] as Signal).is_connected(c[1]):
			(c[0] as Signal).disconnect(c[1])
	if not Config.METRICS_ON or t <= 0.0:
		return
	if out_path == "" and (not persist or cause == "quit" and t < Config.METRICS_MIN_QUIT):
		return
	saved_path = write(MetricsSummary.build(self, cause))


func write(summary: Dictionary) -> String:
	var path := out_path
	if path == "" or not path.ends_with(".json"):
		var dir := path if path != "" else "user://metrics"
		DirAccess.make_dir_recursive_absolute(dir)
		var stamp := Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
		path = "%s/L%d_%s.json" % [dir, Levels.current(), stamp]
	else:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify({ "summary": summary, "samples": samples, "events": events }))
	return path


## Lines appended to the end screen.
func end_text() -> String:
	var s: Dictionary = MetricsSummary.build(self, "end")
	var lost := 0
	for k in s.lost_by_type:
		lost += int(s.lost_by_type[k])
	return "\n\nTime %dm %ds · structures lost %d · Operative deaths %d\n%s" % [
		floori(t / 60.0), floori(fmod(t, 60.0)), lost, s.operative_deaths,
		"Metrics saved." if saved_path != "" else "Metrics not saved."]
