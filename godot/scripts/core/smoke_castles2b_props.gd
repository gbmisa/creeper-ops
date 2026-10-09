class_name SmokeCastles2bProps
## Stage 21b P3: interior props — a dais under the crown nest, two long tables, two
## weapon racks, a runner rug, a winch + chains in every gate hall, and a stone trim on
## each tower-stair step edge. Props sit off the walking line (stairs, doors, passages);
## the walk smoke proves movement still works. Fresh level builds only.


static func run(_g) -> void:
	for lvl in [Level01.build(), Level02.build()]:
		var grid: Grid = lvl.grid
		for row in lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric"):
			_one(grid, row.id, row.layout)


static func _one(grid: Grid, id: String, lay: Dictionary) -> void:
	var root := Node3D.new()
	var desc: Dictionary = CastleProps.build(root, grid, lay)
	var keep: Dictionary = lay["zones"]["keep"]
	var floor_y := float(keep["y"]) * Config.LEVEL_H
	var ca: Dictionary = lay["crown_at"]
	var dais_ok: bool = desc["dais_cell"] == ca["cell"] \
		and absf(float(desc["dais_top_y"]) - (floor_y + CastleDefs.DAIS_H)) < 0.001
	SmokeTest._check("castles2b %s: dais under the crown nest" % id, dais_ok)
	_tables(id, lay, desc)
	var racks: Array = desc["racks"]
	var racks_ok: bool = racks.size() == 2
	for c in racks:
		racks_ok = racks_ok and not _forbidden(lay).has(c)
	SmokeTest._check("castles2b %s: two weapon racks off the walking line" % id, racks_ok)
	var rug: Array = desc["rug_cells"]
	var rug_ok := true
	for c in rug:
		rug_ok = rug_ok and (keep["cells"].has(c) or (lay["keep"] as Dictionary)["door"].has(c))
	SmokeTest._check("castles2b %s: the rug lies on hall/door floor" % id, rug_ok, "(%d cells)" % rug.size())
	var gh := 0
	for it in lay["interiors"]:
		if it["kind"] == "gatehouse":
			gh += 1
	var winches: Array = desc["winches"]
	var winch_ok: bool = winches.size() == gh
	for c in winches:
		winch_ok = winch_ok and not _forbidden(lay).has(c)
	SmokeTest._check("castles2b %s: a winch in every gate hall" % id, winch_ok, "(%d halls)" % gh)
	var want_trims := 8 * (lay["towers"] as Array).size()
	SmokeTest._check("castles2b %s: a trim on every tower step edge" % id,
		int(desc["trims"]) == want_trims, "(%d trims)" % int(desc["trims"]))
	root.free()


## Two tables flanking the aisle (opposite sides), 2-4 cells each, off the walking line.
static func _tables(id: String, lay: Dictionary, desc: Dictionary) -> void:
	var tables: Array = desc["tables"]
	var box: Rect2i = lay["keep_box"]
	var centre := Vector2i(box.get_center())
	var door_cells: Array = (lay["keep"] as Dictionary)["door"]
	var door_c := Vector2i.ZERO
	for c in door_cells:
		door_c += c
	door_c = door_c / maxi(1, door_cells.size())
	var fwd := Vector2i(signi(door_c.x - centre.x), signi(door_c.y - centre.y))
	if fwd == Vector2i.ZERO:
		fwd = Vector2i(1, 0)
	var side := Vector2i(-fwd.y, fwd.x)
	var signs := {}
	var ok: bool = tables.size() == 2
	var keep_cells: Array = (lay["zones"] as Dictionary)["keep"]["cells"]
	for cells in tables:
		ok = ok and (cells as Array).size() >= 2 and (cells as Array).size() <= 4
		for c in cells:
			ok = ok and keep_cells.has(c) and not _forbidden(lay).has(c)
			var rel: Vector2i = c - centre
			signs[signi(rel.x * side.x + rel.y * side.y)] = true
	ok = ok and signs.has(1) and signs.has(-1) and signs.size() == 2
	SmokeTest._check("castles2b %s: two long tables flanking the aisle, off the walking line" % id, ok)


## Stairs, doors and tower doors: no prop may stand on them (the rug is flat and exempt).
static func _forbidden(lay: Dictionary) -> Dictionary:
	var out := {}
	var kd: Dictionary = lay["keep"]
	for c in (kd["door"] as Array) + (kd["stair"] as Array):
		out[c] = true
	for tw in lay["towers"]:
		for c in tw["doors"]:
			out[c] = true
	return out
