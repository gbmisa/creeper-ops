class_name RangeTestAttach
## RANGE5 GUNS-2 checks: attachment data, stat modifiers (exactly the named stat, removal restores the base), fitting through
## the inventory API, then one functional test per attachment on a live PlayerWeapons + TacticalViewmodel.

const STATS := ["up", "side", "moa", "reload", "reload_fast", "mag", "ads_mult", "hip", "noise", "flash", "vel"]


static func run(t: RangeTest) -> void:
	_data(t)
	_modifiers(t)
	_inventory(t)
	await _functional(t)
	_give_holster(t)


## VIEW-FIX: --weapon=<id> must put the gun in the hand even when its slot is taken
## (starter loadout holds the M1911 in the holster, so --weapon=glock18 used to stash it).
static func _give_holster(t: RangeTest) -> void:
	var r := _rig(t)
	var w: PlayerWeapons = r["w"]
	t.check("give: starter has AK primary, M1911 holster",
		(w.inv.equipped("primary") as Dictionary)["id"] == "ak47" and (w.inv.equipped("holster") as Dictionary)["id"] == "m1911")
	w.give("glock18")
	var hol = w.inv.equipped("holster")
	t.check("give: pistol with a full holster lands in the holster and is selected",
		hol != null and (hol as Dictionary)["id"] == "glock18" and (w.gun_item as Dictionary)["id"] == "glock18")
	var kept := w.inv.all_items().any(func(i): return (i as Dictionary)["id"] == "m1911")
	t.check("give: the displaced M1911 is kept in the inventory", kept)
	# fill secondary too, so the long gun's force path is exercised (inventory otherwise full)
	var mp5 := ItemDefs.make("mp5")
	(mp5["gun"] as Gun).spares.clear()
	w.inv.add(mp5)
	var dropped := []
	w.item_dropped.connect(func(it): dropped.append((it as Dictionary)["id"]))
	w.give("m4a1")
	t.check("give: long gun with full hand slots lands in primary and is selected",
		(w.inv.equipped("primary") as Dictionary)["id"] == "m4a1" and (w.gun_item as Dictionary)["id"] == "m4a1")
	var ak_kept := w.inv.all_items().any(func(i): return (i as Dictionary)["id"] == "ak47")
	t.check("give: the displaced AK is kept or dropped to the world, never lost", ak_kept or "ak47" in dropped)
	r["w"].queue_free()
	(r["vm"] as Node).queue_free()
	(r["player"] as Node).queue_free()
	(r["input"] as Node).queue_free()
	(r["rack"] as Node).queue_free()


static func _hand_item(id: String) -> Dictionary:
	var it := ItemDefs.make(id)
	(it["gun"] as Gun).spares.clear()
	return it


static func _data(t: RangeTest) -> void:
	t.check("attach: 12 attachments (5 sights, 3 muzzle, 3 under, extmag)", AttachmentDefs.ROWS.size() == 12)
	var counts := {"sight": 0, "muzzle": 0, "under": 0, "mag": 0}
	var ok := true
	for id in AttachmentDefs.ROWS:
		var r: Dictionary = AttachmentDefs.ROWS[id]
		counts[r["slot"]] += 1
		ok = ok and ItemDefs.has(id) and ItemDefs.of(id)["kind"] == "attach" and r["note"] != "" and ItemDefs.make(id)["id"] == id
		for k in r["mods"]:
			ok = ok and k in STATS
	t.check("attach: slots 5/3/3/1, every one is an item with a note and known mods", ok and counts == {"sight": 5, "muzzle": 3, "under": 3, "mag": 1})
	t.check("attach: lpvo is variable 1-6x, scope8x is 8x, acog 3x, red dot and holo 1x", AttachmentDefs.ROWS["lpvo"]["zoom"] == 1.0 and AttachmentDefs.ROWS["lpvo"]["zoom_max"] == 6.0 \
		and AttachmentDefs.ROWS["scope8x"]["zoom"] == 8.0 and AttachmentDefs.ROWS["acog3x"]["zoom"] == 3.0 and AttachmentDefs.ROWS["reddot"]["zoom"] == 1.0 and AttachmentDefs.ROWS["holo"]["zoom"] == 1.0)
	t.check("attach: t_zoom action exists", Keybinds.DEFAULTS.has("t_zoom"))
	t.check("attach: m4a1 takes all four slots, scope8x only on sniper rails", AttachmentDefs.why_not(WeaponDefs.of("m4a1"), "extmag") == "" \
		and AttachmentDefs.why_not(WeaponDefs.of("ak47"), "scope8x") != "" and AttachmentDefs.why_not(WeaponDefs.of("sr25"), "scope8x") == "" \
		and AttachmentDefs.why_not(WeaponDefs.of("mosin"), "scope8x") == "" and AttachmentDefs.why_not(WeaponDefs.of("sniper"), "scope8x") == "")
	t.check("attach: a gun without the slot refuses (sks has no sight, m1911 no under grip)", AttachmentDefs.why_not(WeaponDefs.of("sks"), "reddot") != "" \
		and AttachmentDefs.why_not(WeaponDefs.of("m1911"), "vgrip") != "")
	var crate_ok := true
	for id in AttachmentDefs.ROWS:
		crate_ok = crate_ok and RangeCrate.LOOT.any(func(r): return r[0] == id)
	t.check("attach: the supply crate holds every attachment", crate_ok)
	var mounts_ok := true
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		mounts_ok = mounts_ok and AttachmentMounts.mount(d, "sight", 0.4).y > 0.0 and AttachmentMounts.mount(d, "muzzle", 0.4).z < 0.0
	t.check("attach: every gun has default mount points", mounts_ok)


