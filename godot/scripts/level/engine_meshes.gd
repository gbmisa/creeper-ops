class_name EngineMeshes
extends RefCounted
## Salvage Engine models: rusted bronze and stone machine parts dressing the stamped terrain
## body (EngineShape), a glowing socket ring per hook point, and the cable to the network.
## Sockets glow dim amber when free, bright green when hooked, dark when the engine is spent.

const FREE := Color("ffb347")
const HOOKED := Color("6dffb0")
const DEAD := Color("2a2622")


## Root at the footprint centre on the floor. Returns it (the caller adds it to the world).
static func model(row: Dictionary) -> Node3D:
	var k := EngineDefs.kind(row)
	var root := Node3D.new()
	root.name = "Engine_" + str(row.get("id", "x"))
	var cell := Config.CELL
	root.position = Vector3((int(row.x) + 0.5) * cell, float(row.floor) * Config.LEVEL_H, (int(row.z) + 0.5) * cell)
	var w := float(k.w) * cell
	var d := float(k.d) * cell
	var h := float(k.top) * Config.LEVEL_H
	var bronze := StructureMeshes.pal("bronze")
	var rust := StructureMeshes.mat(Color("5a3f2a"), 0.55, 0.75)
	var dark := StructureMeshes.mat(Color("2e2822"), 0.3, 0.85)
	match str(row.kind):
		"wreck":
			_wreck(root, w, d, h, bronze, rust, dark)
		"bore":
			_bore(root, w, d, h, bronze, rust, dark)
		_:
			_forge(root, w, d, h, bronze, rust, dark)
	return root


## The fallen titan: rib arches over its back, a spine, a cracked head with a dying eye.
static func _wreck(root: Node3D, w: float, d: float, h: float, bronze: Material, rust: Material, dark: Material) -> void:
	for i in 4:
		var x := -w * 0.5 + 1.4 + float(i) * (w - 2.8) / 3.0
		var rib := StructureMeshes.torus(root, d * 0.5, d * 0.62, rust, Vector3(x, h, 0))
		rib.rotation = Vector3(0, 0, PI * 0.5)  # ring axis along the body: an arch over the back
	var spine := StructureMeshes.cyl(root, 0.32, 0.32, w * 0.95, bronze, 0.0, 8)
	spine.rotation.z = PI * 0.5
	spine.position = Vector3(0, h + d * 0.36, 0)
	var head := StructureMeshes.ball(root, 1.35, rust, Vector3(-w * 0.5 - 0.2, h * 0.7, 0), 10)
	head.scale = Vector3(1.2, 0.9, 1.0)
	StructureMeshes.ball(root, 0.24, StructureMeshes.glow(Color("ff8a2a"), 1.2), Vector3(-w * 0.5 - 1.4, h * 0.78, -0.45), 8)
	var arm := StructureMeshes.cyl(root, 0.35, 0.5, 4.0, rust, 0.0, 8)  # a fallen arm along the south edge
	arm.rotation.z = PI * 0.5
	arm.position = Vector3(w * 0.5 + 1.6, 0.5, d * 0.5 + 0.3)
	StructureMeshes.box(root, Vector3(1.8, 0.5, 1.0), dark, Vector3(w * 0.5 - 1.0, h + 0.15, -d * 0.25))


## The buried bore: a drill head thrusting out of the ground, ringed and tilted.
static func _bore(root: Node3D, w: float, d: float, h: float, bronze: Material, rust: Material, dark: Material) -> void:
	var r := minf(w, d) * 0.5
	var drill := Node3D.new()
	drill.rotation = Vector3(0.28, 0.0, 0.18)
	drill.position = Vector3(0, h - 0.1, 0)
	root.add_child(drill)
	StructureMeshes.cyl(drill, 0.15, r * 0.95, 3.4, bronze, 0.0, 12)
	for i in 4:
		var ring := StructureMeshes.torus(drill, r * (0.78 - 0.17 * i), r * (0.95 - 0.19 * i), dark, Vector3(0, 0.45 + 0.7 * i, 0))
		ring.scale.y = 0.4
	StructureMeshes.cyl(root, r * 0.9, r * 1.0, 0.5, rust, h - 0.4, 12)


## The ruined forge: chimneys, a great gear on the east face and a dead furnace on top.
static func _forge(root: Node3D, w: float, d: float, h: float, bronze: Material, rust: Material, dark: Material) -> void:
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1)]:
		var tower := StructureMeshes.cyl(root, 0.55, 0.75, 3.0, rust, h - 0.04, 10)
		tower.position.x = c.x * (w * 0.5 - 1.0)
		tower.position.z = c.y * (d * 0.5 - 1.0)
		StructureMeshes.torus(root, 0.45, 0.62, dark, Vector3(c.x * (w * 0.5 - 1.0), h + 3.0, c.y * (d * 0.5 - 1.0)))
	var gear := StructureMeshes.torus(root, 1.7, 2.3, bronze, Vector3(w * 0.5 + 0.1, h * 0.55, 0))
	gear.rotation.z = PI * 0.5
	for i in 6:
		var a := float(i) * PI / 3.0
		StructureMeshes.box(root, Vector3(0.5, 0.5, 0.9), bronze, Vector3(w * 0.5 + 0.1, h * 0.55 + sin(a) * 2.4, cos(a) * 2.4))
	StructureMeshes.cyl(root, 1.4, 1.7, 0.8, dark, h - 0.04, 10)
	StructureMeshes.ball(root, 0.7, StructureMeshes.glow(Color("ff6a1a"), 1.2), Vector3(0, h + 0.9, 0), 8)


## A glowing ring on a short post at the socket. Returns the node and its material.
static func socket(world: Node3D, pos: Vector3) -> Dictionary:
	var node := Node3D.new()
	node.name = "EngineSocket"
	node.position = pos
	world.add_child(node)
	var m := StructureMeshes.mat_new(Color("3a2a18"), 0.4, 0.5, FREE, 1.6)
	var ring := StructureMeshes.torus(node, 0.16, 0.3, m)
	ring.rotation.x = PI * 0.5
	StructureMeshes.ball(node, 0.12, m, Vector3.ZERO, 8)
	return { "node": node, "mat": m }


static func tint(sock: Dictionary, color: Color, energy: float) -> void:
	var m := sock.mat as StandardMaterial3D
	m.emission = color
	m.emission_energy_multiplier = energy


## Points of a sagging cable from a to b.
static func cable_points(a: Vector3, b: Vector3) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n := 14
	var sag := minf(2.5, a.distance_to(b) * 0.1)
	for i in n + 1:
		var t := float(i) / float(n)
		pts.append(a.lerp(b, t) - Vector3(0, sag * sin(PI * t), 0))
	return pts


## A thin crossed-ribbon cable along `pts` (two quads per segment, visible from every side).
static func cable_mesh(pts: PackedVector3Array, width := 0.16) -> ImmediateMesh:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		for off in [Vector3(0, width, 0), Vector3(width, 0, 0)]:
			var o: Vector3 = off
			for v in [a - o, a + o, b + o, a - o, b + o, b - o]:
				im.surface_add_vertex(v)
	im.surface_end()
	return im


static func cable_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("8fe8ff")
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func along(pts: PackedVector3Array, t: float) -> Vector3:
	var f := clampf(t, 0.0, 0.9999) * float(pts.size() - 1)
	var i := int(f)
	return pts[i].lerp(pts[i + 1], f - float(i))
