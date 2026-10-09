class_name CastleSocketLook
## Makes empty turret sockets obvious. 3D: a stone plinth with a glowing ring and bolts on
## every empty socket (bright on castles you hold, dim on others), hidden once a turret
## stands. Command mode: a ground ring on the terrain shader (`sockets` uniform) while a
## turret tool is armed or the pointer is over a held castle. FPS: a minor marker.

const GLOW := Color("ffe9a8")
const HELD_E := 2.4
const OTHER_E := 0.7
const HOVER_PAD := 6  # cells around a castle's outer wall that count as "hovering" it
const BEACON_H := 5.2  # clears the tower cone and flag post
const MAX_RINGS := 48


static func build(world: World, v: Dictionary, c: Dictionary) -> void:
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.9)
	var iron := StructureMeshes.pal("iron")
	var glow := StructureMeshes.mat_new(GLOW, 0.0, 0.5, GLOW, OTHER_E)
	v["sock_glow"] = glow
	var fx := []
	for i in c.sockets.size():
		var n := Node3D.new()
		var base: Node3D = v.turrets[i]
		n.position = base.position
		world.add_child(n)
		ShapeKit.lathe(n, PackedVector2Array([Vector2(1.15, 0.0), Vector2(1.1, 0.16), Vector2(0.95, 0.22), Vector2(0.0, 0.22)]), stone, Vector3.ZERO, 12)
		ShapeKit.lathe(n, PackedVector2Array([Vector2(1.0, 0.2), Vector2(1.0, 0.3), Vector2(0.84, 0.3), Vector2(0.84, 0.2)]), glow, Vector3.ZERO, 16)
		for k in 4:  # bolt pattern
			var a := TAU * (float(k) + 0.5) / 4.0
			StructureMeshes.ball(n, 0.1, glow, Vector3(cos(a) * 0.55, 0.3, sin(a) * 0.55), 6)
		ShapeKit.lathe(n, PackedVector2Array([Vector2(0.28, 0.22), Vector2(0.2, 0.34), Vector2(0.0, 0.34)]), iron, Vector3.ZERO, 8)
		# Beacon: corner towers wear cone roofs, so a post and a floating gem rise above them.
		ShapeKit.rod(n, Vector3(0, 0.3, 0), Vector3(0, BEACON_H, 0), 0.05, iron, 5)
		var gem := ShapeKit.lathe(n, PackedVector2Array([Vector2(0.0, -0.9), Vector2(0.55, 0.0), Vector2(0.0, 0.9)]), glow, Vector3(0, BEACON_H + 0.5, 0), 4)
		gem.name = "Gem"
		fx.append(n)
	v["sock_fx"] = fx


## Per frame: show on empty sockets only; held castles glow brighter and pulse.
static func update(v: Dictionary, c: Dictionary, t: float) -> void:
	if not v.has("sock_fx"):
		return
	for i in c.sockets.size():
		var fx: Node3D = v.sock_fx[i]
		fx.visible = not CastleTurrets.alive(c.sockets[i])
		var gem := fx.get_node_or_null("Gem") as Node3D
		if gem:
			gem.rotation.y = t * 1.5 + float(i)
			gem.position.y = BEACON_H + 0.5 + 0.12 * sin(t * 2.0 + float(i))
	var m: StandardMaterial3D = v.sock_glow
	m.emission_energy_multiplier = HELD_E * (0.75 + 0.25 * sin(t * 3.0)) if c.owner == "player" else OTHER_E


## FPS: minor "Turret socket" markers on empty sockets of castles you hold.
static func markers(world: World, v: Dictionary, c: Dictionary) -> void:
	for i in c.sockets.size():
		var idx: int = i
		world.markers.append({ "pos": (v.turrets[i] as Node3D).position + Vector3(0, 2.2, 0),
			"label": "Turret socket [%s]" % Keybinds.short("use"), "color": GLOW, "minor": true,
			"visible": func(): return c.owner == "player" and not CastleTurrets.alive(c.sockets[idx]) })


## Command mode: ring every empty socket. `armed` (turret tool) also dimly shows hostile ones.
static func highlight(s: Strongholds, armed: bool, hover: Dictionary) -> void:
	if s == null or s.world.terrain_mat == null:
		return
	var cell: Vector2i = hover.get("cell", Vector2i(-999, -999))
	var packed := PackedVector4Array()
	packed.resize(MAX_RINGS)
	var n := 0
	for c in s.list:
		var held: bool = c.owner == "player"
		var lay: Dictionary = s.lays[c.id]
		var near: bool = (lay.rect as Rect2i).grow(HOVER_PAD).has_point(cell)
		if not (armed or (held and near)) or (not held and not armed):
			continue
		for sk in c.sockets:
			if CastleTurrets.alive(sk) or n >= MAX_RINGS:
				continue
			var p := s.world.grid.cell_ground(sk.cell.x, sk.cell.y)
			packed[n] = Vector4(p.x, p.z, 3.4, 1.0 if held else 0.3)
			n += 1
	if packed != s.sock_cache:
		s.sock_cache = packed
		s.world.terrain_mat.set_shader_parameter("sockets", packed)
