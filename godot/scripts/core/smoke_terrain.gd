class_name SmokeTerrain
## Stage 5 checks: TerrainEdit updates every system that reads heights (grid, height
## texture, chunks, creeper, raider field, unit paths, the Operative), skips occupied and
## Spire cells, and faction gates block everyone but their owner. Called from SmokeTest.run.

static var _signalled := 0


static func run(g) -> void:
	var w: World = g.surface
	var grid: Grid = w.grid
	var c := _flat_spot(g, grid)
	if c == Vector2i(-1, -1):
		SmokeTest._check("terrain: found a flat test spot", false)
		return
	var n := c + Vector2i(1, 0)  # neighbour the walkers start from
	var h0 := grid.height_at(c.x, c.y)
	Bus.terrain_changed.connect(_count)
	_signalled = 0

	var changed := TerrainEdit.raise(w, [c], 3.0, Grid.Mat.EARTH)
	SmokeTest._check("terrain: edit raises the cell", changed.size() == 1 and absf(grid.height_at(c.x, c.y) - (h0 + 3.0)) < 0.01)
	SmokeTest._check("terrain: material recorded", grid.material[grid.idx(c.x, c.y)] == Grid.Mat.EARTH)
	SmokeTest._check("terrain: base height untouched", absf(grid.base_height[grid.idx(c.x, c.y)] - h0) < 0.01)
	SmokeTest._check("terrain: height texture updated", absf(w.height_tex.get_image().get_pixel(c.x, c.y).r - (h0 + 3.0)) < 0.01)
	SmokeTest._check("terrain: chunks marked dirty", not w.terrain.dirty.is_empty())
	w.terrain.flush()
	SmokeTest._check("terrain: chunks rebuilt", w.terrain.dirty.is_empty())
	SmokeTest._check("terrain: Bus.terrain_changed fired", _signalled == 1)

	var raiders: Raiders = g.hazards.nests.raiders
	SmokeTest._check("terrain: raiders can't step onto a raised cell", not raiders.field.step_ok(n.x, n.y, c.x, c.y))
	var soldier: Dictionary = UnitDefs.DEFS[UnitDefs.ORDER[0]]
	SmokeTest._check("terrain: unit pathing sees the wall", not Pathfind.step_ok(grid, n.x, n.y, c.x, c.y, soldier))
	var cam := Camera3D.new()
	var pc := PlayerController.new(cam)
	pc.spawn(grid, n.x, n.y)
	var cw := grid.cell_ground(c.x, c.y)
	SmokeTest._check("terrain: Operative blocked by the wall", not pc.can_occupy(grid, cw.x, cw.z))
	cam.free()

	var sim := CreeperSim.new(grid)  # own CPU sim, so the level's creeper is untouched
	sim.set_depth(n.x, n.y, 1.0)
	for i in 30:
		sim.update(Config.CREEPER_TICK)
	SmokeTest._check("terrain: creeper flows around a raised cell", sim.depth_at(c.x, c.y) < Config.MIN_DEPTH)

	TerrainEdit.raise(w, [c], -3.0, Grid.Mat.NATURAL)
	SmokeTest._check("terrain: lowering restores the cell", absf(grid.height_at(c.x, c.y) - h0) < 0.01)
	SmokeTest._check("terrain: raiders can walk it again", raiders.field.step_ok(n.x, n.y, c.x, c.y))

	var i := grid.idx(c.x, c.y)
	grid.material[i] = Grid.Mat.SPIRE
	SmokeTest._check("terrain: spire cells are indestructible", TerrainEdit.raise(w, [c], 2.0).is_empty())
	grid.material[i] = Grid.Mat.NATURAL
	var s: Structure = g.structures.place("relay", c.x, c.y, true)
	if s:
		SmokeTest._check("terrain: occupied cells are skipped", TerrainEdit.raise(w, [c], 2.0).is_empty())
		g.structures.remove(s, "recycled")

	grid.gate[i] = Grid.Faction.ENEMY
	SmokeTest._check("terrain: enemy gate passes raiders", raiders.field.step_ok(n.x, n.y, c.x, c.y))
	SmokeTest._check("terrain: enemy gate blocks units", not Pathfind.step_ok(grid, n.x, n.y, c.x, c.y, soldier))
	grid.gate[i] = Grid.Faction.PLAYER
	SmokeTest._check("terrain: player gate blocks raiders", not raiders.field.step_ok(n.x, n.y, c.x, c.y))
	grid.gate[i] = Grid.Faction.NONE
	Bus.terrain_changed.disconnect(_count)
	w.terrain.flush()


static func _count(_w, _cells) -> void:
	_signalled += 1


## A dry, empty cell whose 3x3 block is level, away from hazards.
static func _flat_spot(g, grid: Grid) -> Vector2i:
	for z in range(10, grid.h - 10):
		for x in range(10, grid.w - 10):
			var h := grid.height_at(x, z)
			var ok := true
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var cx := x + dx
					var cz := z + dz
					if grid.height_at(cx, cz) != h or grid.blocked[grid.idx(cx, cz)] \
							or g.structures.structure_at(cx, cz) != null or g.surface.creeper.depth_at(cx, cz) > 0.0:
						ok = false
			if ok:
				return Vector2i(x, z)
	return Vector2i(-1, -1)
