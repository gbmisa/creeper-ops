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
		StructureMeshes.cyl(n, 0.7 * k, 0.9 * k, 0.6 * k, StructureMeshes.mat(Color("3a4150")), 0.0, 10)
		var head := Node3D.new()
		head.name = "Head"
		head.position.y = 0.9 * k
		n.add_child(head)
		StructureMeshes.ball(head, 0.45 * k, StructureMeshes.mat(def.color, 0.3, 0.5, def.color, 0.4))
		StructureMeshes.box(head, Vector3(0.18, 0.18, 1.0 * k), StructureMeshes.mat(Color("20242c")), Vector3(0, 0, -0.5 * k))


static func tick(world: World, c: Dictionary, v: Dictionary, raiders: Raiders, dt: float) -> void:
	var changed := false
	for i in c.sockets.size():
		var s: Dictionary = c.sockets[i]
		if not CastleTurrets.alive(s):
			continue
		var d := world.creeper.depth_at(s.cell.x, s.cell.y)
		if d > Config.DAMAGE_DEPTH:
			s.hp -= (Config.WEAPON_CREEPER_BASE_DPS + d * Config.WEAPON_CREEPER_DPS) * dt
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
			"raiders": fired = _repeater(world, s, def, at, raiders, v.turrets[i])
			"creeper": fired = _lobber(world, s, def, at)
			"air": fired = _flak(world, s, def, at)
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


static func _repeater(world: World, s: Dictionary, def: Dictionary, at: Vector3, raiders: Raiders, node: Node3D) -> bool:
	var best: Dictionary = {}
	var bd: float = def.range * Config.CELL
	for m in raiders.list:
		var d := (m.node.position as Vector3).distance_to(at)
		if m.alive and d < bd:
			bd = d
			best = m
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
	return false
