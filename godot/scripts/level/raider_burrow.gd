class_name RaiderBurrow
## Warden aura and Burrower movement (§4.2). The aura is one ring on the Warden, not a
## ground decal, and it does not stack. A Burrower walks a straight line under cliffs,
## shows a dust puff, and can be hit only during the 1.5 s it spends on the surface.
## The burst lands at the end of that window, so the window is a chance to kill it.


const ARRIVE := 1.6  # metres: "next to" the weapon, inside the 1.5-cell burst
const DUST := 0.22


static func setup(r: Dictionary) -> void:
	var tier: Dictionary = r.tier
	var attack := str(tier.get("attack", ""))
	if attack == "burrow":
		r["burrow"] = "down"
		(r.node as Node3D).visible = false
	elif attack == "aura":
		_ring(r, tier)


## -1 means the hit was ignored (underground). Otherwise the damage after one aura.
static func filter(host: Raiders, r: Dictionary, dmg: float) -> float:
	if str(r.get("burrow", "")) == "down":
		return -1.0
	if AmmoGrades.piercing:
		return dmg  # armour-piercing rounds ignore a Warden's aura
	var p: Vector3 = (r.node as Node3D).position
	for o in host.list:
		if o == r or not o.alive:
			continue
		var ot: Dictionary = o.tier
		if str(ot.get("attack", "")) != "aura":
			continue
		var op: Vector3 = (o.node as Node3D).position
		if Vector2(op.x - p.x, op.z - p.z).length() <= float(ot.range) * Config.CELL:
			return dmg * 0.5
	return dmg


static func step(host: Raiders, r: Dictionary, dt: float, prey: Array) -> void:
	var tier: Dictionary = r.tier
	if str(r.get("burrow", "down")) == "up":
		_surface(host, r, dt, tier, prey)
		return
	var node: Node3D = r.node
	var p: Vector3 = node.position
	var target := _weapon(prey, p)
	if target.is_empty():
		return
	var tp: Vector3 = (target.node as Node3D).position
	var to := Vector2(tp.x - p.x, tp.z - p.z)
	var dist := to.length()
	if dist <= ARRIVE:
		r["burrow"] = "up"
		r["surface_t"] = float(tier.get("surface", 1.5))
		node.visible = true
		node.position = Vector3(p.x, host.world.grid.stand_y(p.x, p.z, Grid.Faction.ENEMY), p.z)
		return
	var step_m: float = minf(dist, RaiderGroups.speed(host, r) * dt)
	var dir := to / dist
	var nx := p.x + dir.x * step_m
	var nz := p.z + dir.y * step_m
	var gy: float = host.world.grid.smooth_y(nx, nz)
	node.position = Vector3(nx, gy - 2.0, nz)
	node.visible = false
	var dust: float = float(r.get("dust", 0.0)) + dt
	if dust >= DUST:
		dust = 0.0
		host.world.effects.burst(Vector3(nx, gy + 0.15, nz), tier.color, 0.7, 0.3)
	r["dust"] = dust


static func _weapon(prey: Array, from: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	var fallback: Dictionary = {}
	var fd := INF
	for q in prey:
		if not (q.alive as Callable).call():
			continue
		var node := q.node as Node3D
		var d := Vector2(node.position.x - from.x, node.position.z - from.z).length()
		if bool(q.get("weapon", false)):
			if d < bd:
				bd = d
				best = q
		elif d < fd:
			fd = d
			fallback = q
	if not best.is_empty():
		return best
	return fallback


static func _surface(host: Raiders, r: Dictionary, dt: float, tier: Dictionary, prey: Array) -> void:
	var node: Node3D = r.node
	var p: Vector3 = node.position
	node.visible = true
	node.position = Vector3(p.x, host.world.grid.stand_y(p.x, p.z, Grid.Faction.ENEMY), p.z)
	var left: float = float(r.get("surface_t", 0.0)) - dt
	r["surface_t"] = left
	if left > 0.0:
		return
	var at: Vector3 = node.position
	var radius: float = float(tier.get("splash", 1.5)) * Config.CELL
	var dmg := float(tier.damage)
	host.world.effects.burst(at + Vector3.UP * 0.3, tier.color, radius, 0.5)
	Sfx.play("boom", at)
	for q in prey:
		if not (q.alive as Callable).call():
			continue
		var qp: Vector3 = (q.node as Node3D).position
		if Vector2(qp.x - at.x, qp.z - at.z).length() <= radius:
			(q.hit as Callable).call(dmg)
	if r.alive:
		r["burrow"] = "down"
		node.visible = false


static func _ring(r: Dictionary, tier: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	var rad: float = float(tier.range) * Config.CELL
	mesh.inner_radius = rad - 0.4
	mesh.outer_radius = rad
	mesh.rings = 32
	mesh.ring_segments = 6
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	var c: Color = tier.color
	mat.albedo_color = Color(c.r, c.g, c.b, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = Vector3(0, 0.25, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(r.node as Node3D).add_child(mi)


## --burrow: a Warden ring and a Burrower dust trail, for a screenshot.
static func demo(g) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(30, 28)
	var edits := []
	for z in range(24, 34):
		for x in range(24, 48):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)
	g.structures.place("cannon", 42, 28, true)
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests[0]
	nests.raiders.spawn(nest, RaiderDefs.named("Warden"), true)
	var w := nests.raiders.list.back() as Dictionary
	(w.node as Node3D).position = grid.cell_ground(30, 28)
	nests.raiders.spawn(nest, RaiderDefs.named("Burrower"), true)
	var b := nests.raiders.list.back() as Dictionary
	(b.node as Node3D).position = grid.cell_ground(34, 28)
	g.command.cam.edge_pan = false
	g.command.cam.focus(grid.cell_ground(34, 28))
	g.command.cam.dist = 36.0