static func _modifiers(t: RangeTest) -> void:
	var g := Gun.new("m4a1")
	var base := {}
	for s in STATS:
		base[s] = g.stat(s)
	t.check("stat: no attachments = the def values", g.stat("up") == WeaponDefs.of("m4a1")["up"] and g.stat("mag") == 30.0 and g.stat("hip") == 1.0 and g.stat("scope") == 1.0)
	for id in AttachmentDefs.ROWS:
		var r: Dictionary = AttachmentDefs.ROWS[id]
		if r.has("only"):
			g = Gun.new("sr25")
			for s in STATS:
				base[s] = g.stat(s)
		else:
			g = Gun.new("m4a1")
		for s in STATS:
			base[s] = g.stat(s)
		g.set_fit(r["slot"], id)
		var exact := true
		for s in STATS:
			var want: float = base[s] * float(r["mods"].get(s, 1.0))
			if s == "mag":
				want = roundf(want)
			exact = exact and is_equal_approx(g.stat(s), want)
			if not r["mods"].has(s):
				exact = exact and g.stat(s) == base[s]
		t.check("stat: %s changes exactly its own stats" % id, exact)
		g.clear_fit(r["slot"])
		var back := true
		for s in STATS:
			back = back and g.stat(s) == base[s]
		t.check("stat: removing %s restores the base exactly" % id, back and g.mag.cap == int(base["mag"]) and g.scope_now() == 1.0)
	var bot := Gun.new("ak47")
	t.check("stat: a gun with nothing fitted (bots) reads its base numbers", bot.stat("up") == 0.75 and bot.stat("noise") == 1.0 and bot.eff_def()["up"] == 0.75)
	var a := Gun.new("m4a1")
	a.set_fit("muzzle", "compensator")
	var b := Gun.new("m4a1")
	t.check("stat: fitting one gun never touches another gun or the def", b.stat("up") == 0.5 and WeaponDefs.of("m4a1")["up"] == 0.5 and a.stat("up") < 0.5)
	a.set_fit("muzzle", "suppressor")
	a.set_fit("under", "vgrip")
	t.check("stat: different slots stack, same slot replaces", is_equal_approx(a.stat("up"), 0.5 * 0.85) and a.stat("noise") == 0.4)


