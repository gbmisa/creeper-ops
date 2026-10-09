class_name DeployRecall
extends RefCounted
## Recall cooldown (0 at a Totem, else scaled walking distance to the nearest anchor).

var g


func _init(game) -> void:
	g = game


func preview_recall() -> float:
	if g.fps.world == null:
		return 0.0
	var feet: Vector3 = g.fps.controller.pos if g.fps.world == g.surface else g.surface.grid.cell_ground(g.level.rift.x, g.level.rift.z)
	return recall_cooldown_from(feet, g.surface.grid)  # from the cave: measured from the Rift


func commit_recall() -> void:
	if g.deploy.down or g.fps.world == null:
		return
	var cd := preview_recall()
	g.teleport_cooldown = cd
	Bus.metric.emit("recall", { "cooldown": cd })
	var msg := "Operative back aboard." if cd <= 0.0 else "Operative recalled. Teleporter offline %ds." % ceili(cd)
	g.flow.to_command(msg)


## 0 at a Totem. Else RECALL_COOLDOWN_MULT × path / WALK (straight line × RECALL_NO_PATH_MULT if none).
func recall_cooldown_from(feet: Vector3, grid: Grid) -> float:
	if near_totem(feet):
		return 0.0
	var frm := grid.world_to_cell(feet.x, feet.z)
	return Config.RECALL_COOLDOWN_MULT * path_metres(grid, frm, nearest_anchor(frm)) / Config.WALK


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



func nearest_anchor(from: Vector2i) -> Vector2i:
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


func near_totem(feet: Vector3) -> bool:
	if g.fps.world != g.surface:
		return false
	for s in g.structures.beacons():
		if Vector2(s.pos.x - feet.x, s.pos.z - feet.z).length() <= Config.TOTEM_FREE_RADIUS:
			return true
	return false
