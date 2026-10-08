class_name CastleDecor
## Pure decoration on a castle's terrain walls: round corner towers with slate cone roofs and
## flags, and a gatehouse (two square towers, a stone arch and a crenellated breastwork) on
## every gate. Banner meshes are returned so StrongholdMeshes.refresh can dye them in the
## owner's colour. No collision: walkers only ever read the grid.

const ENEMY_CLOTH := Color("b8243a")
const PLAYER_CLOTH := Color("2a8fc4")


## Faction tint on gate/bridge trim: dim, so it marks ownership without glowing.
static func trim(c: Color) -> StandardMaterial3D:
	return StructureMeshes.mat(c.darkened(0.3), 0.0, 0.6, c, 0.3)


static func cloth(owner: String) -> StandardMaterial3D:
	return StructureMeshes.mat(ENEMY_CLOTH if owner == "enemy" else PLAYER_CLOTH, 0.0, 0.95)


## Builds the decor under `root`; returns every banner MeshInstance3D.
static func build(root: Node3D, lay: Dictionary) -> Array:
	var banners: Array = []
	var r: Rect2i = lay.rect
	var lh := Config.LEVEL_H
	var c := Config.CELL
	var base: float = (lay.floor - 3) * lh
	var top: float = lay.wall_top * lh
	var corners := [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)]
	var centre := Vector3(r.get_center().x * c, 0, r.get_center().y * c)
	for tw in lay.get("towers", []):  # terrain towers (CastleTowers): crown them, guards stand on top
		_tower_crown(root, tw, centre, banners)
	if lay.get("towers", []).is_empty():
		for k in corners:
			var p := Vector3(k.x * c, 0, k.y * c)
			var t := Node3D.new()
			t.position = p
			root.add_child(t)
			_round_tower(t, base, top + 2.6, 2.1, banners, (p - centre).normalized())
	for gt in lay.gates:
		_gatehouse(root, gt, lay, banners)
	_spire_trim(root, lay)
	return banners


## Carved stone bands round the obsidian spire column, and corner finials at its top.
static func _spire_trim(root: Node3D, lay: Dictionary) -> void:
	var sp: Dictionary = lay.spire
	var c := Vector3((sp.centre.x + 0.5) * Config.CELL, 0, (sp.centre.y + 0.5) * Config.CELL)
	var half := 1.5 * Config.CELL + 0.12
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var y0: int = lay.yard
	var top: int = sp.top
	for lvl in range(y0 + 6, top + 1, 5):
		var y := lvl * Config.LEVEL_H - (0.25 if lvl < top else 0.0)
		for k in 4:
			var along := Vector3(half * 2.0 + 0.24, 0.4, 0.24) if k < 2 else Vector3(0.24, 0.4, half * 2.0 + 0.24)
			var off := Vector3(0, 0, half if k == 0 else -half) if k < 2 else Vector3(half if k == 2 else -half, 0, 0)
			StructureMeshes.box(root, along, stone, c + off + Vector3(0, y, 0))
	var obsidian := StructureMeshes.mat(Color("1d1924"), 0.4, 0.12)
	var vein := StructureMeshes.mat(Color("5a2a8a"), 0.0, 0.3, Color("8a3aff"), 0.6)
	var h0 := y0 * Config.LEVEL_H
	var h1 := top * Config.LEVEL_H
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:  # faceted obsidian ribs up the column corners
			var rib := ShapeKit.lathe(root, PackedVector2Array([Vector2(0.55, 0.0), Vector2(0.4, h1 - h0), Vector2(0.0, h1 - h0 + 1.2)]),
				obsidian, c + Vector3(sx * (half - 0.1), h0, sz * (half - 0.1)), 4)
			rib.rotation.y = PI / 4.0
			for k in 3:  # obsidian shard cluster jutting from each top corner
				var tilt := Vector3(sx, 0, sz).normalized().rotated(Vector3.UP, (k - 1) * 0.6)
				var base := c + Vector3(sx * half, h1 - 0.5, sz * half)
				ShapeKit.taper(root, base, base + tilt * 1.2 + Vector3(0, 2.6 - k * 0.5, 0), 0.45, 0.02, obsidian, 5)
	for k in 4:  # glassy violet veins zig-zagging down each face
		var n := Vector3(1, 0, 0).rotated(Vector3.UP, k * PI / 2.0)
		var t := n.cross(Vector3.UP)
		var p := c + n * (half + 0.02) + Vector3(0, h1 - 1.0, 0)
		for j in 3:
			var q := p + t * (0.9 if j % 2 == 0 else -0.9) + Vector3(0, -(h1 - h0) * 0.28, 0)
			ShapeKit.strut(root, p, q, 0.32, vein, 0.1)
			p = q


