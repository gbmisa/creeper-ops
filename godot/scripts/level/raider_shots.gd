class_name RaiderShots
## Ranged raiders (§4.2). Spitters lob acid. Lancers charge, then throw a bolt.
## Both shots are effects.lob arcs, aimed at where the target stands when the shot leaves,
## and only hurt whoever is still inside the impact. A target that walks away is missed.
## Range on the roster row is in cells. Lancers prefer a Sniper, then any other weapon.


static func step(host: Raiders, r: Dictionary, dt: float, prey: Array) -> void:
	var tier: Dictionary = r.tier
	var beam := str(tier.attack) == "beam"
	var grid: Grid = host.world.grid
	var target := _pick(r, prey, beam, grid)
	_move(host, r, dt, target, tier)
	var cd: float = float(r.get("shot_cd", 0.0))
	if cd > 0.0:
		r["shot_cd"] = cd - dt
		return
	if target.is_empty():
		_end_glow(r)
		r["charge"] = -1.0
		return
	if beam:
		_beam(host, r, dt, target, tier, prey)
	else:
		_launch(host.world, r, target, prey, float(tier.get("splash", 1.5)) * Config.CELL, Config.RAIDER_SHOT_SPEED, 0.5, 0.15)
		r["shot_cd"] = float(tier.interval)


## Sniper (band 0), then other weapons (band 1), then anyone else. Nearest inside a band.
## Beam attackers (Lancers) throw a near-flat bolt: no line of sight, no target, so they
## reposition instead of shooting through walls. Spitters keep lobbing over low walls.
static func _pick(r: Dictionary, prey: Array, beam: bool, grid: Grid) -> Dictionary:
	var tier: Dictionary = r.tier
	var reach: float = float(tier.range) * Config.CELL
	var from: Vector3 = (r.node as Node3D).position
	var best: Dictionary = {}
	var band := 9
	var bd := reach + 1.0
	for q in prey:
		if not (q.alive as Callable).call():
			continue
		var node := q.node as Node3D
		var d := Vector2(node.position.x - from.x, node.position.z - from.z).length()
		if d > reach:
			continue
		var b := 2
		if beam and str(q.get("type", "")) == "sniper":
			b = 0
		elif beam and bool(q.get("weapon", false)):
			b = 1
		if b < band or (b == band and d < bd):
			band = b
			bd = d
			best = q
	if beam and not best.is_empty():
		var eye: Vector3 = (r.node as Node3D).position + Vector3(0, float(r.size), 0)
		var chest: Vector3 = (best.node as Node3D).position
		if not WeaponLogic.sees(grid, eye, chest):
			best = {}
	return best


static func _move(host: Raiders, r: Dictionary, dt: float, target: Dictionary, tier: Dictionary) -> void:
	var node: Node3D = r.node
	var p: Vector3 = node.position
	if target.is_empty():
		var goal: Variant = null
		if r.has("guard_post"):
			goal = CastleLancers.stand(host, r)
		elif r.guard:
			goal = host._patrol(r.nest.pos, r)
		else:
			goal = host._route(r, p)
		if goal == null:
			goal = host._patrol(r.nest.pos, r)
		host._walk(r, goal as Vector2, dt)
		return
	var tp: Vector3 = (target.node as Node3D).position
	var dist := Vector2(tp.x - p.x, tp.z - p.z).length()
	var hold: float = float(tier.range) * Config.CELL * Config.RAIDER_STANDOFF
	host._face(r, Vector2(tp.x - p.x, tp.z - p.z))
	if dist < hold and not r.has("guard_post"):  # castle guards hold their post
		var away := Vector2(p.x - tp.x, p.z - tp.z)
		if away.length() < 0.05:
			away = Vector2(1, 0)
		host._walk(r, Vector2(p.x, p.z) + away.normalized() * 3.0, dt)
		return
	# Holding position to shoot: idle the walk clip instead of leaving a stale
	# sprint playing while standing still.
	node.position.y = RaiderPerch.y(host.world, p.x, p.z)
	CreatureAnim.move(node, 0.0)


static func _beam(host: Raiders, r: Dictionary, dt: float, target: Dictionary, tier: Dictionary, prey: Array) -> void:
	var locked: Variant = r.get("aim_node")
	var node: Node3D = target.node
	if locked != null and locked != node:
		_end_glow(r)
		r["charge"] = -1.0
	var charge: float = float(r.get("charge", -1.0))
	if charge < 0.0:
		r["charge"] = float(tier.interval)
		r["aim_node"] = node
		_begin_glow(r, tier)
		Sfx.play("lift", (r.node as Node3D).position)
		return
	charge -= dt
	r["charge"] = charge
	_grow_glow(r, tier)
	if charge > 0.0:
		return
	if not _bolt_clear(host.world.grid, r, target):  # the flat bolt would hit a wall: hold fire
		_end_glow(r)
		r["charge"] = -1.0
		r.erase("aim_node")
		r["shot_cd"] = Config.RAIDER_LANCER_GAP
		return
	_launch(host.world, r, target, prey, Config.RAIDER_BEAM_RADIUS, Config.RAIDER_BEAM_SPEED, 0.28, 0.04)
	_end_glow(r)
	r["charge"] = -1.0
	r.erase("aim_node")
	r["shot_cd"] = Config.RAIDER_LANCER_GAP


