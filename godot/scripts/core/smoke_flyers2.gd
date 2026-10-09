class_name SmokeFlyers2
## Stage 19: who can hit flyers, roosts and flocks, Wyvern breath and hunting.


class FakeOp extends RefCounted:
	var prey: Dictionary = {}


static func run(g) -> void:
	var nests: SporeNests = g.hazards.nests
	nests.flyers.clear()
	_counters(g, nests.flyers)
	_roost(g, nests)
	_wyvern(g, nests)
	nests.flyers.clear()
	nests.time = 0.0
	nests.seal = 0.0
	for n in nests.nests:
		Hives.sync(nests, n)


## Mission time at which pressure first reaches `p`.
static func _time_for(nests: SporeNests, p: float) -> float:
	var t := 0.0
	while Pressure.value(nests.level, t) < p and t < 6000.0:
		t += 5.0
	return t


static func _free_bat(g, fl: Flyers, at: Vector3, who := "Spore Bat") -> Dictionary:
	return fl.spawn(FlyerDefs.named(who), at, { "cd": 99.0 })


static func _counters(g, fl: Flyers) -> void:
	var sm: StructureManager = g.structures
	var at: Vector3 = g.surface.grid.cell_ground(60, 12)
	var beam := sm.place("beam", 60, 12, true)
	var cannon := sm.place("cannon", 56, 12, true)
	var sniper := sm.place("sniper", 64, 12, true)
	if beam == null or cannon == null or sniper == null:
		SmokeTest._check("flyers: counter test could place weapons", false)
		return
	for s in [beam, cannon, sniper]:
		s.ammo = s.def.ammo.max
		s.hold_fire = false
	var bat := _free_bat(g, fl, at + Vector3(4, 5, 0))
	for i in 12:
		for s in [cannon, sniper]:
			s.cooldown = 0.0
			WeaponLogic.update(s, 0.2, sm)
	SmokeTest._check("flyers: cannon and sniper ignore a bat in range", is_equal_approx(bat.hp, 5.0) and bat.alive)
	for i in 20:
		beam.cooldown = 0.0
		WeaponLogic.update(beam, 0.2, sm)
	SmokeTest._check("flyers: a Beam kills a bat in range", not bat.alive and fl.count() == 0)
	# Flak
	var bat2 := _free_bat(g, fl, at + Vector3(3, 6, 2))
	var hp0: float = bat2.hp
	var flak_fired := CastleTurretFire._flak(g.surface, { "level": 1 }, CastleTurrets.DEFS.flak, at)
	SmokeTest._check("flyers: castle Flak fires at a flyer", flak_fired and bat2.hp < hp0)
	bat2.hp = 5.0
	hp0 = 5.0
	Flyers.strike(g.surface, at, 30.0, 3.0)
	SmokeTest._check("flyers: Flak / Lance helper damages the nearest flyer", is_equal_approx(bat2.hp, hp0 - 3.0))
	var n := Flyers.strike_area(g.surface, at, 20.0, 99.0)
	SmokeTest._check("flyers: the Lance area kills flyers", n == 1 and not bat2.alive)
	# Operative rifle
	var wy := _free_bat(g, fl, at + Vector3(0, 6, 12), "Wyvern")
	var w: OperativeWeapons = g.fps.weapons
	w.camera.global_position = at + Vector3(0, 6, 0)
	w.camera.look_at((wy.node as Node3D).position, Vector3.UP)
	w.rifle.fire(g.surface)
	SmokeTest._check("flyers: an Operative rifle shot hits a Wyvern", float(wy.hp) < 90.0, "(%.1f)" % wy.hp)
	fl.clear()
	for s in [beam, cannon, sniper]:
		sm.remove(s)