## Battlements round a terrain tower's flat top (left open for its Sentinels), a corner
## flagpole and a long banner down its outer face.
static func _tower_crown(root: Node3D, tw: Dictionary, centre: Vector3, banners: Array) -> void:
	var b := StrongholdMeshes._bounds(tw.cells, tw.top)
	var mid: Vector3 = b[0]
	var size: Vector2 = b[1]
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var hx := size.x * 0.5 - 0.25
	var hz := size.y * 0.5 - 0.25
	for i in 5:  # merlons along each edge
		var f := -1.0 + i * 0.5
		for side in [Vector3(f * hx, 0, -hz), Vector3(f * hx, 0, hz), Vector3(-hx, 0, f * hz), Vector3(hx, 0, f * hz)]:
			StructureMeshes.box(root, Vector3(0.6, 0.8, 0.6), stone, mid + side + Vector3(0, 0.4, 0))
	var out := Vector3(mid.x - centre.x, 0, mid.z - centre.z).normalized()
	var pole := mid + Vector3(signf(out.x) * hx, 0, signf(out.z) * hz)
	ShapeKit.rod(root, pole, pole + Vector3(0, 4.5, 0), 0.06, StructureMeshes.pal("bronze"), 6)
	banners.append(StructureMeshes.box(root, Vector3(2.2, 1.3, 0.06), cloth("enemy"), pole + Vector3(1.1, 3.8, 0)))
	var hang := Node3D.new()
	hang.position = mid
	hang.rotation.y = atan2(out.x, out.z)
	root.add_child(hang)
	var face := (hz if absf(out.z) > absf(out.x) else hx) + 0.3
	for mi in ShapeKit.banner(hang, 1.4, 3.6, cloth("enemy"), Vector3(0, -0.3, face)).get_children():
		banners.append(mi)


static func _round_tower(t: Node3D, base: float, top: float, rad: float, banners: Array, out: Vector3) -> void:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	ShapeKit.lathe(t, PackedVector2Array([Vector2(rad * 1.12, base), Vector2(rad, base + 2.0), Vector2(rad, top - 0.6),
		Vector2(rad * 1.15, top - 0.3), Vector2(rad * 1.15, top), Vector2(0.0, top)]), stone, Vector3.ZERO, 12)
	for i in 8:
		var a := i * TAU / 8.0
		StructureMeshes.box(t, Vector3(0.7, 0.8, 0.5), stone, Vector3(cos(a) * rad * 1.05, top + 0.4, sin(a) * rad * 1.05)).rotation.y = -a
	for i in 4:  # arrow slits
		var a := i * TAU / 4.0 + PI / 4.0
		StructureMeshes.box(t, Vector3(0.2, 1.0, 0.2), StructureMeshes.mat(Color("1a1612"), 0.0, 1.0),
			Vector3(cos(a) * rad * 0.98, top - 2.2, sin(a) * rad * 0.98))
	ShapeKit.cone(t, rad * 1.05, 3.4, StructureMeshes.pal("slate"), Vector3(0, top + 0.6, 0), 12)
	ShapeKit.rod(t, Vector3(0, top + 3.8, 0), Vector3(0, top + 5.4, 0), 0.05, StructureMeshes.pal("bronze"), 6)
	var flag := StructureMeshes.box(t, Vector3(2.6, 1.5, 0.06), cloth("enemy"), Vector3(1.32, top + 4.6, 0))
	banners.append(flag)
	var hang := Node3D.new()  # long banner down the outer face
	hang.rotation.y = atan2(out.x, out.z)
	t.add_child(hang)
	for mi in ShapeKit.banner(hang, 1.6, 4.0, cloth("enemy"), Vector3(0, top - 0.4, rad + 0.06)).get_children():
		banners.append(mi)


