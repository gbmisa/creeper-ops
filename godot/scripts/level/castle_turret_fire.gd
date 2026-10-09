class_name CastleTurretFire
## Castle turrets at work (state and buying: CastleTurrets). Each frame, for a castle you
## hold: creeper eats turret HP like a weapon's, then every live turret fires on its own
## interval: Repeater at the nearest raider, Lobber at the deepest creeper, Flak at spore
## volleys. Also builds and refreshes the turret models (one per socket).


static func build_views(world: World, c: Dictionary, v: Dictionary) -> void:
	var nodes := []
	for s in c.sockets:
		var n := Node3D.new()
		n.position = world.grid.cell_ground(s.cell.x, s.cell.y)
		world.add_child(n)
		nodes.append(n)
	v["turrets"] = nodes
	v["turret_type"] = c.sockets.map(func(_s): return "")


## Rebuilds a socket's model when its type or level changed; hides empty or dead ones.
static func refresh(v: Dictionary, c: Dictionary) -> void:
	for i in c.sockets.size():
		var s: Dictionary = c.sockets[i]
		var n: Node3D = v.turrets[i]
		var key := "%s%d" % [s.turret, s.level] if CastleTurrets.alive(s) else ""
		if v.turret_type[i] == key:
			continue
		v.turret_type[i] = key
		for ch in n.get_children():
			ch.queue_free()
		if key == "":
			continue
		var def: Dictionary = CastleTurrets.DEFS[s.turret]
		var k: float = 1.3 + 0.25 * s.level  # reads from command height; grows per level
		_model(n, s.turret, def, k)


## Lamp pulse (Ward Lamp): cheap glow scale + light-energy flicker.
static func animate(v: Dictionary, c: Dictionary, t: float) -> void:
	if not v.has("turrets"):
		return
	for i in c.sockets.size():
		var s: Dictionary = c.sockets[i]
		if s.turret != "ward_lamp" or not CastleTurrets.alive(s):
			continue
		var n := v.turrets[i] as Node3D
		var wob := sin(t * 3.0 + float(i) * 1.7)
		var glow := n.get_node_or_null("Glow")
		if glow:
			glow.scale = Vector3.ONE * (1.0 + 0.18 * wob)
		var l := n.get_node_or_null("GlowLight") as OmniLight3D
		if l:
			l.light_energy = 1.1 + 0.7 * (0.5 + 0.5 * wob)


## Stone pedestal, then a head per turret type (all look along -Z, aimed via "Head").
static func _model(n: Node3D, type: String, def: Dictionary, k: float) -> void:
	ShapeKit.lathe(n, PackedVector2Array([Vector2(0.8, 0.0), Vector2(0.65, 0.2), Vector2(0.55, 0.6),
		Vector2(0.7, 0.75), Vector2(0.0, 0.75)]) , StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.9), Vector3.ZERO, 8).scale = Vector3.ONE * k
	match type:
		"ballista": _ballista_head(n, def.color, k)
		"ward_lamp": _lamp(n, def.color, k)
		_: _repeater_head(n, def.color, k)


## The small anti-raider gun: bronze yoke and a light bolt-thrower.
static func _repeater_head(n: Node3D, col: Color, k: float) -> void:
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 0.95 * k
	n.add_child(head)
	StructureMeshes.box(head, Vector3(0.5, 0.35, 0.5) * k, StructureMeshes.pal("bronze"))
	StructureMeshes.box(head, Vector3(0.14, 0.14, 1.3) * k, StructureMeshes.pal("oak"), Vector3(0, 0.05, -0.4) * k)
	for sx in [-1.0, 1.0]:
		ShapeKit.strut(head, Vector3(0, 0.05, -0.85) * k, Vector3(sx * 0.6, 0.05, -0.55) * k, 0.07 * k, StructureMeshes.pal("bronze_dark"))
	StructureMeshes.ball(head, 0.12 * k, StructureMeshes.glow(col, 1.6), Vector3(0, 0.25, 0) * k, 8)


