class_name OperativeDeploy
extends RefCounted
## Totem deploy, drop pods, recall cooldown, death and respawn (design §5.4).
## drop_blocked is the Shield Dome hook. No Totem: measure to the Command Node.

var g
var down := false
var deaths := 0
var carried_extractors := 0
var crafted_ammo := 0
var bill_energy := 0.0
var bill_salvage := 0.0
var respawn_left := 0.0
var drop_blocked: Callable
var lose_crafted_ammo: Callable
var _pod := {}


func _init(game) -> void:
	g = game
	drop_blocked = func(_cell: Vector2i) -> bool: return false
	lose_crafted_ammo = func() -> void: pass
	Bus.operative_down.connect(_on_down)


func update(dt: float) -> void:
	_tick_pod(dt)
	if not down or g.economy.energy + 0.001 < bill_energy or not g.stockpile.can_afford("salvage", bill_salvage):
		return
	respawn_left = maxf(0.0, respawn_left - dt)
	if respawn_left <= 0.0:
		_finish_respawn()


func deploy_totem() -> void:
	if g.landing or g.paused or g.over:
		return
	if down:
		_deny("Operative is down. %s." % status_text())
		return
	if not _pod.is_empty():
		_deny("A drop pod is already falling.")
		return
	if g.teleport_cooldown > 0.0:
		_deny("Teleporter recharging: %ds." % ceili(g.teleport_cooldown))
		return
	var b := _chosen_totem()
	if b == null:
		_deny("No finished Totem. Drop one (Orbital tab) outside Blight, then press T.")
		return
	_spawn(Vector2i(b.x, b.z - 1), 0.0)
	Bus.metric.emit("deploy", { "how": "totem" })
	Bus.say("Operative deployed. The creeper won't wait for you.", "radio")


func can_drop(cell: Vector2i) -> Dictionary:
	if g.landing:
		return { "ok": false, "reason": "Land the Command Node first" }
	if down:
		return { "ok": false, "reason": "Operative is down" }
	if not _pod.is_empty():
		return { "ok": false, "reason": "A drop pod is already falling" }
	if not g.surface.grid.in_bounds(cell.x, cell.y):
		return { "ok": false, "reason": "Off the map" }
	if drop_blocked.call(cell):
		return { "ok": false, "reason": "An enemy Shield Dome blocks this drop" }
	var cost := drop_cost(cell)
	if g.economy.energy + 0.001 < cost:
		return { "ok": false, "reason": "Drop needs %d energy (bank has %d)." % [ceili(cost), floori(g.economy.energy)] }
	return { "ok": true, "reason": "", "warn": "Drop pod: %d energy, falls %ds" % [ceili(cost), int(Config.DROP_TIME)] }


func start_drop(cell: Vector2i) -> void:
	var res := can_drop(cell)
	if not res.ok:
		_deny(res.reason)
		return
	var cost := drop_cost(cell)
	if not g.economy.spend(cost):
		_deny("Drop needs %d energy." % ceili(cost))
		return
	_pod = { "cell": cell, "t": 0.0, "tick": 0.0 }
	Bus.metric.emit("deploy", { "how": "drop", "cost": cost })
	Sfx.play("lift")
	Bus.say("Drop pod inbound (%d energy)." % ceili(cost), "info")


func drop_cost(cell: Vector2i) -> float:
	var anchor := _nearest_anchor(cell)
	return drop_cost_cells(Vector2(cell.x - anchor.x, cell.y - anchor.y).length())


func drop_cost_cells(cells: float) -> float:
	return minf(Config.DROP_MAX, Config.DROP_BASE + floorf(maxf(0.0, cells) / Config.DROP_PER_CELLS))


func preview_recall() -> float:
	if g.fps.world == null:
		return 0.0
	var feet: Vector3 = g.fps.controller.pos if g.fps.world == g.surface else g.surface.grid.cell_ground(g.level.rift.x, g.level.rift.z)
	return recall_cooldown_from(feet, g.surface.grid)  # from the cave: measured from the Rift


func commit_recall() -> void:
	if down or g.fps.world == null:
		return
	var cd := preview_recall()
	g.teleport_cooldown = cd
	Bus.metric.emit("recall", { "cooldown": cd })
	var msg := "Operative back aboard." if cd <= 0.0 else "Operative recalled. Teleporter offline %ds." % ceili(cd)
	g.flow.to_command(msg)


## 0 at a Totem. Else RECALL_COOLDOWN_MULT × path / WALK (straight line × RECALL_NO_PATH_MULT if none).
func recall_cooldown_from(feet: Vector3, grid: Grid) -> float:
	if _near_totem(feet):
		return 0.0
	var frm := grid.world_to_cell(feet.x, feet.z)
	return Config.RECALL_COOLDOWN_MULT * path_metres(grid, frm, _nearest_anchor(frm)) / Config.WALK


