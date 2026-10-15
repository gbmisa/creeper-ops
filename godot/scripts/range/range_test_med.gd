class_name RangeTestMed
## Track MED checks (pure logic): status meters, med item defs, use flow, serialization.


static func _body() -> BodyHealth:
	return BodyHealth.new()


static func _status() -> StatusEffects:
	return StatusEffects.new()


static func run(t: RangeTest) -> void:
	_meters(t)
	_items(t)
	_wound_care(t)
	_pools(t)
	_buffs(t)
	_serialize(t)


static func _meters(t: RangeTest) -> void:
	var s := _status()
	var b := _body()
	s.on_hit(100.0, false, false)
	t.check("med: 100 damage fills the pain meter", s.m["pain"] >= 1.0, str(s.m["pain"]))
	t.check("med: full pain gives tremor (sway x2)", s.tremor() and s.sway_mult() == 2.0)
	t.check("med: full pain slows ADS", s.ads_time_mult() > 1.0)
	s.bump("pain", -1.0)
	t.check("med: pain decays below full, tremor stops", not s.tremor())
	# Analgin suppresses pain effects without clearing the meter.
	s.on_hit(100.0, false, false)
	s.apply_med({"effect": "pain_off", "dur": 95.0}, "", b)
	t.check("med: analgin suppresses tremor while the meter is full", not s.tremor() and s.pain_off_t > 90.0)
	# Radiation.
	var s2 := _status()
	s2.tick(20.0, {"in_hot_zone": true}, b)
	t.check("med: 20 s in the hot zone fills radiation", s2.m["radiation"] >= 1.0, str(s2.m["radiation"]))
	t.check("med: full radiation cuts max stamina", s2.max_stamina_mult() < 1.0)
	var s3 := _status()
	s3.iodine_t = 300.0
	s3.tick(20.0, {"in_hot_zone": true}, b)
	t.check("med: iodine slows radiation build-up", s3.m["radiation"] < 1.0, str(s3.m["radiation"]))
	# Dehydration / energy drain faster when sprinting.
	var s4 := _status()
	s4.tick(60.0, {"sprinting": true}, b)
	var s5 := _status()
	s5.tick(60.0, {}, b)
	t.check("med: sprinting drains dehydration and energy faster",
		s4.m["dehydration"] > s5.m["dehydration"] and s4.m["energy"] > s5.m["energy"])
	var f1 := func() -> bool:
		var x := _status()
		x.bump("dehydration", 1.0)
		return x.stamina_regen_mult() == 0.5
	t.check("med: full dehydration halves stamina regen", f1.call())
	var f2 := func() -> bool:
		var x := _status()
		x.bump("energy", 1.0)
		return x.stamina_regen_mult() == 0.5
	t.check("med: full energy halves stamina regen", f2.call())
	# Contusion decays over ~10 s.
	var s6 := _status()
	s6.add_contusion()
	t.check("med: contusion muffles audio at full", s6.muffle() == 1.0)
	s6.tick(11.0, {}, b)
	t.check("med: contusion clears after ~10 s", s6.muffle() == 0.0)


static func _items(t: RangeTest) -> void:
	for id in ["med_bandage", "med_esmarch", "med_splint", "med_cms", "med_ai2", "med_car",
			"med_salewa", "med_grizzly", "med_analgin", "med_morphine", "med_propital",
			"med_sj6", "med_adrenaline", "med_etgc", "med_iodine", "med_water", "med_juice",
			"med_crackers", "med_mre", "med_stim", "med_ifak"]:
		var d := ItemDefs.of(id)
		t.check("med: item def %s has a use effect" % id, d["kind"] == "med" and (d.get("use", {}) as Dictionary).has("effect"))
	t.check("med: CMS kit has 3 uses", int(ItemDefs.make("med_cms").get("uses", 0)) == 3)
	t.check("med: analgin has 4 uses", int(ItemDefs.make("med_analgin").get("uses", 0)) == 4)
	t.check("med: stim is a MED item (MED owns it)", ItemDefs.of("med_stim")["kind"] == "med")


static func _wound_care(t: RangeTest) -> void:
	var b := _body()
	var s := _status()
	b.bleeds.append({"zone": "larm", "rate": TacticalConfig.LIGHT_BLEED_DPS})
	b.bleeds.append({"zone": "rleg", "rate": TacticalConfig.HEAVY_BLEED_DPS})
	b.fractured["lleg"] = true
	s.apply_med(ItemDefs.of("med_bandage")["use"], "larm", b)
	t.check("med: bandage stops the light bleed only", b.bleeds.size() == 1)
	s.apply_med(ItemDefs.of("med_esmarch")["use"], "rleg", b)
	t.check("med: esmarch stops the heavy bleed", b.bleeds.is_empty())
	s.apply_med(ItemDefs.of("med_splint")["use"], "lleg", b)
	t.check("med: splint fixes the fracture", not b.fractured.has("lleg"))
	# Surgery restores a blacked limb at 60 %.
	var b2 := _body()
	b2.hit("larm", 80.0)  # blacks the 60 HP arm; the 20 spill won't kill
	t.check("med: test setup blacked the arm", b2.hp["larm"] <= 0.0)
	t.check("med: surgery restores at 60 % max", s.apply_med(ItemDefs.of("med_cms")["use"], "larm", b2)["msg"] != "" \
		and b2.hp["larm"] == BodyHealth.MAX["larm"] * 0.6 and b2.zone_max("larm") == BodyHealth.MAX["larm"] * 0.6)
	t.check("med: surgery on a healthy limb refuses", not b2.surgery("rarm"))
	# Zone picker refuses when there is nothing to treat.
	t.check("med: bandage with no bleed has no target",
		StatusEffects.pick_zone(b2, ItemDefs.of("med_bandage")["use"], "") == "NO_TARGET")