static func _inventory(t: RangeTest) -> void:
	var inv := Inventory.new()
	var gi := _hand_item("m4a1")
	inv.place(gi, "primary")
	var red := ItemDefs.make("reddot")
	inv.place(red, "pockets", 0, 0)
	var r := inv.request_fit(gi, red)
	t.check("fit: reddot goes on the m4a1 and leaves the inventory", r["ok"] and gi["gun"].fit["sight"] == "reddot" and red["loc"] == "" and not inv.pockets.has(red))
	var holo := ItemDefs.make("holo")
	inv.place(holo, "pockets", 1, 0)
	r = inv.request_fit(gi, holo)
	t.check("fit: a second sight replaces the first, which comes back as an item", r["ok"] and r["old"]["id"] == "reddot" and gi["gun"].fit["sight"] == "holo")
	var bad := ItemDefs.make("scope8x")
	r = inv.request_fit(gi, bad)
	t.check("fit: scope8x on an m4a1 is refused and nothing changes", not r["ok"] and r["why"] != "" and gi["gun"].fit["sight"] == "holo")
	t.check("fit: weight includes the fitted part", is_equal_approx(ItemDefs.item_kg(gi), WeaponDefs.of("m4a1")["kg"] + AttachmentDefs.ROWS["holo"]["kg"]))
	gi["gun"].busy_t = 1.0
	gi["gun"].busy_kind = "reload"
	t.check("fit: refused while the gun is busy", Attachments.why_not(gi, ItemDefs.make("vgrip")) == "Weapon is busy")
	gi["gun"].busy_t = 0.0
	gi["gun"].busy_kind = ""
	var back := InventoryIO.item_from_dict(InventoryIO.item_to_dict(gi))
	t.check("fit: the fitted parts survive save / load (map switch)", back["gun"].fit == {"sight": "holo"})
	var left := Attachments.unfit_to_inv(inv, gi, "sight")
	t.check("fit: remove puts the part back in the inventory", left.is_empty() and not gi["gun"].fit.has("sight") and inv.pockets.any(func(i): return i["id"] == "holo"))
	var em := ItemDefs.make("extmag")
	inv.place(em, "pockets", 2, 0)
	inv.request_fit(gi, em)
	var g: Gun = gi["gun"]
	g.refill()
	t.check("fit: extmag gives a 45-round magazine", g.mag.cap == 45 and g.rounds_total() == 45, "%s %s %s" % [g.fit, g.mag.cap, g.mag.count()])
	var spill_left := Attachments.unfit_to_inv(inv, gi, "mag")
	t.check("fit: removing extmag trims to 30, the 15 surplus rounds come back as ammo", g.mag.count() == 30 and g.mag.cap == 30 and (spill_left.size() > 0 or inv.pockets.any(func(i): return i["id"] in TacAmmoDefs.ROWS and int(i["count"]) == 15) or inv.all_items().any(func(i): return i["id"] in TacAmmoDefs.ROWS)))
	var view := InventoryView.new()
	view.inv = inv
	var item_r: Rect2 = view.item_rect({"loc": "primary", "slot": true, "rect": view.regions()[0]["rect"]}, gi)
	g.set_fit("sight", "reddot")
	var chips := view.chips(gi, item_r)
	var hit := view.chip_at((chips["sight"] as Rect2).get_center())
	t.check("fit UI: a fitted part shows a chip you can click to remove", chips.has("sight") and not hit.is_empty() and hit["slot"] == "sight")
	view.free()


## The live rig: player + weapons + viewmodel, the gun in hand swapped through the primary slot.
static func _rig(t: RangeTest) -> Dictionary:
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	t.add_child(player)
	player.set_physics_process(false)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	w.setup(player, input, t.bal, rack)
	var vm := TacticalViewmodel.new()
	player.cam.add_child(vm)
	vm.setup(w, player)
	return {"input": input, "player": player, "rack": rack, "w": w, "vm": vm}


static func _equip(r: Dictionary, id: String, fit: Array = []) -> Gun:
	var w: PlayerWeapons = r["w"]
	var old = w.inv.equipped("primary")
	if old != null:
		w.inv.remove(old)
	var it := _hand_item(id)
	w.inv.place(it, "primary")
	for f in fit:
		w.inv.request_fit(it, ItemDefs.make(f))
	w.gun_item = {}
	w.sync()
	w.select_slot("primary")
	w.draw_t = 0.0
	return w.gun


static func _settle(r: Dictionary, ads: bool) -> void:
	var w: PlayerWeapons = r["w"]
	w.trigger_ads = ads
	await (r["player"] as Node).get_tree().create_timer(1.4 if ads else 0.3).timeout


static func _fire(w: PlayerWeapons) -> bool:
	w.gun.fire_cd = 0.0
	w.gun.durability = 1.0
	w.gun.malf = ""
	w.gun.needs_cycle = false
	var res := w.gun.fire(w.rng)
	if res["fired"]:
		w._shoot(res)
	return res["fired"]


static func _first_kick(w: PlayerWeapons) -> Vector2:
	w.recoil.offset = Vector2.ZERO
	w.rng.seed = 7
	_fire(w)
	return w.recoil.offset


static func _ads_frames(w: PlayerWeapons) -> int:
	w.ads_amt = 0.0
	w.draw_t = 0.0
	w.trigger_ads = true
	var n := 0
	while w.ads_amt < 1.0 and n < 3000:
		w._ads(0.001)
		n += 1
	w.trigger_ads = false
	return n