static func _gatehouse(root: Node3D, gt: Dictionary, lay: Dictionary, banners: Array) -> void:
	var lh := Config.LEVEL_H
	var b := StrongholdMeshes._bounds(gt.cells, lay.yard)
	var g := Node3D.new()
	g.position = b[0]
	var out := { "n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0) }[gt.side] as Vector3
	g.rotation.y = 0.0 if gt.side in ["n", "s"] else PI / 2.0
	root.add_child(g)
	var face := 1.0 if (g.basis.inverse() * out).z > 0.0 else -1.0  # local z of the outer face
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	var wall_h: float = (lay.wall_top - lay.yard) * lh
	var low: float = -3.0 * lh
	for sx in [-1.0, 1.0]:
		var h := wall_h + 3.2 - low
		StructureMeshes.box(g, Vector3(2.6, h, 4.6), stone, Vector3(sx * 4.4, low + h * 0.5, 0))
		for mz in [-1.6, 0.0, 1.6]:
			StructureMeshes.box(g, Vector3(0.6, 0.8, 0.6), stone, Vector3(sx * 4.4 + sx * 1.0, wall_h + 3.6, mz))
		var bn := ShapeKit.banner(g, 1.9, 4.2, cloth("enemy"), Vector3(sx * 4.4, wall_h + 2.9, face * 2.34))
		for mi in bn.get_children():
			banners.append(mi)
	ShapeKit.arch(g, 6.2, 1.6, 0.5, 1.0, stone, Vector3(0, wall_h - 1.7, face * 1.9), 16)
	StructureMeshes.box(g, Vector3(6.2, 1.4, 1.0), stone, Vector3(0, wall_h + 0.5, face * 1.9))
	for i in 4:
		StructureMeshes.box(g, Vector3(0.7, 0.7, 0.6), stone, Vector3(-2.4 + i * 1.6, wall_h + 1.55, face * 2.1))


## Wooden portcullis across a gate (centre `at` on the yard, `size` m); returns [node, trims].
## The node sits where the old gate field did, so targets and hit heights are unchanged.
static func portcullis(root: Node3D, at: Vector3, size: Vector2) -> Array:
	var h := Grid.GATE_H * Config.LEVEL_H
	var n := Node3D.new()
	n.position = at + Vector3(0, h * 0.5, 0)
	n.rotation.y = 0.0 if size.x >= size.y else PI / 2.0
	root.add_child(n)
	var span := maxf(size.x, size.y)
	var oak := StructureMeshes.pal("oak")
	for i in 7:
		StructureMeshes.box(n, Vector3(0.18, h, 0.18), oak, Vector3(-span * 0.5 + 0.3 + i * (span - 0.6) / 6.0, 0, 0))
	for j in 4:
		StructureMeshes.box(n, Vector3(span, 0.14, 0.24), StructureMeshes.pal("iron"), Vector3(0, -h * 0.5 + 0.5 + j * (h - 0.8) / 3.0, 0))
	var trims := []
	trims.append(StructureMeshes.box(n, Vector3(span, 0.16, 0.3), trim(StrongholdMeshes.ENEMY), Vector3(0, h * 0.5 - 0.08, 0)))
	for sx in [-1.0, 1.0]:
		trims.append(StructureMeshes.box(n, Vector3(0.12, h, 0.3), trim(StrongholdMeshes.ENEMY), Vector3(sx * span * 0.5, 0, 0)))
	return [n, trims]


## Plank drawbridge (`along` m) with tinted rune edges; returns [planks, trims].
static func drawbridge(root: Node3D, at: Vector3, along: Vector2) -> Array:
	var planks := StructureMeshes.box(root, Vector3(along.x, 0.3, along.y), StructureMeshes.pal("oak"))
	planks.position = at
	var trims := []
	var x_long := along.x >= along.y
	for s in [-1.0, 1.0]:
		var edge := StructureMeshes.box(root, Vector3(along.x if x_long else 0.2, 0.36, 0.2 if x_long else along.y), trim(StrongholdMeshes.ENEMY))
		edge.position = at + (Vector3(0, 0.05, s * along.y * 0.5) if x_long else Vector3(s * along.x * 0.5, 0.05, 0))
		trims.append(edge)
	return [planks, trims]


## Winch: a stone block with an oak drum and iron chain wheel.
static func winch(w: Node3D) -> void:
	StructureMeshes.box(w, Vector3(1.6, 1.0, 1.2), StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92), Vector3(0, 0.5, 0))
	ShapeKit.rod(w, Vector3(-0.9, 1.4, 0), Vector3(0.9, 1.4, 0), 0.4, StructureMeshes.pal("oak"), 10)
	for sx in [-1.0, 1.0]:
		ShapeKit.rod(w, Vector3(sx * 0.95, 1.4, 0), Vector3(sx * 1.05, 1.4, 0), 0.55, StructureMeshes.pal("iron"), 10)


## Crown nest on the spire top: a fungal husk caged by curved, tapered bone ribs round a
## matte cluster of egg sacs ("Sac", scaled by StrongholdMeshes.animate) with green pustules.
static func crown_nest() -> Node3D:
	var crown := Node3D.new()
	ShapeKit.lathe(crown, PackedVector2Array([Vector2(2.1, 0.0), Vector2(1.8, 0.6), Vector2(1.3, 1.1),
		Vector2(1.5, 1.4), Vector2(0.0, 1.45)]), StructureMeshes.mat(Color("4a3a26"), 0.0, 0.95), Vector3.ZERO, 9)
	for i in 6:
		var a := i * TAU / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		ShapeKit.horn(crown, d * 1.6 + Vector3(0, 0.8, 0), d * 2.3 + Vector3(0, 2.4, 0), d * 1.2 + Vector3(0, 3.8, 0), 0.24, RaiderMeshes.bone())
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 1.9
	crown.add_child(sac)
	var flesh := StructureMeshes.mat(Color("6a2a3e"), 0.0, 0.95, Color("c02850"), 0.15)
	for e in [[Vector3(0, 0.1, 0), 0.95], [Vector3(0.6, -0.15, 0.35), 0.6], [Vector3(-0.5, -0.1, 0.45), 0.55],
			[Vector3(0.1, -0.2, -0.65), 0.6], [Vector3(-0.35, 0.55, -0.2), 0.5]]:
		StructureMeshes.ball(sac, e[1], flesh, e[0], 7)
	for p in [Vector3(0.55, 0.45, 0.2), Vector3(-0.6, 0.25, -0.4), Vector3(0.2, 0.75, 0.5)]:
		StructureMeshes.ball(sac, 0.16, RaiderMeshes.sick(), p, 5)
	return crown