func path_metres(grid: Grid, frm: Vector2i, to: Vector2i) -> float:
	if frm == to:
		return 0.0
	var dist := { frm: 0 }
	var q: Array[Vector2i] = [frm]
	var head := 0
	while head < q.size():
		var cur: Vector2i = q[head]
		head += 1
		var d: int = dist[cur]
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + dir
			if dist.has(nxt) or not grid.step_ok(cur.x, cur.y, nxt.x, nxt.y, Config.CLIMB, 99.0, Grid.Faction.PLAYER):
				continue
			if nxt == to:
				return float(d + 1) * Config.CELL
			dist[nxt] = d + 1
			q.append(nxt)
	return Vector2(to.x - frm.x, to.y - frm.y).length() * Config.CELL * Config.RECALL_NO_PATH_MULT


func status_text() -> String:
	if not down:
		return ""
	var need: PackedStringArray = []
	if g.economy.energy + 0.001 < bill_energy:
		need.append("%s energy" % _num(bill_energy))
	if not g.stockpile.can_afford("salvage", bill_salvage):
		need.append("%s salvage" % _num(bill_salvage))
	if not need.is_empty():
		return "waiting for %s" % ", ".join(need)
	return "respawn %ds" % ceili(maxf(0.0, respawn_left))


func _on_down() -> void:
	if down:
		return
	deaths += 1
	var mult := pow(Config.RESPAWN_GROWTH, float(deaths - 1))
	bill_energy = Config.RESPAWN_ENERGY * mult
	bill_salvage = Config.RESPAWN_SALVAGE * mult
	respawn_left = Config.RESPAWN_TIME
	down = true
	lose_crafted_ammo.call()
	carried_extractors = 0
	crafted_ammo = 0
	g.hud.alert("OPERATIVE DOWN", "bad")
	g.flow.to_command("Operative down. Respawn costs %s energy and %s salvage (%ds once you can pay)." % [_num(bill_energy), _num(bill_salvage), int(Config.RESPAWN_TIME)], "bad")


func _finish_respawn() -> void:
	if not g.economy.spend(bill_energy):
		respawn_left = 0.0
		return
	if not g.stockpile.spend("salvage", bill_salvage):
		g.economy.energy += bill_energy
		respawn_left = 0.0
		return
	down = false
	g.fps.reset_suit()
	g.hud.alert("OPERATIVE RESPAWNED", "good", 2.0)
	Bus.say("Operative respawned aboard the Command Node.", "good")


func _tick_pod(dt: float) -> void:
	if _pod.is_empty():
		return
	_pod["t"] = float(_pod["t"]) + dt
	_pod["tick"] = float(_pod["tick"]) - dt
	var cell: Vector2i = _pod["cell"]
	var at: Vector3 = g.surface.grid.cell_ground(cell.x, cell.y)
	if float(_pod["t"]) < Config.DROP_TIME:
		if float(_pod["tick"]) <= 0.0:
			_pod["tick"] = 0.15
			g.surface.effects.beam(at + Vector3(0, 70, 0), at, Color("9fd4ff"), 0.16, 0.25 + float(_pod["t"]) * 0.12)
		return
	_pod = {}
	if down:
		Bus.say("The pod arrived, but the Operative is down.", "warn")
		return
	_spawn(cell, 0.0)
	g.surface.effects.burst(at, Color("cfe8ff"), 2.5, 0.5)
	Sfx.play("teleport", at)
	Bus.say("Operative on the ground.", "radio")


func _spawn(cell: Vector2i, facing: float) -> void:
	g.fps.reset_suit()
	g.fps.enter(g.surface, cell, facing)
	g.command.set_tool("")
	g.flow.set_mode("surface")


func _chosen_totem() -> Structure:
	var beacons: Array = g.structures.beacons()
	var sb: Structure = g.structures.selected_beacon
	if beacons.has(sb):
		return sb
	return null if beacons.is_empty() else beacons.back()


func _nearest_anchor(from: Vector2i) -> Vector2i:
	var node: Structure = g.structures.command_node()
	var best := Vector2i(node.x, node.z) if node else Vector2i.ZERO
	var bd := INF
	var found := false
	for s in g.structures.beacons():
		var d := Vector2(from.x - s.x, from.y - s.z).length()
		if not found or d < bd:
			bd = d
			best = Vector2i(s.x, s.z)
			found = true
	return best


func _near_totem(feet: Vector3) -> bool:
	if g.fps.world != g.surface:
		return false
	for s in g.structures.beacons():
		if Vector2(s.pos.x - feet.x, s.pos.z - feet.z).length() <= Config.TOTEM_FREE_RADIUS:
			return true
	return false


func _deny(text: String) -> void:
	Bus.say(text, "warn")
	Sfx.play("deny")


func _num(n: float) -> String:
	return str(int(roundf(n))) if is_equal_approx(n, roundf(n)) else "%.1f" % n