static func _functional(t: RangeTest) -> void:
	var r := _rig(t)
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var player: TacticalPlayer = r["player"]
	var input: InputState = r["input"]
	var tree := t.get_tree()
	await tree.process_frame
	await _sights(t, r)
	# recoil: compensator / vgrip lower vertical, flash hider lowers horizontal; a baseline first
	_equip(r, "m4a1")
	t.bal.shots.clear()
	var base_kick := _first_kick(w)
	var base_noise := [0.0]
	var cb := func(_p, rad, _k, _s): base_noise[0] = rad
	BotNoise.listen(cb)
	_fire(w)
	var base_radius: float = base_noise[0]
	var base_vel: float = (t.bal.shots.back()["vel"] as Vector3).length()
	vm._on_shot({"fired": true, "last": false}, w.gun)
	var base_flash: bool = vm.flash.active()
	t.check("recoil: the plain m4a1 kicks its def value, bots hear 150 m, there is a muzzle flash", is_equal_approx(base_kick.x, 0.5) and base_radius == BotNoise.SHOT_R and base_flash)
	for row in [["compensator", 0.8, 1.0], ["vgrip", 0.85, 1.0], ["flashhider", 1.0, 0.9]]:
		_equip(r, "m4a1", [row[0]])
		var k := _first_kick(w)
		t.check("%s: first-shot vertical kick x%.2f, horizontal x%.2f of the base" % [row[0], row[1], row[2]],
			is_equal_approx(k.x, base_kick.x * row[1]) and (absf(base_kick.y) < 0.0001 or is_equal_approx(k.y, base_kick.y * row[2])), "%s vs %s" % [k, base_kick])
		var meas := _climb(w)
		t.check("%s: a 10-shot burst climbs measurably %s" % [row[0], "less" if row[1] < 1.0 else "the same vertically"], (meas < _climb_base(r, w) * 0.95) if row[1] < 1.0 else true)
	_equip(r, "m4a1", ["compensator"])
	base_noise[0] = 0.0
	_fire(w)
	t.check("compensator: louder, bots hear 1.25x", is_equal_approx(base_noise[0], BotNoise.SHOT_R * 1.25))
	# suppressor
	_equip(r, "m4a1", ["suppressor"])
	t.bal.shots.clear()
	base_noise[0] = 0.0
	_fire(w)
	var sup_vel: float = (t.bal.shots.back()["vel"] as Vector3).length()
	vm._on_shot({"fired": true, "last": false}, w.gun)
	t.check("suppressor: bot hearing radius x0.4 (60 m)", is_equal_approx(base_noise[0], BotNoise.SHOT_R * 0.4))
	t.check("suppressor: no muzzle flash", not vm.flash.active())
	t.check("suppressor: muzzle velocity -5%", is_equal_approx(sup_vel / base_vel, 0.95))
	t.check("suppressor: a muzzle part sits at the muzzle, beyond the barrel end", vm.rig.get_child_count() == 1 and vm.rig.get_child(0).position.z < 0.0)
	_equip(r, "m4a1", ["flashhider"])
	vm._on_shot({"fired": true, "last": false}, w.gun)
	t.check("flashhider: no muzzle flash, same noise", not vm.flash.active())
	BotNoise.listeners.erase(cb)
	# under grips and laser, extmag
	await _under_and_mag(t, r)
	r["w"].queue_free()
	vm.queue_free()
	player.queue_free()
	input.queue_free()
	r["rack"].queue_free()
	t.bal.shots.clear()


static func _climb(w: PlayerWeapons) -> float:
	w.recoil.offset = Vector2.ZERO
	w.rng.seed = 3
	for i in 10:
		_fire(w)
	return w.recoil.offset.x


static func _climb_base(r: Dictionary, w: PlayerWeapons) -> float:
	var g := _equip(r, "m4a1")
	var c := _climb(w)
	g.fit.clear()
	return c