static func _roost(g, nests: SporeNests) -> void:
	var fl := nests.flyers
	var hive: Dictionary = nests.nests[0]
	nests.time = 0.0
	nests.seal = 0.0
	for n in nests.nests:
		Hives.sync(nests, n)
		FlyerLaunch.sync(nests, n)
	SmokeTest._check("flyers: no roost and no flock before pressure 0.30",
		Hives.find(hive, "roost").is_empty() and FlyerDefs.pick(0.29, 0.5).is_empty())
	nests.time = _time_for(nests, 0.72)
	Hives.sync(nests, hive)
	FlyerLaunch.sync(nests, hive)
	var roost := Hives.find(hive, "roost")
	SmokeTest._check("flyers: a stage-2 hive grows a roost", int(hive.stage) >= 2 and not roost.is_empty())
	roost.grown = true
	roost.cd = 0.0
	FlyerLaunch.tick(nests, 0.1)
	var launched := fl.count()
	SmokeTest._check("flyers: a grown roost launches a flock", launched > 0, "(%d)" % launched)
	fl.clear()
	roost.cd = 999.0
	nests.seal = Config.MORTAR_SEAL + 1.0
	FlyerLaunch.tick(nests, 0.1)
	SmokeTest._check("flyers: a sealed Node triggers a flock at it", fl.count() > 0 and fl.list.all(func(f): return f.node_bias))
	nests.seal = 0.0
	FlyerLaunch.tick(nests, 0.1)
	fl.clear()
	HiveParts.hurt(nests, hive, roost, 999.0, "unit")
	var again := 0
	for i in 40:
		FlyerLaunch.tick(nests, 5.0)
		again += fl.count()
	Hives.sync(nests, hive)
	FlyerLaunch.sync(nests, hive)
	SmokeTest._check("flyers: killing the roost stops launches", not roost.alive and again == 0 and fl.count() == 0)
	fl.clear()


static func _wyvern(g, nests: SporeNests) -> void:
	var fl := nests.flyers
	var saved_prey: Callable = nests.prey
	var saved_op: Callable = nests.operative
	var at: Vector3 = g.surface.grid.cell_ground(60, 20) + Vector3(0, 8, 0)
	var f := fl.spawn(FlyerDefs.named("Wyvern"), at, { "cd": 99.0 })
	var inside := { "node": Node3D.new(), "radius": 1.0, "dmg": 0.0 }
	var behind := { "node": Node3D.new(), "radius": 1.0, "dmg": 0.0 }
	for row in [inside, behind]:
		g.surface.add_child(row.node)
		row["alive"] = func(): return true
		row["hit"] = func(d: float): row.dmg += d
	inside.node.position = at + Vector3(9, -6, 0)
	behind.node.position = at + Vector3(-9, -6, 0)
	nests.prey = func() -> Array: return [inside, behind]
	f.aim = inside.node.position - at
	f.breath = 2.0
	FlyerAi._breathe(fl, f, 0.5)
	SmokeTest._check("flyers: Wyvern breath burns inside the cone only",
		is_equal_approx(inside.dmg, 6.0) and behind.dmg == 0.0, "(%.1f / %.1f)" % [inside.dmg, behind.dmg])
	var op := FakeOp.new()
	var tgt := Node3D.new()
	g.surface.add_child(tgt)
	tgt.position = at + Vector3(25, -8, 0)
	op.prey = { "node": tgt, "radius": 0.5, "alive": func(): return true, "hit": func(_d): pass }
	nests.operative = func(): return op
	f.breath = 0.0
	var near: bool = FlyerAi._wyvern_goal(fl, f).get("operative", false)
	tgt.position = at + Vector3(45, -8, 0)
	var far: bool = FlyerAi._wyvern_goal(fl, f).get("operative", false)
	SmokeTest._check("flyers: a Wyvern hunts the Operative within 30 m only", near and not far)
	tgt.position = at + Vector3(28, -8, 0)
	f.think = 0.0
	var d0 := Vector2(tgt.position.x - at.x, tgt.position.z - at.z).length()
	for i in 60:
		fl.update(0.05)
		f.cd = 99.0
	var p := (f.node as Node3D).position
	var d1 := Vector2(tgt.position.x - p.x, tgt.position.z - p.z).length()
	SmokeTest._check("flyers: the hunting Wyvern closes in", d1 < d0 - 4.0, "(%.1f -> %.1f m)" % [d0, d1])
	nests.prey = saved_prey
	nests.operative = saved_op
	for row in [inside, behind]:
		(row.node as Node3D).queue_free()
	tgt.queue_free()
	fl.clear()
