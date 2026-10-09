class_name CastleFires
## Braziers and torches for castle interiors (Stage 21b P2). Each builder returns
## { light, base, seed, kind } for the flicker pass in StrongholdMeshes.animate.
## Decoration only: walkers read the grid.


## Iron brazier: stone foot, iron stem and bowl, glowing embers, a flickering light.
static func brazier(parent: Node3D, floor_y: float, at: Vector3, seed: float) -> Dictionary:
	var n := Node3D.new()
	n.position = Vector3(at.x, floor_y, at.z)
	parent.add_child(n)
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var iron := StructureMeshes.pal("iron")
	StructureMeshes.box(n, Vector3(0.9, 0.5, 0.9), stone, Vector3(0, 0.25, 0))
	StructureMeshes.cyl(n, 0.09, 0.13, 0.8, iron, 0.5, 8)
	ShapeKit.lathe(n, PackedVector2Array([Vector2(0.08, 0.0), Vector2(0.5, 0.12),
		Vector2(0.55, 0.3), Vector2(0.45, 0.32)]), iron, Vector3(0, 1.3, 0), 10)
	StructureMeshes.ball(n, 0.3, StructureMeshes.glow(Color("ff7a2a"), 2.0), Vector3(0, 1.55, 0), 8)
	var l := OmniLight3D.new()
	l.light_color = Color("ff9a4d")
	l.light_energy = CastleDefs.BRAZIER_ENERGY
	l.omni_range = CastleDefs.BRAZIER_RANGE
	l.shadow_enabled = false
	l.position = Vector3(0, 2.3, 0)
	n.add_child(l)
	return { "light": l, "base": CastleDefs.BRAZIER_ENERGY, "seed": seed, "kind": "brazier" }


## Wall torch: iron bracket, an angled wooden haft and a flame; a small warm light.
static func torch(parent: Node3D, at: Vector3, facing: Vector3, seed: float) -> Dictionary:
	var n := Node3D.new()
	n.position = at
	parent.add_child(n)
	var iron := StructureMeshes.pal("iron")
	var oak := StructureMeshes.pal("oak")
	StructureMeshes.box(n, Vector3(0.14, 0.14, 0.34), iron, Vector3.ZERO)
	var tip := Vector3(0, 0.75, 0) + facing * 0.25
	ShapeKit.rod(n, Vector3(0, 0.05, 0), tip, 0.05, oak, 6)
	StructureMeshes.ball(n, 0.15, StructureMeshes.glow(Color("ffa03a"), 2.0), tip + Vector3(0, 0.1, 0), 7)
	var l := OmniLight3D.new()
	l.light_color = Color("ffab54")
	l.light_energy = CastleDefs.TORCH_ENERGY
	l.omni_range = CastleDefs.TORCH_RANGE
	l.shadow_enabled = false
	l.position = tip + Vector3(0, 0.15, 0)
	n.add_child(l)
	return { "light": l, "base": CastleDefs.TORCH_ENERGY, "seed": seed, "kind": "torch" }


## Flicker one fire entry (called from StrongholdMeshes.animate).
static func flicker(f: Dictionary, t: float) -> void:
	var l: OmniLight3D = f.light
	var s: float = f.seed
	l.light_energy = float(f.base) * (0.82 + 0.18 * (0.5 + 0.5 * sin(t * 11.0 + s))
		* (0.6 + 0.4 * sin(t * 23.0 + s * 1.7)))


## The gatehouse's inner side: toward the outer rect's centre, or the inner rect's for
## the inner gatehouse (its towers open to the ward, never the bailey).
static func gate_inner_dir(lay: Dictionary, centre: Vector2i) -> Vector2i:
	var r: Rect2i = lay.rect
	if (lay.inner_rect as Rect2i).grow(2).has_point(centre):
		r = lay.inner_rect
	var to := Vector2i(r.get_center()) - centre
	if absi(to.x) >= absi(to.y):
		return Vector2i(signi(to.x), 0)
	return Vector2i(0, signi(to.y))