## The bolt's own arc, not just the sight line, must reach the target (keep walls, roofs).
static func _bolt_clear(grid: Grid, r: Dictionary, target: Dictionary) -> bool:
	var from: Vector3 = (r.node as Node3D).position + Vector3(0, float(r.size), 0)
	var aim: Vector3 = (target.node as Node3D).position
	var arc := clampf(maxf(from.distance_to(aim), 0.5) * 0.04, 1.2, 8.0)
	return WeaponLogic.clip_lob(grid, from, aim, arc).distance_to(aim) <= Config.SNIPER_LOS_SLACK + 0.5


static func _launch(world: World, r: Dictionary, target: Dictionary, prey: Array, radius: float, speed: float, size: float, arc_k: float) -> void:
	var from: Vector3 = (r.node as Node3D).position + Vector3(0, float(r.size), 0)
	var aim: Vector3 = (target.node as Node3D).position
	var dist := maxf(from.distance_to(aim), 0.5)
	var tier: Dictionary = r.tier
	var dmg := float(tier.damage)
	var color: Color = tier.color
	var src := str(tier.get("name", "raider")).to_lower() + "_shot"  # "spitter_shot", "lancer_shot"
	var arc := clampf(dist * arc_k, 1.2, 8.0)
	var end := WeaponLogic.clip_lob(world.grid, from, aim, arc)
	var it: Dictionary = world.effects.lob(from, end, {
		"color": color, "size": size, "time": maxf(dist / speed, 0.35),
		"arc": arc,
		"on_arrive": func(): _impact(world, end, radius, dmg, color, prey, from, src),
	})
	it["foe"] = true  # hostile lob: Beams shoot these down (spitter acid)
	Sfx.play("mortar", from)


static func _impact(world: World, at: Vector3, radius: float, dmg: float, color: Color, prey: Array, from := Vector3.INF, src := "raider_shot") -> void:
	world.effects.burst(at + Vector3.UP * 0.3, color, maxf(radius, 1.2), 0.35)
	Sfx.play("boom", at)
	for q in prey:
		if not (q.alive as Callable).call():
			continue
		var p: Vector3 = (q.node as Node3D).position
		if Vector2(p.x - at.x, p.z - at.z).length() > radius or absf(p.y - at.y) > 4.0:
			continue
		if from != Vector3.INF and str(q.get("kind", "")) == "operative":
			HitFeel.note_source(from)
		if q.has("struct"):
			(q.struct as Structure).last_hit_by = src
		(q.hit as Callable).call(dmg)


static func _begin_glow(r: Dictionary, tier: Dictionary) -> void:
	_end_glow(r)
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mi.mesh = mesh
	mi.material_override = StructureMeshes.glow(tier.color, 2.4)
	mi.position = Vector3(0.6, 0.9, 0)
	(r.node as Node3D).add_child(mi)
	r["charge_glow"] = mi


static func _grow_glow(r: Dictionary, tier: Dictionary) -> void:
	var mi := r.get("charge_glow") as MeshInstance3D
	if mi == null:
		return
	var total: float = maxf(float(tier.interval), 0.01)
	var k: float = 1.0 - clampf(float(r.charge) / total, 0.0, 1.0)
	mi.scale = Vector3.ONE * lerpf(0.4, 2.6, k)


static func _end_glow(r: Dictionary) -> void:
	var mi := r.get("charge_glow") as MeshInstance3D
	if mi != null:
		mi.queue_free()
	r.erase("charge_glow")


## --ranged: one Spitter and one Lancer on a flat pad, for a projectile screenshot.
static func demo(g) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(24, 74)
	var edits := []
	for z in range(70, 78):
		for x in range(18, 50):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)
	g.structures.place("cannon", 39, 73, true)
	g.structures.place("sniper", 46, 75, true)
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests[0]
	nests.raiders.spawn(nest, RaiderDefs.named("Spitter"), true)
	var sp := nests.raiders.list.back() as Dictionary
	(sp.node as Node3D).position = grid.cell_ground(24, 73)
	nests.raiders.spawn(nest, RaiderDefs.named("Lancer"), true)
	var ln := nests.raiders.list.back() as Dictionary
	(ln.node as Node3D).position = grid.cell_ground(24, 75)
	g.command.cam.edge_pan = false
	g.command.cam.focus(grid.cell_ground(34, 74))
	g.command.cam.dist = 28.0
