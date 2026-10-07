class_name CollectorField
extends RefCounted
## Collector land claim (CW green field). Each dry, non-Blight cell inside the SQUARE field
## (Chebyshev radius COLLECT_RADIUS) of a finished, connected collector yields energy. A cell
## counts once however many collectors overlap it, which rewards spreading out.
## Visuals: no per-cell quads. We upload a per-cell "claimed" mask and terrain.gdshader draws
## each claimed cell as a green grid tile on the ground.

const REFRESH := 0.5

var world: World
var income := 0.0
var cells := 0
var _timer := 0.0
var _img: Image
var _tex: ImageTexture
var _bytes := PackedByteArray()


func _init(w: World) -> void:
	world = w
	var g := w.grid
	_bytes.resize(g.w * g.h)
	_img = Image.create_from_data(g.w, g.h, false, Image.FORMAT_R8, _bytes)
	_tex = ImageTexture.create_from_image(_img)
	w.terrain_mat.set_shader_parameter("claim_tex", _tex)


## Cells of a collector's square field at (x, z).
static func field_cells(g: Grid, x: int, z: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r := Config.COLLECT_RADIUS
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if g.in_bounds(x + dx, z + dz):
				out.append(Vector2i(x + dx, z + dz))
	return out


func update(dt: float, collectors: Array) -> void:
	_timer -= dt
	if _timer > 0.0:
		return
	_timer = REFRESH
	var g := world.grid
	var depth := world.creeper.depth
	_bytes.fill(0)
	cells = 0
	for c in collectors:
		for cell in field_cells(g, c.x, c.z):
			var i := g.idx(cell.x, cell.y)
			if _bytes[i] == 0 and g.zone[i] != Grid.Zone.BLIGHT and depth[i] <= Config.MIN_DEPTH:
				_bytes[i] = 255
				cells += 1
	income = cells * Config.COLLECT_PER_CELL
	_img.set_data(g.w, g.h, false, Image.FORMAT_R8, _bytes)
	_tex.update(_img)
