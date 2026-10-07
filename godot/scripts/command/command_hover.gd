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
		"@lance":
			cm.overlay.show_ghost("", p, res.ok, Config.LANCE_RADIUS * Config.CELL, Config.LANCE_RADIUS * Config.CELL, [])
		"@move":
			cm.overlay.show_ghost(cm.selected.type, at, res.ok, StructureDefs.radius_m(cm.selected.type), cm.selected.def.get("range", 0.0) * Config.CELL, [])
		"@land":
			cm.overlay.show_ghost("node", at, res.ok, StructureDefs.radius_m("node"), StructureDefs.DEFS.node.link * Config.CELL, [])
		_:
			var def: Dictionary = StructureDefs.DEFS[cm.tool]
			var r: float = def.get("range", def.link) * Config.CELL
			var cover: Array[Vector4] = cm.structures.network.cover_discs(cm.structures.list) if def.get("needs_network", true) else []
			cm.overlay.show_ghost(cm.tool, at, res.ok, StructureDefs.radius_m(cm.tool), r, cover)


static func check(cm: CommandMode, c: Vector2i) -> Dictionary:
	match cm.tool:
		"@lance": return cm.orbital.can_fire()
		"@move": return Placement.can_move(cm.structures, cm.selected, c.x, c.y) if cm.selected else { "ok": false, "reason": "" }
		"@land": return Placement.can_land(cm.structures, cm.level, c.x, c.y)
		_: return Placement.can_place(cm.structures, cm.tool, c.x, c.y)
