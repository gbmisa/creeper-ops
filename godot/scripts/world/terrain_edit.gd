class_name TerrainEdit
## The only way gameplay changes terrain after a level is built (the Terp, castle breaches
## and repairs, enemy mortars, growing hives). An edit is { x, z, height, material? }.
## Cells under a structure (world.occupied) and Spire cells are skipped. World.terrain_changed
## then updates everything that reads heights: the height texture (terrain and creeper
## shaders), the terrain chunk meshes, the creeper sim, props, and via Bus.terrain_changed
## the raider flow field and unit paths. The Operative needs nothing: it re-reads the grid
## every frame, so it rides a rising cell up and falls with a sinking one.


## Applies the edits and returns the cells that actually changed.
static func apply(world: World, edits: Array) -> Array[Vector2i]:
	var g := world.grid
	var changed: Array[Vector2i] = []
	for e in edits:
		var x: int = e.x
		var z: int = e.z
		if not g.in_bounds(x, z) or world.occupied.call(x, z):
			continue
		var i := g.idx(x, z)
		if g.material[i] == Grid.Mat.SPIRE:
			continue
		var h := clampf(float(e.height), 0.0, float(Config.MAX_LEVEL))
		var mat: int = e.get("material", g.material[i])
		if absf(h - g.height[i]) < 0.001 and mat == g.material[i]:
			continue
		g.height[i] = h
		g.material[i] = mat
		changed.append(Vector2i(x, z))
	if not changed.is_empty():
		world.terrain_changed(changed)
	return changed


## Raise (or with a negative `by`, lower) cells relative to their current height.
static func raise(world: World, cells: Array, by: float, material := -1) -> Array[Vector2i]:
	var edits := []
	for c in cells:
		var e := { "x": c.x, "z": c.y, "height": world.grid.height_at(c.x, c.y) + by }
		if material >= 0:
			e["material"] = material
		edits.append(e)
	return apply(world, edits)
