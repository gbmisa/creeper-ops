class_name CastleInteriorMeshes
## Roof slabs over castle interiors (lay.interiors, Grid.roof) and the warm light inside them.
## One merged mesh per interior: a top face at the roof level, an underside GridRoofs.ROOF_THICK
## lower, and edge faces where the roof ends. The slab uses the castle ashlar shader
## (shaders/castle_slab.gdshader), the same stone logic as the terrain walls; oak beams run
## under it every CastleDefs.SLAB_BEAM_EVERY cells. Decoration only: walkers read Grid.roof.

static var _slab_mat: ShaderMaterial


static func slab_mat() -> ShaderMaterial:
	if _slab_mat == null:
		_slab_mat = ShaderMaterial.new()
		_slab_mat.shader = load("res://shaders/castle_slab.gdshader")
	return _slab_mat


static func build(root: Node3D, g: Grid, lay: Dictionary, banners: Array = [], fires: Array = []) -> Array:
	var out := []
	var seed := 0.0
	for it in lay.get("interiors", []):
		var node := Node3D.new()
		node.name = "Interior_%s" % it.kind
		root.add_child(node)
		var mi := MeshInstance3D.new()
		var top: float = float(it.roof) * Config.LEVEL_H
		mi.mesh = _slab(it.cells, top)
		mi.set_surface_override_material(0, slab_mat())
		mi.set_surface_override_material(1, slab_mat())
		node.add_child(mi)
		_beams(node, it.cells, top - GridRoofs.ROOF_THICK)
		_fires(node, g, lay, it, fires, seed)
		seed += 1.37
		out.append(node)
	return out


## Oak beams under the slab, one per cell row every SLAB_BEAM_EVERY cells.
static func _beams(node: Node3D, cells: Array, under: float) -> void:
	var oak := StructureMeshes.pal("oak")
	var step: int = CastleDefs.SLAB_BEAM_EVERY
	for c in cells:
		if int(c.y) % step != 0:
			continue
		StructureMeshes.box(node, Vector3(Config.CELL + 0.06, 0.28, 0.28), oak,
			Vector3((c.x + 0.5) * Config.CELL, under - 0.14, (c.y + 0.5) * Config.CELL))


## Braziers in the gate halls and the keep hall; two torches on each gatehouse's inner
## face. Tower stairs stay unlit. Appends CastleFires entries to `fires`.
static func _fires(node: Node3D, g: Grid, lay: Dictionary, it: Dictionary, fires: Array, seed: float) -> void:
	if it.kind != "gatehouse" and it.kind != "hall":
		return
	var c: Vector2i = it.light
	if not g.in_bounds(c.x, c.y):
		c = it.cells[it.cells.size() / 2]
	if it.kind == "gatehouse":
		var inward := CastleFires.gate_inner_dir(lay, c)
		var bc: Vector2i = c + inward
		if not it.cells.has(bc):
			bc = c
		var floor_y := g.height_at(bc.x, bc.y) * Config.LEVEL_H
		fires.append(CastleFires.brazier(node, floor_y,
			Vector3((bc.x + 0.5) * Config.CELL, 0, (bc.y + 0.5) * Config.CELL), seed))
		_torches(node, g, it, inward, fires, seed)
	else:
		var cc: Vector2i = c
		if bool((lay.get("keep", {}) as Dictionary).get("column", false)):
			cc = c + Vector2i(3, 3)  # clear of the 3x3 spire column through the hall
			if not it.cells.has(cc):
				cc = c
		var floor_y := g.height_at(cc.x, cc.y) * Config.LEVEL_H
		fires.append(CastleFires.brazier(node, floor_y,
			Vector3((cc.x + 0.5) * Config.CELL, 0, (cc.y + 0.5) * Config.CELL), seed))


## Two torches flanking the passage's inner opening, at the end row's side cells.
static func _torches(node: Node3D, g: Grid, it: Dictionary, inward: Vector2i, fires: Array, seed: float) -> void:
	var far := -(1 << 20)
	for c in it.cells:
		far = maxi(far, c.x * inward.x + c.y * inward.y)
	var row: Array = it.cells.filter(func(c): return c.x * inward.x + c.y * inward.y == far)
	var perp := Vector2i(-inward.y, inward.x)
	row.sort_custom(func(a, b): return a.x * perp.x + a.y * perp.y < b.x * perp.x + b.y * perp.y)
	var facing := Vector3(inward.x, 0, inward.y)
	for tc in [row[0], row[row.size() - 1]]:
		var floor_y := g.height_at(tc.x, tc.y) * Config.LEVEL_H
		var at := Vector3((tc.x + 0.5) * Config.CELL, floor_y + 2.2, (tc.y + 0.5) * Config.CELL)
		fires.append(CastleFires.torch(node, at, facing, seed + 0.61))


## Surface 0: top faces and edges; surface 1: the underside (seen from inside).
static func _slab(cells: Array, top: float) -> ArrayMesh:
	var set := {}
	for c in cells:
		set[c] = true
	var cs := Config.CELL
	var bot := top - GridRoofs.ROOF_THICK
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var su := SurfaceTool.new()
	su.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in cells:
		var x0: float = c.x * cs
		var z0: float = c.y * cs
		_quad(st, Vector3(x0, top, z0), Vector3(x0 + cs, top, z0), Vector3(x0 + cs, top, z0 + cs), Vector3(x0, top, z0 + cs), Vector3.UP)
		_quad(su, Vector3(x0, bot, z0 + cs), Vector3(x0 + cs, bot, z0 + cs), Vector3(x0 + cs, bot, z0), Vector3(x0, bot, z0), Vector3.DOWN)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if set.has(c + d):
				continue
			var n := Vector3(d.x, 0, d.y)
			var mid := Vector3(x0 + cs * 0.5, 0, z0 + cs * 0.5) + n * cs * 0.5
			var t := Vector3(-d.y, 0, d.x) * cs * 0.5
			_quad(st, mid - t + Vector3(0, top, 0), mid + t + Vector3(0, top, 0), mid + t + Vector3(0, bot, 0), mid - t + Vector3(0, bot, 0), n)
	var mesh := st.commit()
	su.commit(mesh)
	return mesh


## Two triangles a-b-c, a-c-d, wound so the face looks along `n` (Godot culls by winding).
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	var face := (b - a).cross(c - a)
	if face.dot(n) > 0.0:  # Godot's front faces are clockwise seen from outside
		var t := b
		b = d
		d = t
	for v in [a, b, c, a, c, d]:
		st.set_normal(n)
		st.add_vertex(v)
