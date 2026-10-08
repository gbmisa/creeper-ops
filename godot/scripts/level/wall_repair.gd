class_name WallRepair
## Repair a wall of a castle you hold, from command mode. 1 Salvage per WALL_REPAIR_HP.
## At 0 HP the segment is a breach; paying restores its stone.


static func check(castles: Strongholds, cell: Vector2i) -> Dictionary:
	var hit := _find(castles, cell)
	if hit.is_empty():
		return { "ok": false, "reason": "Click a wall of a castle you hold" }
	return _quote(hit.c, int(hit.i), castles.stockpile)


static func apply(castles: Strongholds, cell: Vector2i) -> Dictionary:
	var hit := _find(castles, cell)
	if hit.is_empty():
		return { "ok": false, "reason": "Click a wall of a castle you hold" }
	var res := _quote(hit.c, int(hit.i), castles.stockpile)
	if not res.ok:
		return res
	var c: Dictionary = hit.c
	var i := int(hit.i)
	var lay: Dictionary = hit.lay
	var wall: Dictionary = c.walls[i]
	var down := float(wall.hp) <= 0.0
	castles.stockpile.spend("salvage", float(res.cost))
	wall.hp = wall.max_hp
	if down:
		var edits := []
		for cell_i in lay.segments[i].cells:
			edits.append({ "x": cell_i.x, "z": cell_i.y, "height": lay.wall_top, "material": Grid.Mat.STONE })
		TerrainEdit.apply(castles.world, edits)
	StrongholdMeshes.refresh(castles.views[c.id], c)
	Bus.say("%s: wall repaired (%s Salvage)." % [c.name, String.num(float(res.cost), 1)], "good")
	return { "ok": true, "reason": "" }


static func _find(castles: Strongholds, cell: Vector2i) -> Dictionary:
	if castles == null:
		return {}
	for c in castles.list:
		var lay: Dictionary = castles.lays[c.id]
		for i in lay.segments.size():
			if cell in lay.segments[i].cells:
				return { "c": c, "i": i, "lay": lay }
	return {}


static func _quote(c: Dictionary, i: int, pile: Stockpile) -> Dictionary:
	if c.owner != "player" or (str(c.state) != "held" and str(c.state) != "siege"):
		return { "ok": false, "reason": "Repair walls on a castle you hold" }
	var wall: Dictionary = c.walls[i]
	var missing := float(wall.max_hp) - float(wall.hp)
	if missing <= 0.01:
		return { "ok": false, "reason": "That wall is intact" }
	var cost := missing / Config.WALL_REPAIR_HP
	if pile == null or not pile.can_afford("salvage", cost):
		return { "ok": false, "reason": "Repair needs %s Salvage" % String.num(cost, 1) }
	return { "ok": true, "reason": "", "cost": cost, "warn": "Repair: %s Salvage" % String.num(cost, 1) }
