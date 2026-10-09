class_name HiveParts
## Core, spawner pits, spitter turrets and the spore launcher (§3.3).
## The Core ignores every weapon except the Operative and the Lance.
## The mortar body lives in EnemyMortars. This slot stays empty on purpose.


static func kind_of(id: String) -> String:
	if id.begins_with("pit"):
		return "pit"
	if id.begins_with("spitter"):
		return "spitter"
	return id


static func spawn(host, hive: Dictionary, id: String, stage: int, grown: bool) -> Dictionary:
	var kind := kind_of(id)
	var slot := (hive.slots as Dictionary)[id] as Vector2i
	var node := HiveMeshes.part(kind)
	var pos: Vector3 = host.world.place_at(node, slot.x, slot.y)
	var part := {
		"id": id, "kind": kind, "stage": stage, "x": slot.x, "z": slot.y,
		"node": node, "pos": pos, "alive": true, "grown": grown,
		"grow": 0.0 if grown else Config.HIVE_GROW, "hp": 0.0, "max_hp": 0.0,
		"cd": Config.SPIRE_INTERVAL if kind == "launcher" else 0.0,
	}
	part.hp = Hives.base_hp(host, hive, kind)
	part.max_hp = part.hp
	if not grown:
		node.scale = Vector3.ONE * 0.15
	var hit_unit := func(dmg: float, _p = null): hurt(host, hive, part, dmg, "unit")
	var hit_op := func(dmg: float, _p = null): hurt(host, hive, part, dmg, "operative")
	part["enemy"] = { "node": node, "oy": 0.8, "radius": 1.0,
		"alive": func(): return part.alive, "hit": hit_unit }
	part["target"] = { "node": node, "radius": 1.05, "oy": 0.9,
		"alive": func(): return part.alive, "on_hit": hit_op, "max_hp": part.max_hp }
	host.world.add_target(part.target)
	(hive.parts as Array).append(part)
	return part


static func restore(host, hive: Dictionary, src: Dictionary) -> void:
	var part := spawn(host, hive, str(src.id), int(src.stage), bool(src.grown))
	part.hp = float(src.hp)
	part.max_hp = float(src.max_hp)
	part.grow = float(src.grow)
	if not part.grown:
		var k := 1.0 - clampf(float(part.grow) / Config.HIVE_GROW, 0.0, 1.0)
		(part.node as Node3D).scale = Vector3.ONE * lerpf(0.15, 1.0, k)


static func hurt(host, hive: Dictionary, part: Dictionary, dmg: float, source: String) -> void:
	if part.is_empty() or not part.alive:
		return
	if str(part.kind) == "core" and source != "operative" and source != "lance":
		return
	part.hp = float(part.hp) - dmg
	if str(part.kind) == "core":
		hive.hp = part.hp
	if float(part.hp) > 0.0:
		_hit_anim(part)
		return
	if str(part.kind) == "core":
		Hives.raze(host, hive)
	else:
		if str(part.kind) != "spitter":  # spitters pay nothing (no Salvage farming)
			Loot.drop(host.world, part.pos, Config.LOOT_PART, host.stockpile, host.operative)
		forget(host.world, part)


## Hit flinch on the model, at most one clip every 0.3 s.
static func _hit_anim(part: Dictionary) -> void:
	var model := CreatureAnim.of(part.get("node") as Node3D)
	if model == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(part.get("hit_t", 0)) < 300:
		return
	part["hit_t"] = now
	CreatureAnim.hit(model)


static func forget(world: World, part: Dictionary) -> void:
	if part.is_empty():
		return
	part.alive = false
	if part.has("target"):
		world.remove_target(part.target)
	var node := part.get("node") as Node3D
	part["node"] = null
	if node != null and is_instance_valid(node):
		var model := CreatureAnim.of(node)
		if model != null:
			CreatureAnim.die(model, func() -> void:
				if is_instance_valid(node):
					node.queue_free())
		else:
			node.queue_free()


static func lance(host, ats: Array) -> void:
	var reach := Config.LANCE_RADIUS * Config.CELL
	for at in ats:
		var p: Vector3 = at
		for hive in host.nests:
			var h: Dictionary = hive
			if str(h.state) != "active":
				continue
			for part in (h.parts as Array).duplicate():
				var q: Dictionary = part
				if not q.alive:
					continue
				var pos: Vector3 = q.pos
				if Vector2(pos.x - p.x, pos.z - p.z).length() <= reach:
					var dmg := Config.HIVE_LANCE_DMG
					if host.builder != null:
						dmg *= host.builder.lance_scale(p)
					hurt(host, h, q, dmg, "lance")


