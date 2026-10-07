class_name StrongholdMeshes
## Decoration on top of castle terrain (the walls, spire and plateau are terrain cells).
## Gates and the drawbridge are hard-light fields tinted by who may pass: red for the enemy,
## cyan for you, amber when the winch is down and anyone can cross. Builds the castle's
## `view` (Nodes only, keyed like the state) and refreshes it from the state.

const ENEMY := Color("ff3a6a")
const PLAYER := Color("5fd4ff")
const OPEN := Color("ffb347")
const STONE := Color("8a8478")


static func cell_pos(x: int, z: int, level: float) -> Vector3:
	return Vector3((x + 0.5) * Config.CELL, level * Config.LEVEL_H, (z + 0.5) * Config.CELL)


static func _energy(c: Color, alpha := 0.38) -> StandardMaterial3D:
	var m := StructureMeshes.mat(c, 0.0, 0.2, c, 1.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = alpha
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Centre (world, at `level`) and size in metres of the box around `cells`.
static func _bounds(cells: Array, level: float) -> Array:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := -lo
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var size := Vector2(hi.x - lo.x + 1, hi.y - lo.y + 1) * Config.CELL
	var centre := Vector3((lo.x + hi.x + 1) * 0.5 * Config.CELL, level * Config.LEVEL_H, (lo.y + hi.y + 1) * 0.5 * Config.CELL)
	return [centre, size]


static func build(world: World, lay: Dictionary) -> Dictionary:
	var root := Node3D.new()
	root.name = "Castle"
	world.add_child(root)
	var v := { "root": root, "segs": [], "gates": [] }
	var top: float = lay.wall_top
	var stone := StructureMeshes.mat(STONE, 0.1, 0.9)
	var outward := { "n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0) }
	for seg in lay.segments:
		var b := _bounds(seg.cells, top)
		var a := Node3D.new()
		a.position = b[0]
		root.add_child(a)
		for i in range(0, seg.cells.size(), 2):  # even cells are the outer row: merlons
			var c: Vector2i = seg.cells[i]
			var off: Vector3 = cell_pos(c.x, c.y, top) - a.position + outward[seg.side] * 0.6
			StructureMeshes.box(a, Vector3(0.8, 0.9, 0.8), stone, off + Vector3(0, 0.45, 0))
		v.segs.append(a)
	for gt in lay.gates:
		var b := _bounds(gt.cells, lay.yard)
		var curtain := StructureMeshes.box(root, Vector3(b[1].x, Grid.GATE_H * Config.LEVEL_H, b[1].y), _energy(ENEMY))
		curtain.position = b[0] + Vector3(0, Grid.GATE_H * Config.LEVEL_H * 0.5, 0)
		v.gates.append(curtain)
	if not lay.bridge.is_empty():
		var b := _bounds(lay.bridge, lay.yard)
		var along: Vector2 = b[1] + (Vector2(0, 2) if b[1].y < b[1].x else Vector2(2, 0))  # cover the end slopes
		v["deck"] = StructureMeshes.box(root, Vector3(along.x, 0.3, along.y), _energy(ENEMY, 0.55))
		v.deck.position = b[0] - Vector3(0, 0.15, 0)
		var w := Node3D.new()
		w.position = cell_pos(lay.winch.x, lay.winch.y, lay.yard)
		root.add_child(w)
		StructureMeshes.cyl(w, 0.5, 0.8, 1.6, StructureMeshes.mat(Color("2a2a36"), 0.6, 0.4), 0.0, 8)
		v["winch_glow"] = StructureMeshes.ball(w, 0.45, _energy(ENEMY, 0.9), Vector3(0, 2.0, 0))
		v["winch"] = w
	for route in lay.climbs:  # stone caps show where the pillars can be landed on
		for c in route:
			var cap := StructureMeshes.box(root, Vector3(1.2, 0.3, 1.2), stone)
			cap.position = cell_pos(c.x, c.y, world.grid.height_at(c.x, c.y)) - Vector3(0, 0.12, 0)
	var sp: Dictionary = lay.spire
	var crown := Node3D.new()  # crown nest: a dark husk round a pulsing red sac
	StructureMeshes.cyl(crown, 1.2, 2.0, 1.2, StructureMeshes.mat(Color("2a1420"), 0.1, 0.8), 0.0, 9)
	var sac := Node3D.new()
	sac.name = "Sac"
	sac.position.y = 1.9
	crown.add_child(sac)
	StructureMeshes.ball(sac, 1.2, StructureMeshes.mat(Color("ff3a6a"), 0.0, 0.4, Color("ff3a6a"), 0.7))
	crown.position = cell_pos(sp.centre.x, sp.centre.y, sp.top)
	root.add_child(crown)
	v["crown"] = crown
	if not sp.pad.is_empty():
		var pad := HazardMeshes.pad()
		pad.position = (cell_pos(sp.pad[0].x, sp.pad[0].y, 0) + cell_pos(sp.pad[1].x, sp.pad[1].y, 0)) * 0.5
		pad.position.y = world.grid.height_at(sp.pad[0].x, sp.pad[0].y) * Config.LEVEL_H
		root.add_child(pad)
	var pump := Node3D.new()
	pump.position = cell_pos(lay.pump_at.x, lay.pump_at.y, lay.yard)
	root.add_child(pump)
	StructureMeshes.cyl(pump, 0.6, 0.9, 2.4, StructureMeshes.mat(Color("2a2036"), 0.5, 0.5), 0.0, 8)
	v["pump_glow"] = StructureMeshes.cyl(pump, 0.35, 0.35, 0.6, _energy(Color("3d7bff"), 0.9), 2.4, 8)
	v["pump"] = pump
	return v


## Colours and visibility from the state (call after any change).
static func refresh(v: Dictionary, c: Dictionary) -> void:
	var col := ENEMY if c.owner == "enemy" else PLAYER
	for i in v.segs.size():
		(v.segs[i] as Node3D).visible = c.walls[i].hp > 0.0
	for i in v.gates.size():
		var g: MeshInstance3D = v.gates[i]
		g.visible = c.gates[i].hp > 0.0
		g.material_override = _energy(col)
	if v.has("deck"):
		var open: bool = c.winch.hp <= 0.0
		(v.deck as MeshInstance3D).material_override = _energy(OPEN if open else col, 0.55)
		(v.winch_glow as MeshInstance3D).material_override = _energy(OPEN if open else col, 0.9)
		(v.winch_glow as Node3D).visible = not open
	(v.crown as Node3D).visible = c.state == "hostile"


static func animate(v: Dictionary, c: Dictionary, t: float) -> void:
	var sac := (v.crown as Node3D).get_node("Sac") as Node3D
	sac.scale = Vector3.ONE * (0.6 + 0.4 * c.crown.hp / c.crown.max_hp) * (1.0 + 0.06 * sin(t * 3.0))
	var glow := v.pump_glow as Node3D
	glow.scale.y = 1.0 + minf(3.0, c.pump.intake) * (0.5 + 0.5 * sin(t * 6.0))
	glow.visible = c.pump.jam <= 0.0
