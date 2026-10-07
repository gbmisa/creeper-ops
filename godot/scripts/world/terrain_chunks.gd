class_name TerrainChunks
extends Node3D
## The terrain as SIZE x SIZE-cell chunk meshes (the decorative rim included). TerrainEdit
## marks the chunks under changed cells dirty; update() rebuilds at most REBUILDS_PER_FRAME
## of them, so a big edit spreads over a few frames instead of stalling one.

const SIZE := 16
const REBUILDS_PER_FRAME := 2

var grid: Grid
var cave := false
var material: Material
var noise: Noise2D
var chunks := {}  # Vector2i chunk coord -> MeshInstance3D
var dirty := {}   # Vector2i chunk coord -> true
var _ext := Vector2i.ZERO  # extended size in cells (grid + rim on both sides)


func setup(g: Grid, is_cave: bool, mat: Material) -> void:
	name = "Terrain"
	grid = g
	cave = is_cave
	material = mat
	noise = Noise2D.new(41 if is_cave else 17)
	_ext = Vector2i(g.w, g.h) + Vector2i.ONE * TerrainMesh.MARGIN * 2
	for cz in ceili(float(_ext.y) / SIZE):
		for cx in ceili(float(_ext.x) / SIZE):
			_build(Vector2i(cx, cz))


func _build(c: Vector2i) -> void:
	var c0 := c * SIZE
	var c1 := Vector2i(mini(_ext.x, c0.x + SIZE), mini(_ext.y, c0.y + SIZE))
	var mi: MeshInstance3D = chunks.get(c)
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = "Chunk_%d_%d" % [c.x, c.y]
		mi.material_override = material
		add_child(mi)
		chunks[c] = mi
	mi.mesh = TerrainMesh.build_region(grid, cave, noise, c0, c1)


## A cell's height moves the vertices up to one cell around it, so mark the 3x3 block.
func mark(cells: Array) -> void:
	for cell in cells:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var e := Vector2i(cell.x + dx, cell.y + dz) + Vector2i.ONE * TerrainMesh.MARGIN
				dirty[Vector2i(floori(float(e.x) / SIZE), floori(float(e.y) / SIZE))] = true


func update(budget := REBUILDS_PER_FRAME) -> void:
	for c in dirty.keys():
		if budget <= 0:
			return
		dirty.erase(c)
		if chunks.has(c):
			_build(c)
			budget -= 1


## Rebuild everything pending now (tests, debug).
func flush() -> void:
	update(dirty.size())