## Yaw the model to face a target. The model's +X is forward.
static func face_at(part: Dictionary, at: Vector3) -> void:
	var model := CreatureAnim.of(part.get("node") as Node3D)
	if model == null:
		return
	var from: Vector3 = (part.get("node") as Node3D).position
	var d: Vector3 = at - from
	model.rotation.y = atan2(-d.z, d.x)


## One attack swing on the part's model (no-op for the procedural fallback).
static func attack_anim(part: Dictionary) -> void:
	var model := CreatureAnim.of(part.get("node") as Node3D)
	if model != null:
		CreatureAnim.attack(model)


static func combat(host, hive: Dictionary, dt: float) -> void:
	var prey: Array = host.prey.call()
	for part in hive.parts:
		var p: Dictionary = part
		if not p.alive or not p.grown:
			continue
		var kind := str(p.kind)
		if kind == "spitter":
			_spitter(host, p, dt, prey)
		elif kind == "launcher":
			_launcher(host, p, dt)


static func _spitter(host, part: Dictionary, dt: float, prey: Array) -> void:
	part.cd = float(part.cd) - dt
	if float(part.cd) > 0.0:
		return
	var reach := Config.HIVE_SPITTER_RANGE * Config.CELL
	var from: Vector3 = (part.node as Node3D).position
	var best: Dictionary = {}
	var bd := reach
	for q in prey:
		if not (q.alive as Callable).call():
			continue
		var node := q.node as Node3D
		var d := Vector2(node.position.x - from.x, node.position.z - from.z).length()
		if d < bd:
			bd = d
			best = q
	if best.is_empty():
		return
	part.cd = Config.HIVE_SPITTER_INTERVAL
	var aim: Vector3 = (best.node as Node3D).position
	face_at(part, aim)
	attack_anim(part)
	var splash := Config.HIVE_SPITTER_SPLASH * Config.CELL
	var dmg := Config.HIVE_SPITTER_DMG
	var from3: Vector3 = from + Vector3(0, 0.9, 0)
	var end := WeaponLogic.clip_lob(host.world.grid, from3, aim, 2.5)
	var it: Dictionary = host.world.effects.lob(from3, end, {
		"color": Color("d6ff3a"), "size": 0.28, "time": maxf(from.distance_to(aim) / Config.RAIDER_SHOT_SPEED, 0.35),
		"arc": 2.5,
		"on_arrive": func():
			host.world.effects.burst(end, Color("d6ff3a"), splash, 0.35)
			for q in prey:
				if not (q.alive as Callable).call():
					continue
				var p: Vector3 = (q.node as Node3D).position
				if Vector2(p.x - end.x, p.z - end.z).length() <= splash:
					if str(q.get("kind", "")) == "operative":
						HitFeel.note_source(from)
					(q.hit as Callable).call(dmg),
	})
	it["foe"] = true  # hostile lob: Beams shoot these down (hive spitter acid)


static func _launcher(host, part: Dictionary, dt: float) -> void:
	part.cd = float(part.cd) - dt
	if float(part.cd) > 0.0 or host.structures == null:
		return
	var sm: StructureManager = host.structures
	var target: Structure = sm.nearest_to(int(part.x), int(part.z), func(s: Structure): return s.type != "beacon")
	if target == null:
		return
	part.cd = Config.SPIRE_INTERVAL
	var to: Vector3 = target.pos
	attack_anim(part)
	Bus.say("Spore volley incoming at your %s! (Beams can shoot it down)" % target.def.label, "warn")
	var it: Dictionary = host.world.effects.lob((part.node as Node3D).position + Vector3(0, 1.6, 0), to, {
		"color": Color("88ff55"), "size": 0.9, "time": 4.0, "arc": 28.0,
		"on_arrive": func():
			host.world.creeper.add(target.x, target.z, Config.SPORE_AMOUNT)
			host.world.effects.burst(to, Color("88ff55"), 3.0 * Config.CELL, 0.6)
			if not target.dead:
				sm.damage(target, 15.0, "hive_spitter"),
	})
	it["spore"] = true
	it["spore_hp"] = Config.SPORE_HP
