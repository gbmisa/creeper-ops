class_name EngineShape
extends RefCounted
## Stamps Salvage Engine bodies into the terrain while the level is built (before
## snapshot_base), so walkers, the creeper and Grid.stand_y all see them as ground.
## Body cells rise `top` whole levels over the local floor; a stair of one-level steps climbs
## the south face. Each row gets floor, stair, sockets (pos + the cell the Operative stands
## on) and cells for the "never buildable" rule. Whole levels only: no height noise.


static func stamp_all(g: Grid, rows: Array) -> void:
	for raw in rows:
		var row: Dictionary = raw
		stamp(g, row)


static func stamp(g: Grid, row: Dictionary) -> void:
	var k := EngineDefs.kind(row)
	var cx := int(row.x)
	var cz := int(row.z)
	var floor_h := roundf(g.height_at(cx, cz))
	var top := floor_h + float(k.top)
	var body := EngineDefs.body_cells(row)
	for c in body:  # level the footprint's surroundings first so the body stands on a clean floor
		_put(g, c.x, c.y, top, Grid.Mat.STONE)
	var stair: Array[Vector2i] = []
	if bool(k.stair):
		var zs := cz + int(k.d) / 2 + 1
		var x0 := cx - int(k.w) / 2
		for i in int(k.top) - 1:
			var c := Vector2i(x0 + i, zs)
			_put(g, c.x, c.y, floor_h + 1.0 + float(i), Grid.Mat.STONE)
			stair.append(c)
		# a flat landing before the first step and a floor strip to walk in from
		_put(g, x0 - 1, zs, floor_h, Grid.Mat.NATURAL)
		for i in int(k.top) - 1:
			_put(g, x0 + i, zs + 1, floor_h, Grid.Mat.NATURAL)
		_put(g, x0 - 1, zs + 1, floor_h, Grid.Mat.NATURAL)
	row["floor"] = int(floor_h)
	row["stair"] = stair
	row["cells"] = body + stair
	for c in row.cells:
		g.blocked[g.idx(c.x, c.y)] = 1
	var socks: Array = []
	for raw in k.sockets:
		socks.append(_socket(g, row, k, raw))
	row["sockets"] = socks


static func _put(g: Grid, x: int, z: int, h: float, mat: int) -> void:
	if not g.in_bounds(x, z):
		return
	var i := g.idx(x, z)
	g.height[i] = h
	g.material[i] = mat


## World position of a socket plus the cell the Operative stands in to use it.
static func _socket(g: Grid, row: Dictionary, k: Dictionary, s: Dictionary) -> Dictionary:
	var cx := int(row.x)
	var cz := int(row.z)
	var hw := int(k.w) / 2
	var hd := int(k.d) / 2
	var face := str(s.face)
	var u := float(s.u)
	var lift := float(s.lift)
	var top_level := float(row.floor) + float(k.top)
	if face == "top":
		var tc := Vector2i(cx + int(roundf(u)), cz)
		var tp := Vector3((cx + 0.5 + u) * Config.CELL, top_level * Config.LEVEL_H + lift, (cz + 0.5) * Config.CELL)
		return { "face": face, "pos": tp, "cell": tc, "level": int(top_level) }
	var cell: Vector2i
	var edge: int  # grid line the wall stands on, in cells
	var along := (cx + 0.5 + u) * Config.CELL
	match face:
		"s":
			edge = cz + hd + 1
			cell = Vector2i(cx + int(roundf(u)), edge)
		"n":
			edge = cz - hd
			cell = Vector2i(cx + int(roundf(u)), edge - 1)
		"e":
			edge = cx + hw + 1
			along = (cz + 0.5 + u) * Config.CELL
			cell = Vector2i(edge, cz + int(roundf(u)))
		_:
			edge = cx - hw
			along = (cz + 0.5 + u) * Config.CELL
			cell = Vector2i(edge - 1, cz + int(roundf(u)))
	# The wall is a terrace ramp (Grid.terrace), not a vertical face: find where it is `lift` metres up,
	# measured from the ground the Operative stands on (that cell's own height).
	var base := g.height_at(cell.x, cell.y)
	var rise := maxf(0.5, (top_level - base) * Config.LEVEL_H)
	var half := Config.TERRACE_BAND * Config.CELL * 0.5
	var off := half - 2.0 * half * clampf(lift / rise, 0.0, 1.0) + 0.12
	var dir := 1.0 if face == "s" or face == "e" else -1.0
	var y := base * Config.LEVEL_H + lift
	var pos := Vector3(along, y, edge * Config.CELL + dir * off)
	if face == "e" or face == "w":
		pos = Vector3(edge * Config.CELL + dir * off, y, along)
	return { "face": face, "pos": pos, "cell": cell, "level": int(base) }
