class_name SmokeHiveSites
## Playtest 1C: every hive on L1 and L2 has an access challenge, written as an
## "access" tag on the hive row. Per hive: (a) the Operative flood from the
## landing area reaches within 2 cells of the core, (b) the raider flood from
## the hive reaches the player's half of the map, (c) the tag is a valid kind.
## Kinds are mixed per level (L1: all distinct; L2 has 6 hives, so >= 4 kinds).


const KINDS := ["plateau", "blight", "creeper", "chokepoint", "cavemouth"]


static func run(g) -> void:
	_level(Levels.build(1), "L1")
	_level(Levels.build(2), "L2")


static func _level(lvl: Dictionary, tag: String) -> void:
	var grid: Grid = lvl.grid
	var kinds := {}
	for h in lvl.hives:
		var hx := int(h.x)
		var hz := int(h.z)
		var kind := str(h.get("access", ""))
		SmokeTest._check("%s: hive %s has an access kind" % [tag, h.name], kind in KINDS, kind)
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		# (a) The Operative can walk from the landing area to the core.
		var walk: Dictionary = LevelShape.walkable_from(grid, lvl.landing_hint)
		var near := false
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if walk.has(Vector2i(hx + dx, hz + dz)):
					near = true
					break
			if near:
				break
		SmokeTest._check("%s: Operative reaches %s core" % [tag, h.name], near)
		# (b) Raiders can walk out of the hive to the player's half (south).
		var field := RaiderField.new(grid)
		var seen := _flood(grid, field, Vector2i(hx, hz))
		var out := false
		for z in range(int(float(grid.h) * 0.65), grid.h):
			for x in grid.w:
				if seen[grid.idx(x, z)] != 0:
					out = true
					break
			if out:
				break
		SmokeTest._check("%s: raiders leave %s" % [tag, h.name], out)
	var want := mini(4, (lvl.hives as Array).size())
	SmokeTest._check("%s: access kinds are mixed" % tag, kinds.size() >= want, str(kinds))


static func _flood(grid: Grid, field: RaiderField, start: Vector2i) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(grid.w * grid.h)
	if not grid.in_bounds(start.x, start.y):
		return seen
	var open: Array[Vector2i] = [start]
	seen[grid.idx(start.x, start.y)] = 1
	var head := 0
	while head < open.size():
		var a := open[head]
		head += 1
		for d in RaiderField.DIRS:
			var b: Vector2i = a + d
			if not grid.in_bounds(b.x, b.y):
				continue
			var i: int = grid.idx(b.x, b.y)
			if seen[i] != 0 or not field.step_ok(a.x, a.y, b.x, b.y):
				continue
			seen[i] = 1
			open.append(b)
	return seen
