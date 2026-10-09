class_name StrongholdMeshes
## Decoration on top of castle terrain (the walls, spire and plateau are terrain cells).
## Gates and the drawbridge are hard-light fields tinted by who may pass: red for the enemy,
## cyan for you, amber when the winch is down and anyone can cross. Builds the castle's
## `view` (Nodes only, keyed like the state) and refreshes it from the state.

const ENEMY := Color("ff3a6a")
const PLAYER := Color("5fd4ff")
const OPEN := Color("ffb347")
const STONE := Color("8a8478")
## Decor stone graded like terrain.gdshader grades the terrain walls, so merlons and towers
## match the wall tone under the dusk sun.
const DECOR_STONE := Color("808a70")
## Inner ring trim: a shade darker than the outer wall.
const INNER_STONE := Color("6b7560")


static func cell_pos(x: int, z: int, level: float) -> Vector3:
	return Vector3((x + 0.5) * Config.CELL, level * Config.LEVEL_H, (z + 0.5) * Config.CELL)


static var _energy_cache := {}


static func _energy(c: Color, alpha := 0.38) -> StandardMaterial3D:
	var key := "%s%s" % [c.to_html(), alpha]
	if _energy_cache.has(key):
		return _energy_cache[key]
	var m := StructureMeshes.mat_new(c, 0.0, 0.2, c, 1.6)
	_energy_cache[key] = m
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
	var v := { "root": root, "segs": [], "gates": [], "banners": CastleDecor.build(root, lay), "gate_trim": [] }
	v["lay"] = lay  # P8: the portcullis swing reads ring ownership from this
	var top: float = lay.wall_top
	var stone := StructureMeshes.mat(DECOR_STONE, 0.0, 0.92)
	var outward := { "n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0) }
	for seg in lay.segments:
		var b := _bounds(seg.cells, top)
		var a := Node3D.new()
		a.position = b[0]
		root.add_child(a)
		CastleStonework.wall_trim(a, world.grid, seg, lay, outward[seg.side])
		v.segs.append(a)
	for gt in lay.gates:
		var b := _bounds(gt.cells, lay.yard)
		var pc: Array = CastleDecor.portcullis(root, b[0], b[1])
		(pc[0] as Node3D).set_meta("base_y", (pc[0] as Node3D).position.y)
		(pc[0] as Node3D).set_meta("ring", (gt as Dictionary).get("ring", "outer"))
		v.gates.append(pc[0])
		v.gate_trim.append(pc[1])
	if not lay.bridge.is_empty():
		var b := _bounds(lay.bridge, lay.yard)
		var along: Vector2 = b[1] + (Vector2(0, 2) if b[1].y < b[1].x else Vector2(2, 0))  # cover the end slopes
		var dk: Array = CastleDecor.drawbridge(root, b[0] - Vector3(0, 0.15, 0), along)
		v["deck"] = dk[0]
		v["deck_trim"] = dk[1]
		var w := Node3D.new()
		w.position = cell_pos(lay.winch.x, lay.winch.y, lay.yard)
		root.add_child(w)
		CastleDecor.winch(w)
		v["winch_glow"] = StructureMeshes.crystal(w, 0.3, 0.8, _energy(ENEMY, 0.9), Vector3(0, 2.3, 0))
		v["winch"] = w
	for route in lay.climbs:  # stone caps show where the pillars can be landed on
		for c in route:
			var cap := StructureMeshes.box(root, Vector3(1.2, 0.3, 1.2), stone)
			cap.position = cell_pos(c.x, c.y, world.grid.height_at(c.x, c.y)) - Vector3(0, 0.12, 0)
	var sp: Dictionary = lay.spire
	var crown := CastleDecor.crown_nest()  # fungal husk round a pulsing red "Sac"
	var ca: Dictionary = lay.crown_at  # spire top (Stage 7) or the keep hall (concentric)
	crown.position = cell_pos(ca.cell.x, ca.cell.y, ca.level)
	if lay.get("plan", "") == "concentric":
		crown.position.y += CastleDefs.DAIS_H  # P3: the nest sits on the dais
	v["fires"] = []
	v["interiors"] = CastleInteriorMeshes.build(root, world.grid, lay, v.banners, v["fires"])
	CastleStonework.build(root, world.grid, lay)
	CastleProps.build(root, world.grid, lay)
	var cloth := CastleBanners.build(root, world.grid, lay, v.banners)
	for k in cloth:
		v[k] = cloth[k]
	var marks := CastleReadability.build_markers(root, lay, v)
	for k in marks:
		v[k] = marks[k]
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
		(v.gates[i] as Node3D).visible = c.gates[i].hp > 0.0
		_swing_gate(v, c, i)
		for t in v.gate_trim[i]:
			(t as MeshInstance3D).material_override = CastleDecor.trim(col)
	if v.has("deck"):
		var open: bool = c.winch.hp <= 0.0
		for t in v.deck_trim:
			(t as MeshInstance3D).material_override = CastleDecor.trim(OPEN if open else col)
		(v.winch_glow as MeshInstance3D).material_override = _energy(OPEN if open else col, 0.9)
		(v.winch_glow as Node3D).visible = not open
	(v.crown as Node3D).visible = c.state == "hostile"
	for b in v.banners:
		(b as MeshInstance3D).material_override = CastleDecor.cloth(c.owner)


## Portcullis swing (P8, visual only): the gate mesh (v.gates[i]) tweens up when its ring
## changes hands to you and back down when the enemy takes it. Idempotent: it only
## tweens when the target height differs, so every refresh() after a handoff moves it
## and nothing else does. Targets and hit heights are untouched (the node sits where
## the old gate field did; the 3.2 m aim height in stronghold_hooks.gd is unchanged).
static func _swing_gate(v: Dictionary, c: Dictionary, i: int) -> void:
	var n := v.gates[i] as Node3D
	if not n.has_meta("base_y"):
		n.set_meta("base_y", n.position.y)
	var base: float = n.get_meta("base_y")
	var lay: Dictionary = v.get("lay", {})
	var yours := false
	if not lay.is_empty() and float((c.gates[i] as Dictionary).get("hp", 0.0)) > 0.0:
		yours = CastleStages.ring_owner(c, lay, str(n.get_meta("ring", "outer"))) == "player"
	var want := base + (CastleDefs.PORTCULLIS_LIFT if yours else 0.0)
	n.set_meta("lift_t", want)  # the smoke test reads the target, not the tween
	if absf(n.position.y - want) < 0.01:
		return
	if n.has_meta("gate_tween"):
		var old = n.get_meta("gate_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	if n.is_inside_tree():
		var tw := n.create_tween()
		tw.tween_property(n, "position:y", want, CastleDefs.PORTCULLIS_TIME)\
			.set_trans(Tween.TRANS_SINE)
		n.set_meta("gate_tween", tw)
	else:
		n.position.y = want


static func animate(v: Dictionary, c: Dictionary, t: float) -> void:
	var sac := (v.crown as Node3D).get_node("Sac") as Node3D
	sac.scale = Vector3.ONE * (0.6 + 0.4 * c.crown.hp / c.crown.max_hp) * (1.0 + 0.06 * sin(t * 3.0))
	var glow := v.pump_glow as Node3D
	glow.scale.y = 1.0 + minf(3.0, c.pump.intake) * (0.5 + 0.5 * sin(t * 6.0))
	glow.visible = c.pump.jam <= 0.0
	for f in v.get("fires", []):
		CastleFires.flicker(f, t)
	CastleBanners.animate_flags(v, c)
	CastleReadability.animate_markers(v, c)
	CastleTurretFire.animate(v, c, t)
