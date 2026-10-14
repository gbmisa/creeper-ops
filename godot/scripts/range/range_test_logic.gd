class_name RangeTestLogic
## Pure-logic checks (no physics): penetration math, magazines, gun handling, body health.

static func run(t: RangeTest) -> void:
	_penetration(t)
	_mags_and_reloads(t)
	_actions(t)
	_body(t)
	_malfunction(t)
	_recoil(t)


static func _penetration(t: RangeTest) -> void:
	var a := Penetration.armor_a(4, 100.0)
	t.check("pen chance: pen >= a is 1", Penetration.pen_chance(a, a) == 1.0 and Penetration.pen_chance(a + 10.0, a) == 1.0)
	t.check("pen chance: pen <= a-15 is 0", Penetration.pen_chance(a - 15.0, a) == 0.0 and Penetration.pen_chance(5.0, a) == 0.0)
	t.check("pen chance: quadratic middle", absf(Penetration.pen_chance(a - 7.5, a) - 0.004 * 7.5 * 7.5) < 0.0001)
	var ps := TacAmmoDefs.of("762_ps")
	var shot := {"dmg": 57.0, "pen": ps["pen"], "armor_dmg": ps["armor_dmg"], "glance": 90.0}
	var plate := ArmorDefs.of("plate4")
	var blocked := Penetration.armor_hit(plate, 50.0, shot, 0.99, 0.0)
	var through := Penetration.armor_hit(plate, 50.0, shot, 0.0, 0.0)
	t.check("armor: class 4 vs PS can block and can pass", not blocked["pen"] and through["pen"] and blocked["dmg"] < through["dmg"] and blocked["dur_loss"] > 0.0)
	t.check("armor: blunt = dmg x blunt", absf(blocked["dmg"] - 57.0 * 0.25) < 0.01)
	var r := Penetration.world_hit("sheet_metal", 0.003, 35.0, 10.0, 0.0)
	t.check("sheet metal: grazing hit ricochets", r["ricochet"])
	t.check("sheet metal: steep hit does not ricochet", not Penetration.world_hit("sheet_metal", 0.02, 35.0, 80.0, 0.0)["ricochet"])
	t.check("materials: plywood passes PS, concrete stops it", Penetration.world_hit("plywood", 0.02, 35.0, 90.0, 1.0)["pass"] and not Penetration.world_hit("concrete", 0.02, 35.0, 90.0, 1.0)["pass"])
	t.check("zero angles are stable", Ballistics.zero_angle("762_ps", 100.0) > 0.0 and Ballistics.zero_angle("762_ps", 300.0) > Ballistics.zero_angle("762_ps", 100.0))


static func _mags_and_reloads(t: RangeTest) -> void:
	var m := Magazine.new(30)
	var words := []
	for n in [30, 25, 15, 8, 3, 0]:
		m.rounds.clear()
		for i in n:
			m.push("762_ps")
		words.append(m.estimate())
	t.check("mag estimate strings", words == ["Full", "Almost full", "About half", "Less than half", "Almost empty", "Empty"], str(words))
	var small := Magazine.new(7)
	for i in 5:
		small.push("45_fmj")
	t.check("mag estimate: exact for small mags", small.estimate() == "5 rounds")
	var g := Gun.new("ak47")
	g.mag.rounds.resize(10)
	var old := g.mag
	t.check("tactical reload starts", g.reload(false))
	g.update(5.0)
	t.check("tactical reload keeps the old mag", g.spares.has(old) and g.mag != old and g.spares.size() == 3)
	var f := Gun.new("ak47")
	var old2 := f.mag
	f.reload(true)
	f.update(5.0)
	t.check("fast reload drops the old mag", not f.spares.has(old2) and f.spares.size() == 2)
	var c := Gun.new("ak47")
	c.reload(false)
	c.update(5.0)
	t.check("reload with a chambered round keeps it (+1)", c.rounds_total() == 31 and c.chamber != "", str(c.rounds_total()))
	var e := Gun.new("ak47")
	e.chamber = ""
	e.reload(false)
	e.update(5.0)
	t.check("reload with empty chamber chambers one", e.rounds_total() == 30 and e.mag.count() == 29)