## The Ballista: a big bolt-thrower — longer oak rail, heavy bronze arms, a fat glowing bolt.
static func _ballista_head(n: Node3D, col: Color, k: float) -> void:
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 0.95 * k
	n.add_child(head)
	StructureMeshes.box(head, Vector3(0.7, 0.5, 0.9) * k, StructureMeshes.pal("bronze_dark"))
	StructureMeshes.box(head, Vector3(0.22, 0.22, 2.6) * k, StructureMeshes.pal("oak"), Vector3(0, 0.12, -0.7) * k)
	for sx in [-1.0, 1.0]:  # heavy throwing arms
		ShapeKit.strut(head, Vector3(0, 0.12, -1.6) * k, Vector3(sx * 1.05, 0.12, -0.9) * k, 0.13 * k, StructureMeshes.pal("bronze"))
		ShapeKit.strut(head, Vector3(sx * 1.05, 0.12, -0.9) * k, Vector3(sx * 0.85, 0.35, -0.7) * k, 0.06 * k, StructureMeshes.pal("bronze_dark"))
	StructureMeshes.box(head, Vector3(0.16, 0.16, 1.1) * k, StructureMeshes.glow(col, 1.8), Vector3(0, 0.3, -0.75) * k)


## The Ward Lamp: an iron post with a caged crystal that pulses (animated in animate()).
static func _lamp(n: Node3D, col: Color, k: float) -> void:
	StructureMeshes.box(n, Vector3(0.18, 2.4, 0.18) * k, StructureMeshes.pal("iron"), Vector3(0, 1.95 * k, 0))
	for sx in [-1.0, 1.0]:  # the cage
		ShapeKit.strut(n, Vector3(sx * 0.42 * k, 2.9 * k, 0), Vector3(sx * 0.18 * k, 3.5 * k, 0), 0.05 * k, StructureMeshes.pal("bronze_dark"))
		ShapeKit.strut(n, Vector3(0, 2.9 * k, sx * 0.42 * k), Vector3(0, 3.5 * k, sx * 0.18 * k), 0.05 * k, StructureMeshes.pal("bronze_dark"))
	var glow := StructureMeshes.ball(n, 0.32 * k, StructureMeshes.glow(col, 2.2), Vector3(0, 3.2 * k, 0), 12)
	glow.name = "Glow"
	var l := OmniLight3D.new()
	l.name = "GlowLight"
	l.light_color = col
	l.light_energy = 1.4
	l.omni_range = 7.0
	l.position = Vector3(0, 3.2 * k, 0)
	n.add_child(l)


static func tick(world: World, c: Dictionary, v: Dictionary, raiders: Raiders, dt: float) -> void:
	var changed := false
	for i in c.sockets.size():
		var s: Dictionary = c.sockets[i]
		if not CastleTurrets.alive(s):
			continue
		var d := world.creeper.depth_at(s.cell.x, s.cell.y)
		if d > Config.MIN_DEPTH:  # CW3 flat wet damage, like network weapons
			s.hp -= CastleTurrets.DEFS[s.turret].hp[s.level - 1] / Config.WET_TIME * dt
			if s.hp <= 0.0:
				_lost(c, s)
				changed = true
				continue
		s.cd -= dt
		if s.cd > 0.0:
			continue
		var def: Dictionary = CastleTurrets.DEFS[s.turret]
		var at: Vector3 = (v.turrets[i] as Node3D).position + Vector3(0, 1.0, 0)
		var fired := false
		match def.targets:
			"raiders": fired = _ballista(world, s, def, at, raiders, v.turrets[i]) if s.turret == "ballista" else _repeater(world, s, def, at, raiders, v.turrets[i])
			"creeper": fired = _lobber(world, s, def, at)
			"air": fired = _flak(world, s, def, at)
			"none": pass  # the Ward Lamp fires nothing
		if fired:
			s.cd = def.interval
	if changed:
		refresh(v, c)