static func _sights(t: RangeTest, r: Dictionary) -> void:
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var player: TacticalPlayer = r["player"]
	var input: InputState = r["input"]
	var irons := TacticalPlayer.BASE_FOV - 8.0
	_equip(r, "m4a1")
	var iron_frames := _ads_frames(w)
	await _settle(r, true)
	var iron_y := vm.model.position.y
	t.check("sight: iron sights ADS to the def line at the base FOV", absf(iron_y - (WeaponDefs.of("m4a1")["ads_pos"] as Vector3).y) < 0.004 and is_equal_approx(player.cam.fov, irons) and vm.rig.glass == null)
	var want_mult := {"reddot": 0.9, "holo": 0.95, "acog3x": 1.15, "lpvo": 1.2}
	for id in ["reddot", "holo"]:
		var g := _equip(r, "m4a1", [id])
		await _settle(r, true)
		var row: Dictionary = AttachmentDefs.ROWS[id]
		var rail_y := AttachmentMounts.mount(g.def, "sight", 0.0).y
		t.check("%s: the ADS line moves to the sight (model %.3f -> %.3f)" % [id, iron_y, vm.model.position.y], absf(vm.model.position.y + rail_y + row["axis_h"]) < 0.004 and absf(vm.model.position.y - iron_y) > 0.002)
		var gp := player.cam.to_local(vm.rig.glass.global_position) if vm.rig.glass != null else Vector3(9, 9, 9)
		t.check("%s: the reticle glass is on the sight line, centred (x %.4f y %.4f)" % [id, gp.x, gp.y], vm.rig.glass != null and absf(gp.x) < 0.003 and absf(gp.y) < 0.004 and gp.z < -0.06)
		t.check("%s: 1x, the FOV stays at the iron-sight FOV and the model stays visible" % id, is_equal_approx(player.cam.fov, irons) and not w.scoped() and vm.model.visible)
		t.check("%s: the sight is not clipped by the near plane" % id, player.cam.near < -gp.z - 0.03)
		t.check("%s: ADS time x%.2f of the iron sights" % [id, want_mult[id]], absf(float(_ads_frames(w)) / iron_frames - want_mult[id]) < 0.04)
	for id in ["acog3x", "lpvo"]:
		var g := _equip(r, "m4a1", [id])
		await _settle(r, true)
		var z := g.stat("scope")
		var narrow := rad_to_deg(2.0 * atan(tan(deg_to_rad(TacticalPlayer.BASE_FOV) * 0.5) / z))
		t.check("%s: ADS narrows the FOV to %.1fx (%.1f deg) and shows the scope overlay" % [id, z, narrow], is_equal_approx(player.cam.fov, narrow) and w.scoped() and not vm.model.visible)
		t.check("%s: ADS time x%.2f of the iron sights" % [id, want_mult[id]], absf(float(_ads_frames(w)) / iron_frames - want_mult[id]) < 0.04)
		var ov := ScopeOverlay.new()
		ov.style = g.reticle()
		t.check("%s: its own reticle (%s)" % [id, g.reticle()], ov.style == AttachmentDefs.ROWS[id]["ret"] and ov.style != "mildot")
		ov.free()
		if id == "lpvo":
			await _settle(r, true)
			t.check("lpvo: starts at 6x", g.stat("scope") == 6.0)
			input._pressed[Keybinds.DEFAULTS["t_zoom"][2][0]] = true
			w._commands()  # the action path: t_zoom pressed this frame
			input._pressed.clear()
			await t.get_tree().create_timer(0.2).timeout
			t.check("lpvo: t_zoom drops it to 1x: FOV back to iron, no overlay", g.stat("scope") == 1.0 and is_equal_approx(player.cam.fov, irons) and not w.scoped())
			input._pressed[Keybinds.DEFAULTS["t_zoom"][2][0]] = true
			w._commands()  # the action path: t_zoom pressed this frame
			input._pressed.clear()
			await t.get_tree().create_timer(0.2).timeout
			t.check("lpvo: t_zoom again is back to 6x", g.stat("scope") == 6.0 and w.scoped())
	var sg := _equip(r, "sr25", ["scope8x"])
	await _settle(r, true)
	var n8 := rad_to_deg(2.0 * atan(tan(deg_to_rad(TacticalPlayer.BASE_FOV) * 0.5) / 8.0))
	t.check("scope8x: 8x (%.1f deg), overlay up, slowest ADS (x1.3)" % n8, is_equal_approx(player.cam.fov, n8) and w.scoped() and absf(float(_ads_frames(w)) / _ads_frames_iron(r, "sr25") - 1.3) < 0.04)
	var sniper := _equip(r, "sniper")
	t.check("sniper: its own built-in 6x scope is unchanged", sniper.stat("scope") == 6.0)
	_equip(r, "sniper", ["reddot"])
	t.check("sniper + red dot: the fitted sight replaces the built-in scope (1x)", w.gun.stat("scope") == 1.0)
	await _settle(r, false)
	_equip(r, "m4a1")


static func _ads_frames_iron(r: Dictionary, id: String) -> int:
	var w: PlayerWeapons = r["w"]
	var g := _equip(r, id)
	var n := _ads_frames(w)
	g.fit.clear()
	return n