static func _actions(t: RangeTest) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := Gun.new("sniper")
	s.durability = 1.0
	var r1 := s.fire(rng)
	var r2 := s.fire(rng)
	t.check("bolt needs a cycle before the next shot", r1["fired"] and not r2["fired"] and r2["reason"] == "cycle")
	s.release()
	s.update(0.5)
	t.check("bolt still cycling at 0.5 s", s.fire(rng)["fired"] == false)
	s.update(1.0)
	s.fire_cd = 0.0
	t.check("bolt fires again after the cycle", s.fire(rng)["fired"])
	var sg := Gun.new("shotgun")
	var res := sg.fire(rng)
	var dirs := sg.shot_dirs(Basis.IDENTITY, res["ammo"], true, rng)
	t.check("shotgun fires 8 pellets", res["fired"] and res["pellets"] == 8 and dirs.size() == 8)
	var ga := Gun.new("garand")
	t.check("garand cannot reload with rounds left", not ga.reload())
	var ping := false
	for i in 8:
		ga.fire_cd = 0.0
		var r := ga.fire(rng)
		ping = r["ping"]
	t.check("garand pings on the last round", ping and ga.mag.count() == 0)
	t.check("garand reloads once empty", ga.reload() and ga.busy())
	ga.update(5.0)
	t.check("garand loads a full clip", ga.mag.count() == 8)


static func _body(t: RangeTest) -> void:
	var b := BodyHealth.new()
	b.rng.seed = 3
	b.hit("lleg", 70.0)
	t.check("leg blacks out at 0", b.hp["lleg"] == 0.0 and b.alive())
	var before: float = b.hp["thorax"]
	var res := b.hit("lleg", 10.0)
	t.check("blacked limb spills x1.0 to living zones", is_equal_approx(b.hp["thorax"], before - 10.0) and res["spill"].has("stomach"))
	var s := BodyHealth.new()
	s.hit("stomach", 70.0)
	s.hit("stomach", 10.0)
	t.check("stomach spill is x1.5", is_equal_approx(s.hp["thorax"], 85.0 - 15.0))
	var d := BodyHealth.new()
	d.hit("thorax", 90.0)
	t.check("thorax at 0 is death", not d.alive())
	var h := BodyHealth.new()
	t.check("head at 0 is death", not h.hit("head", 40.0)["alive"] if false else h.hit("head", 40.0)["killed"] and not h.alive())
	var bl := BodyHealth.new()
	bl.hit("larm", 5.0, {"bleed": "heavy"})
	bl.tick(1.0)
	t.check("heavy bleed ticks 2.4 HP/s", is_equal_approx(bl.hp["larm"], 55.0 - 2.4))
	var lb := BodyHealth.new()
	lb.hit("rleg", 5.0, {"bleed": "light"})
	lb.tick(2.0)
	t.check("light bleed ticks 0.8 HP/s", is_equal_approx(lb.hp["rleg"], 60.0 - 1.6))
	var fr := BodyHealth.new()
	fr.hit("rleg", 30.0, {"fracture": true})
	t.check("leg fracture slows", fr.move_mult() < 1.0)


static func _malfunction(t: RangeTest) -> void:
	var rng := RandomNumberGenerator.new()
	var g := Gun.new("ak47")
	g.force_malf("jam")
	t.check("malfunction blocks fire", not g.fire(rng)["fired"])
	t.check("inspect names the malfunction", g.inspect() == "jam")
	t.check("still blocked after inspect", not g.fire(rng)["fired"])
	t.check("second inspect starts the fix", g.inspect() == "fixing" and g.busy())
	g.update(3.0)
	g.fire_cd = 0.0
	t.check("fires again after the fix", g.fire(rng)["fired"])


static func _recoil(t: RangeTest) -> void:
	var rng := RandomNumberGenerator.new()
	var def := WeaponDefs.of("ak47")
	var rm := RecoilModel.new()
	for i in 200:
		rm.shoot(def, rng)
	t.check("recoil climbs to a cap", rm.offset.x <= def["up"] * TacticalConfig.RECOIL_CAP_SHOTS + 0.001 and rm.offset.x > def["up"] * 3.0)
	rm.update(3.0, 50.0)
	t.check("recoil converges back", rm.offset.length() < 0.1)