static func _pools(t: RangeTest) -> void:
	var b := _body()
	var s := _status()
	b.hit("thorax", 80.0)   # 5/85 left
	b.hit("stomach", 60.0)  # 10/70 left
	s.apply_med(ItemDefs.of("med_ai2")["use"], "", b)
	t.check("med: AI-2 pool heals the worst zone first, then the next",
		b.hp["thorax"] == b.zone_max("thorax") and b.hp["stomach"] > 10.0 and b.hp["stomach"] < b.zone_max("stomach"))
	var b2 := _body()
	b2.hit("thorax", 80.0)
	b2.hit("stomach", 60.0)
	s.apply_med(ItemDefs.of("med_salewa")["use"], "", b2)
	t.check("med: salewa's bigger pool fully heals what AI-2 could not",
		b2.hp["thorax"] == b2.zone_max("thorax") and b2.hp["stomach"] == b2.zone_max("stomach"))
	var b3 := _body()
	b3.bleeds.append({"zone": "rarm", "rate": TacticalConfig.LIGHT_BLEED_DPS})
	s.apply_med(ItemDefs.of("med_car")["use"], "", b3)
	t.check("med: car kit stops light bleeds", b3.bleeds.is_empty())
	var b4 := _body()
	b4.fractured["rleg"] = true
	b4.bleeds.append({"zone": "rleg", "rate": TacticalConfig.HEAVY_BLEED_DPS})
	s.apply_med(ItemDefs.of("med_grizzly")["use"], "", b4)
	t.check("med: grizzly clears all wounds", b4.bleeds.is_empty() and b4.fractured.is_empty())


static func _buffs(t: RangeTest) -> void:
	var b := _body()
	var s := _status()
	# Propital regen.
	s.apply_med(ItemDefs.of("med_propital")["use"], "", b)
	b.hit("stomach", 40.0)
	var before: float = b.hp["stomach"]
	s.tick(10.0, {}, b)
	t.check("med: propital regenerates ~1 HP/s", b.hp["stomach"] > before + 5.0, str(b.hp["stomach"] - before))
	# Morphine dehydrates as a side effect.
	var s2 := _status()
	s2.apply_med(ItemDefs.of("med_morphine")["use"], "", b)
	t.check("med: morphine adds dehydration", float(s2.m["dehydration"]) > 0.29)
	t.check("med: morphine pain block lasts 300 s", s2.pain_off_t >= 299.0)
	# SJ6 side effects land when it expires.
	var s3 := _status()
	s3.apply_med(ItemDefs.of("med_sj6")["use"], "", b)
	t.check("med: SJ6 buffs stamina regen", s3.stam_buff_t > 200.0 and s3.stamina_regen_mult() > 1.0)
	s3.tick(241.0, {}, b)
	t.check("med: SJ6 expiry adds fatigue and tremor", float(s3.m["fatigue"]) > 0.4 and s3.tremor())
	# eTG-c toxicates.
	var s4 := _status()
	s4.apply_med(ItemDefs.of("med_etgc")["use"], "", b)
	t.check("med: eTG-c builds toxication", float(s4.m["toxication"]) > 0.39)
	# Hydration / food.
	var s5 := _status()
	s5.bump("dehydration", 0.8)
	s5.apply_med(ItemDefs.of("med_water")["use"], "", b)
	t.check("med: water restores hydration", float(s5.m["dehydration"]) < 0.31)
	s5.bump("energy", 0.8)
	s5.apply_med(ItemDefs.of("med_mre")["use"], "", b)
	t.check("med: MRE restores energy", float(s5.m["energy"]) < 0.21)


static func _serialize(t: RangeTest) -> void:
	var s := _status()
	s.bump("pain", 0.7)
	s.bump("radiation", 0.3)
	s.pain_off_t = 42.0
	s.regen_rate = 1.0
	s.regen_t = 100.0
	var d := s.to_dict()
	var s2 := _status()
	s2.from_dict(d)
	t.check("med: status round-trips through to_dict", s2.m["pain"] == 0.7 and s2.m["radiation"] == 0.3 \
		and s2.pain_off_t == 42.0 and s2.regen_rate == 1.0 and s2.regen_t == 100.0)
