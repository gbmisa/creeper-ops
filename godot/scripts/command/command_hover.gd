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
	if cm.tool == "@terp":
		cm.reason = cm.overlay.paint.hover_text(cm) if cm.overlay.paint else ""
		cm.overlay.hide_ghost()
		return
	if not cm.drag_plan.is_empty():  # DragBuild draws its own preview
		cm.overlay.hide_ghost()
		cm.reason = DragBuild.summary(cm.drag_plan)
		return
	var c: Vector2i = cm.hover.cell
	var at := cm.world.grid.cell_ground(c.x, c.y)
	var res := check(cm, c)
	cm.reason = res.reason if not res.ok else res.get("warn", "")
	if _turret_type(cm.tool) != "":  # any castle turret (ward lamps have no range: no ring)
		var rg: float = float(CastleTurrets.DEFS[_turret_type(cm.tool)].get("range", 0.0))
		cm.overlay.show_ghost("", at, res.ok, 1.2 * Config.CELL, rg * Config.CELL, [])
		return
	match cm.tool:
		"@lance", "@drop":
			var rad := (Config.LANCE_RADIUS if cm.tool == "@lance" else 1.0) * Config.CELL
			cm.overlay.show_ghost("", p, res.ok, rad, rad, [])
		"@move":
			cm.overlay.show_ghost(cm.selected.type, at, res.ok, StructureDefs.radius_m(cm.selected.type), WeaponLogic.def_range(cm.selected.def) * Config.CELL, [])
		"@land":
			cm.overlay.show_ghost("node", at, res.ok, StructureDefs.radius_m("node"), StructureDefs.DEFS.node.link * Config.CELL, [])
		"@repair":
			cm.overlay.show_ghost("", at, res.ok, 1.2 * Config.CELL, 0.0, [])
		_:
			var def: Dictionary = StructureDefs.DEFS[cm.tool]
			var reach := float(def.work_range) if def.has("work_range") else (WeaponLogic.def_range(def) if def.has("range") else float(def.link))
			var r := reach * Config.CELL
			var cover: Array[Vector4] = cm.structures.network.cover_discs(cm.structures.list) if def.get("needs_network", true) else []
			cm.overlay.show_ghost(cm.tool, at, res.ok, StructureDefs.radius_m(cm.tool), r, cover)


## The turret id for a "@<turret>" tool, or "" (rangeless defs like the Ward Lamp included).
static func _turret_type(tool: String) -> String:
	if not tool.begins_with("@"):
		return ""
	var t := tool.substr(1)
	return t if CastleTurrets.DEFS.has(t) else ""


static func check(cm: CommandMode, c: Vector2i) -> Dictionary:
	if _turret_type(cm.tool) != "":
		return turret_check(cm, c).res
	match cm.tool:
		"@lance": return cm.orbital.can_fire()
		"@drop": return cm.deploy.can_drop(c)
		"@move": return Placement.can_move(cm.structures, cm.selected, c.x, c.y) if cm.selected else { "ok": false, "reason": "" }
		"@land": return Placement.can_land(cm.structures, cm.level, c.x, c.y)
		"@repair": return WallRepair.check(cm.castles, c)
		"@terp":
			var why := TerpPaint.cell_reason(cm.world.grid, c)
			return { "ok": why == "", "reason": why }
		_: return Placement.can_place(cm.structures, cm.tool, c.x, c.y)


## The castle and socket under `cell` for a turret tool, and whether it can be bought.
static func turret_check(cm: CommandMode, cell: Vector2i) -> Dictionary:
	var type := cm.tool.substr(1)
	for c in cm.castles.list if cm.castles else []:
		var i := CastleTurrets.socket_at(c, cell)
		if i >= 0:
			return { "castle": c, "i": i, "res": CastleTurrets.check(c, i, type, cm.castles.stockpile.salvage) }
	return { "castle": {}, "i": -1, "res": { "ok": false, "reason": "Pick a turret socket on a castle you hold (wall corners, beside the gate)" } }