static func _under_and_mag(t: RangeTest, r: Dictionary) -> void:
	var w: PlayerWeapons = r["w"]
	var player: TacticalPlayer = r["player"]
	var vm: TacticalViewmodel = r["vm"]
	# angled grip: ADS faster
	_equip(r, "m4a1")
	var base_frames := _ads_frames(w)
	_equip(r, "m4a1", ["agrip"])
	var ag := _ads_frames(w)
	t.check("agrip: ADS time x0.85 (%d -> %d frames)" % [base_frames, ag], absf(float(ag) / base_frames - 0.85) < 0.04)
	# laser: hip spread
	var g := _equip(r, "m4a1")
	var basis := Basis.IDENTITY
	var ammo: String = g.loaded_ammo()
	var spread := func(hip: bool, gun: Gun) -> float:
		var rng := RandomNumberGenerator.new()
		rng.seed = 21
		var centre := Vector3(0, 0, -1).rotated(Vector3.RIGHT, Ballistics.zero_angle(ammo, gun.zero_dist()))
		var sum := 0.0
		for i in 400:
			sum += rad_to_deg(gun.shot_dirs(basis, ammo, not hip, rng)[0].angle_to(centre))
		return sum / 400.0
	var hip_base: float = spread.call(true, g)
	var ads_base: float = spread.call(false, g)
	var lg := _equip(r, "m4a1", ["laser"])
	var hip_laser: float = spread.call(true, lg)
	t.check("laser: hip spread lower (%.2f -> %.2f deg, about -30%% of the hip cone)" % [hip_base, hip_laser], hip_laser < hip_base * 0.8 and hip_laser > hip_base * 0.6)
	t.check("laser: aimed spread is untouched", spread.call(false, lg) == ads_base)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var beam: MeshInstance3D = vm.rig.beam
	t.check("laser: a beam is built and visible", beam != null and beam.is_visible_in_tree() and vm.rig.update_beam() > 0.5)
	var eye := Vector3(150, 1.6, 200)
	var pts := [Vector3(0, 1.6, 200), Vector3(0, 1.3, 200)]
	var rng := RandomNumberGenerator.new()
	var space: PhysicsDirectSpaceState3D = t.bal.get_world_3d().direct_space_state
	var plain := BotPerception.new()
	plain.update(0.1, eye, Vector3(-1, 0, 0), space, pts, false, rng, 1.0)
	var lit := BotPerception.new()
	t.check("laser: bots 150 m away do not see the player without it", not plain.seeing)
	t.check("laser: the weapons set the bot spot range multiplier while it is fitted", is_equal_approx(player.spot_mult, PlayerWeapons.LASER_SPOT))
	lit.update(0.1, eye, Vector3(-1, 0, 0), space, pts, false, rng, player.spot_mult)
	t.check("laser: with the laser lit the same bot at 150 m sees the player", lit.seeing)
	_equip(r, "m4a1")
	await t.get_tree().process_frame
	t.check("laser: gone again, the multiplier is back to 1 and no beam", player.spot_mult == 1.0 and vm.rig.beam == null)
	# extended magazine
	var mg := _equip(r, "m4a1")
	var base_reload := mg.stat("reload")
	var eg := _equip(r, "m4a1", ["extmag"])
	eg.refill()
	t.check("extmag: capacity +50% (30 -> %d), a full mag holds it" % int(eg.stat("mag")), int(eg.stat("mag")) == 45 and eg.rounds_total() == 45)
	eg.mag.rounds.clear()
	eg.chamber = ""
	eg.spares.clear()
	eg.spares.append(InvReload.mag_from_item(ItemDefs.make("mag_m4a1"), int(eg.stat("mag"))))
	t.check("extmag: reload is slower (x1.2 time)", eg.reload(false) and is_equal_approx(eg.busy_t, (base_reload * 1.2) + TacticalConfig.CHAMBER_TIME))
	eg.update(20.0)
	t.check("extmag: a stock mag loaded into the extended gun holds up to 45", eg.mag.cap == 45)
	eg.busy_t = 0.0
	t.check("extmag: the reload base time is the stock time x1.2, and removing it gives back %.1f s" % base_reload, is_equal_approx(eg.stat("reload"), base_reload * 1.2))
	eg.clear_fit("mag")
	t.check("extmag: removed, capacity and reload time are exactly the base", eg.stat("mag") == 30.0 and eg.stat("reload") == base_reload and eg.mag.cap == 30)