## A turret took damage (raider melee): returns true when it just died.
static func hit(c: Dictionary, s: Dictionary, dmg: float) -> bool:
	if not CastleTurrets.alive(s):
		return false
	s.hp -= dmg
	if s.hp > 0.0:
		return false
	_lost(c, s)
	return true


static func _lost(c: Dictionary, s: Dictionary) -> void:
	Bus.say("%s on %s destroyed." % [CastleTurrets.DEFS[s.turret].label, c.name], "bad")
	s.hp = 0.0
	s.turret = ""
	s.level = 0


## Nearest live raider within `reach` metres of `at`.
static func _target_raider(raiders: Raiders, at: Vector3, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var bd := reach
	for m in raiders.list:
		var d := (m.node.position as Vector3).distance_to(at)
		if m.alive and d < bd:
			bd = d
			best = m
	return best


static func _repeater(world: World, s: Dictionary, def: Dictionary, at: Vector3, raiders: Raiders, node: Node3D) -> bool:
	var best := _target_raider(raiders, at, def.range * Config.CELL)
	if best.is_empty():
		return false
	var p: Vector3 = best.node.position + Vector3(0, best.tier.size * 0.6, 0)
	var head := node.get_node_or_null("Head") as Node3D
	if head:
		head.look_at(p, Vector3.UP)
	world.effects.beam(at, p, def.color, 0.06, 0.05)
	best.enemy.hit.call(def.power[s.level - 1])
	Sfx.play("rifle", at)
	return true


## A Ballista aims like a Repeater but throws one slow, heavy bolt: thicker beam, big power.
static func _ballista(world: World, s: Dictionary, def: Dictionary, at: Vector3, raiders: Raiders, node: Node3D) -> bool:
	var best := _target_raider(raiders, at, def.range * Config.CELL)
	if best.is_empty():
		return false
	var p: Vector3 = best.node.position + Vector3(0, best.tier.size * 0.6, 0)
	var head := node.get_node_or_null("Head") as Node3D
	if head:
		head.look_at(p, Vector3.UP)
	world.effects.beam(at, p, def.color, 0.16, 0.12)
	best.enemy.hit.call(def.power[s.level - 1])
	Sfx.play("rifle", at)
	return true


static func _lobber(world: World, s: Dictionary, def: Dictionary, at: Vector3) -> bool:
	var t = world.creeper.deepest_wet(s.cell.x, s.cell.y, def.range)
	if t == null:
		return false
	var b := world.grid.cell_ground(t.x, t.y)
	var power: float = def.power[s.level - 1]
	var splash: float = def.splash
	world.effects.lob(at, b, { "color": def.color, "time": 1.0, "arc": 10.0, "size": 0.45, "on_arrive": func():
		world.creeper.remove_radius(t.x, t.y, splash, power)
		world.effects.burst(b, Color("ffaa33"), splash * Config.CELL * 0.7, 0.45)
		Sfx.play("boom", b) })
	Sfx.play("mortar", at)
	return true


static func _flak(world: World, s: Dictionary, def: Dictionary, at: Vector3) -> bool:
	var reach: float = def.range * Config.CELL
	for it in world.effects.lobs():
		if it.has("spore") and (it.pos as Vector3).distance_to(at) <= reach:
			it.spore_hp -= def.power[s.level - 1]
			world.effects.burst(it.pos, def.color, 1.2, 0.2)
			if it.spore_hp <= 0.0:
				it.dead = true
				world.effects.burst(it.pos, Color("88ff55"), 2.5, 0.4)
				Sfx.play("pop", it.pos)
			Sfx.play("blaster", at)
			return true
	var fp = Flyers.strike(world, at, reach, def.power[s.level - 1])  # Stage 19: flyers
	if fp != null:
		world.effects.burst(fp, def.color, 1.2, 0.2)
		Sfx.play("blaster", at)
		return true
	return false
