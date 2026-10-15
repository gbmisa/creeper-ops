class_name OperativeDeploy
extends RefCounted
## Site deploy (Totems + Command Node, chosen by DeployPick), drop pods (DeployPod), recall (DeployRecall),
## death and respawn (design §5.4). drop_blocked is the Shield Dome hook. Recall cooldown is measured to
## the nearest Totem or Command Node by walk path.

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
var pods: DeployPod
var recall: DeployRecall
var pick: DeployPick


func _init(game) -> void:
	g = game
	drop_blocked = func(_cell: Vector2i) -> bool: return false
	lose_crafted_ammo = func() -> void: pass
	pods = DeployPod.new(game)
	recall = DeployRecall.new(game)
	pick = DeployPick.new(game)
	Bus.operative_down.connect(_on_down)


func update(dt: float) -> void:
	pods.tick(dt)
	pick.update(dt)
	if not down or g.economy.energy + 0.001 < bill_energy or not g.stockpile.can_afford("salvage", bill_salvage):
		return
	respawn_left = maxf(0.0, respawn_left - dt)
	if respawn_left <= 0.0:
		_finish_respawn()


func deploy_totem() -> void:
	if g.landing or g.paused or g.over:
		return
	if pick.active:
		pick.confirm()  # deploy pressed again: take the highlighted site
		return
	if down:
		_deny("Operative is down. %s." % status_text())
		return
	if pods.falling():
		_deny("A drop pod is already falling.")
		return
	if g.teleport_cooldown > 0.0:
		_deny("Teleporter recharging: %ds." % ceili(g.teleport_cooldown))
		return
	if pick.begin_if_needed():
		return
	var b := pick.chosen()
	if b == null:
		_deploy_from_node(g.structures.command_node())
		return
	deploy_from(b)


## Deploy at one specific finished Totem or Command Node (also what the pick mode calls).
func deploy_from(b: Structure) -> void:
	pick.remember(b)
	if b.type == "node":
		_deploy_from_node(b)
		return
	_spawn(Vector2i(b.x, b.z - 1), 0.0)
	var totem_model := CreatureAnim.of(b.body)
	if totem_model != null:
		CreatureAnim.attack(totem_model)
	Bus.metric.emit("deploy", { "how": "totem" })
	Bus.say("Operative deployed. The creeper won't wait for you.", "radio")


## No finished Totem: fall back to the Command Node, so the Operative can get
## boots on the ground before any base exists. Spawns on a free cell beside it.
func _deploy_from_node(node: Structure) -> void:
	if node == null:
		_deny("No Command Node.")
		return
	var cell := _free_cell_near(node)
	if cell.x < 0:
		_deny("No free ground beside the Command Node.")
		return
	_spawn(cell, 0.0)
	Bus.metric.emit("deploy", { "how": "node" })
	Bus.say("Operative deployed from the Command Node.", "radio")


## First walkable, unoccupied cell on rings around the node's footprint.
func _free_cell_near(node: Structure) -> Vector2i:
	var grid: Grid = g.surface.grid
	var fr: int = StructureDefs.footprint("node")
	var busy := {}
	for c in Placement.footprint_cells("node", node.x, node.z):
		busy[c] = true
	for ring in range(1, 5):
		var r := fr + ring
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var c := Vector2i(node.x + dx, node.z + dz)
				if busy.has(c) or not grid.in_bounds(c.x, c.y):
					continue
				if g.structures.structure_at(c.x, c.y) != null:
					continue
				if not grid.step_ok(node.x, node.z, c.x, c.y, Config.CLIMB, 99.0, Grid.Faction.PLAYER):
					continue
				return c
	return Vector2i(-1, -1)


func preview_recall() -> float:
	return recall.preview_recall()


func commit_recall() -> void:
	recall.commit_recall()


func recall_cooldown_from(feet: Vector3, grid: Grid) -> float:
	return recall.recall_cooldown_from(feet, grid)


func path_metres(grid: Grid, frm: Vector2i, to: Vector2i) -> float:
	return recall.path_metres(grid, frm, to)


func can_drop(cell: Vector2i) -> Dictionary:
	if g.landing:
		return { "ok": false, "reason": "Land the Command Node first" }
	if down:
		return { "ok": false, "reason": "Operative is down" }
	if pods.falling():
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
	pods.begin(cell)
	Bus.metric.emit("deploy", { "how": "drop", "cost": cost })
	Sfx.play("lift")
	Bus.say("Drop pod inbound (%d energy)." % ceili(cost), "info")



func drop_cost(cell: Vector2i) -> float:
	var anchor := recall.nearest_anchor(cell)
	return drop_cost_cells(Vector2(cell.x - anchor.x, cell.y - anchor.y).length())


func drop_cost_cells(cells: float) -> float:
	return minf(Config.DROP_MAX, Config.DROP_BASE + floorf(maxf(0.0, cells) / Config.DROP_PER_CELLS))



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
	pick.begin_respawn()



func _spawn(cell: Vector2i, facing: float) -> void:
	g.fps.reset_suit()
	g.fps.enter(g.surface, cell, facing)
	g.command.set_tool("")
	g.flow.set_mode("surface")


func _deny(text: String) -> void:
	Bus.say(text, "warn")
	Sfx.play("deny")


func _num(n: float) -> String:
	return str(int(roundf(n))) if is_equal_approx(n, roundf(n)) else "%.1f" % n
