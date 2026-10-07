class_name CommandHover
## Ghost and range preview for the armed command tool. Asks Placement (or the Lance
## and landing rules) whether the cell is legal, then draws it through CommandOverlay.


static func refresh(cm: CommandMode, input: InputState) -> void:
	var p = cm.cam.pick(input.mouse, cm.world.grid)
	if p == null:
		cm.hover = {}
		cm.reason = ""
		cm.overlay.hide_ghost()
		return
	cm.hover = { "cell": cm.world.grid.world_to_cell(p.x, p.z), "point": p }
	if cm.tool == "":
		cm.reason = ""
		return
	var c: Vector2i = cm.hover.cell
	var at := cm.world.grid.cell_ground(c.x, c.y)
	var res := check(cm, c)
	cm.reason = res.reason if not res.ok else res.get("warn", "")
	match cm.tool:
		"@lance", "@drop":
			var rad := (Config.LANCE_RADIUS if cm.tool == "@lance" else 1.0) * Config.CELL
			cm.overlay.show_ghost("", p, res.ok, rad, rad, [])
		"@move":
			cm.overlay.show_ghost(cm.selected.type, at, res.ok, StructureDefs.radius_m(cm.selected.type), WeaponLogic.def_range(cm.selected.def) * Config.CELL, [])
		"@land":
			cm.overlay.show_ghost("node", at, res.ok, StructureDefs.radius_m("node"), StructureDefs.DEFS.node.link * Config.CELL, [])
		"@repeater", "@lobber", "@flak":
			cm.overlay.show_ghost("", at, res.ok, 1.2 * Config.CELL, CastleTurrets.DEFS[cm.tool.substr(1)].range * Config.CELL, [])
		_:
			var def: Dictionary = StructureDefs.DEFS[cm.tool]
			var r: float = (WeaponLogic.def_range(def) if def.has("range") else def.link) * Config.CELL
			var cover: Array[Vector4] = cm.structures.network.cover_discs(cm.structures.list) if def.get("needs_network", true) else []
			cm.overlay.show_ghost(cm.tool, at, res.ok, StructureDefs.radius_m(cm.tool), r, cover)


static func check(cm: CommandMode, c: Vector2i) -> Dictionary:
	match cm.tool:
		"@lance": return cm.orbital.can_fire()
		"@drop": return cm.deploy.can_drop(c)
		"@move": return Placement.can_move(cm.structures, cm.selected, c.x, c.y) if cm.selected else { "ok": false, "reason": "" }
		"@land": return Placement.can_land(cm.structures, cm.level, c.x, c.y)
		"@repeater", "@lobber", "@flak": return turret_check(cm, c).res
		_: return Placement.can_place(cm.structures, cm.tool, c.x, c.y)


## The castle and socket under `cell` for a turret tool, and whether it can be bought.
static func turret_check(cm: CommandMode, cell: Vector2i) -> Dictionary:
	var type := cm.tool.substr(1)
	for c in cm.castles.list if cm.castles else []:
		var i := CastleTurrets.socket_at(c, cell)
		if i >= 0:
			return { "castle": c, "i": i, "res": CastleTurrets.check(c, i, type, cm.castles.stockpile.salvage) }
	return { "castle": {}, "i": -1, "res": { "ok": false, "reason": "Pick a turret socket on a castle you hold (wall corners, beside the gate)" } }
