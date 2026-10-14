class_name RangeTestTempest
## Hidden chords and the secret Tempest railgun: not in DEFAULTS / ORDER / rack / crate, the chord gives and removes it (holster slot,
## 0 kg, sidearm returns), the rail round goes through a wall and kills a plate-armored dummy, chain lightning kills nearby bots.


class FakeBot extends Node3D:
	var body := BodyHealth.new()
	func on_hit(_res: Dictionary) -> void:
		pass


static func run(t: RangeTest) -> void:
	_hidden(t)
	await _toggle(t)
	await _rail(t)


static func _hidden(t: RangeTest) -> void:
	var codes := []
	for id in Keybinds.HIDDEN:
		codes.append_array(Keybinds.HIDDEN[id])
	var clash := false
	for id in Keybinds.DEFAULTS:
		for k in Keybinds.keys(id):
			clash = clash or codes.has(k)
	t.check("hidden chords: secret_tempest + cheat_menu, none in DEFAULTS or the Controls screen", Keybinds.HIDDEN.has("secret_tempest")
		and Keybinds.HIDDEN.has("cheat_menu") and not Keybinds.DEFAULTS.has("secret_tempest") and not Keybinds.DEFAULTS.has("cheat_menu") and not clash)
	t.check("hidden chords: Ctrl+Alt+P and Ctrl+Numpad 5", Keybinds.HIDDEN["secret_tempest"] == [KEY_P | KEY_MASK_CTRL | KEY_MASK_ALT]
		and Keybinds.HIDDEN["cheat_menu"] == [KEY_KP_5 | KEY_MASK_CTRL])
	var inp := InputState.new()
	t.add_child(inp)
	inp._pressed[KEY_P] = true
	var plain := inp.act_hidden("secret_tempest")
	inp._pressed[KEY_P | KEY_MASK_CTRL | KEY_MASK_ALT] = true
	t.check("hidden chords: act_hidden needs the full chord", not plain and inp.act_hidden("secret_tempest") and not inp.act_hidden("cheat_menu"))
	inp.queue_free()
	var in_rack := false
	for row in RangeRack.GRID:
		in_rack = in_rack or SecretArms.TEMPEST in row
	var in_loot := false
	for row in RangeCrate.LOOT:
		in_loot = in_loot or row[0] == SecretArms.TEMPEST
	t.check("tempest: hidden from ORDER, RACK_ROWS, the rack, crates and loot", not WeaponDefs.ORDER.has("tempest") and not WeaponDefs.ROWS.has("tempest")
		and not str(WeaponDefs.RACK_ROWS).contains("tempest") and not in_rack and not in_loot)
	var d := WeaponDefs.of("tempest")
	t.check("tempest: 0 kg, 2x1 pistol-size, full auto 600 rpm, 200-round cell, no recoil", d["kg"] == 0.0 and d["inv_w"] == 2 and d["inv_h"] == 1
		and d["rpm"] == 600.0 and d["mag"] == 200 and d["modes"] == ["auto"] and d["no_recoil"] and ItemDefs.of("tempest")["pistol"])
	var a := TacAmmoDefs.of(SecretArms.CELL)
	t.check("tempest: cell is flat (v0 2500, no drag), pen 100, kills any zone", a["v0"] == 2500.0 and a["drag"] == 0.0 and a["pen"] == 100.0 and a["dmg"] >= BodyHealth.MAX["thorax"] * 10.0)
	t.check("tempest: own sound profile (pitched-up crack)", SoundDefs.profile_of("tempest") == "tempest" and SoundDefs.PROFILES["tempest"]["pitch"] > 1.0
		and RangeAudio.stream(SoundDefs.gun_event("tempest", "shot")) != null)


static func _toggle(t: RangeTest) -> void:
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	t.add_child(player)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	var bal := Ballistics.new()
	t.add_child(bal)
	w.setup(player, input, bal, rack)
	var wi := WorldItems.new()
	t.add_child(wi)
	wi.setup(player, w)
	await t.get_tree().physics_frame
	var side = w.inv.equipped("holster")
	var side_uid: int = side["uid"]
	var kg := w.inv.total_kg()
	t.check("tempest toggle: starts with a sidearm in the holster", side != null and side["id"] != "tempest")
	Tempest.toggle(w, wi)
	t.check("tempest on: occupies the holster and is in hand", w.inv.equipped("holster")["id"] == "tempest" and w.gun.id == "tempest" and w.gun_item["loc"] == "holster")
	t.check("tempest on: carried weight is unchanged (Tempest is 0 kg)", is_equal_approx(w.inv.total_kg(), kg), "%f vs %f" % [w.inv.total_kg(), kg])
	var kept := false
	for it in w.inv.all_items():
		kept = kept or it["uid"] == side_uid
	for pack in [w.inv.equipped("backpack"), w.inv.equipped("rig")]:
		if pack != null:
			for it in pack["items"]:
				kept = kept or it["uid"] == side_uid
	t.check("tempest on: the old sidearm went to the stash, not lost", kept or wi.items.any(func(i): return i["uid"] == side_uid))
	t.check("tempest on: nothing else in hand slots changed", w.inv.equipped("primary") != null and w.inv.equipped("primary")["id"] == "ak47")
	w.gun.fire_cd = 0.0
	var rng := RandomNumberGenerator.new()
	var burst := 0
	for i in 5:
		w.gun.fire_cd = 0.0
		burst += int(w.gun.fire(rng)["fired"])
	t.check("tempest: fires full auto, 200 rounds in the cell", burst == 5 and w.gun.mag.count() + (1 if w.gun.chamber != "" else 0) == 200 - 5)
	Tempest.toggle(w, wi)
	var back = w.inv.equipped("holster")
	t.check("tempest off: the previous sidearm is back in the holster and in hand", back != null and back["uid"] == side_uid and w.gun_item["uid"] == side_uid)
	t.check("tempest off: Tempest gone, weight unchanged", is_equal_approx(w.inv.total_kg(), kg) and not w.inv.all_items().any(func(i): return i["id"] == "tempest"))
	w.inv.remove(w.inv.equipped("holster"))  # no sidearm at all: toggling restores the empty holster
	Tempest.toggle(w, wi)
	Tempest.toggle(w, wi)
	t.check("tempest toggle with an empty holster leaves it empty", w.inv.equipped("holster") == null)
	for n in [input, player, rack, w, bal, wi]:
		n.queue_free()


static func _dummy(t: RangeTest, x: float, armor: Array) -> BodyHealth:
	var dummy := Node3D.new()
	dummy.position = Vector3(x, 0, -8)
	t.add_child(dummy)
	var body := BodyHealth.new()
	for a in armor:
		body.equip(a)
	HitboxRig.build(dummy, body, dummy)
	return body


static func _rail(t: RangeTest) -> void:
	var x := 60.0
	var body := _dummy(t, x, ["plate4", "helmet3"])
	t._wall(Vector3(x, 1.5, -5), Vector3(4, 3, 0.02), "brick", 0.02)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t._fly("762_ps", Vector3(x, 1.3, 0), Vector3(0, 0, -1))
	var ps_blocked := t._hits.is_empty() and not body.dead
	t._fly(SecretArms.CELL, Vector3(x, 1.3, 0), Vector3(0, 0, -1))
	t.check("tempest rail: goes through a wall that stops a 7.62 PS", ps_blocked and not t._impacts.is_empty() and t._impacts[0]["kind"] == "pass")
	t.check("tempest rail: kills a plate-armored dummy through the wall", not t._hits.is_empty() and body.dead and t._hits[0]["result"] == "PEN")
	var flat := Vector3(0, 0, -1)
	t._wall(Vector3(80, 0, -300.25), Vector3(8, 40, 0.5), "steel_target", 0.5)
	t._fly(SecretArms.CELL, Vector3(80, 1.6, 0), flat.rotated(Vector3.RIGHT, Ballistics.zero_angle(SecretArms.CELL, 100.0)))
	t.check("tempest rail: flat trajectory (under 5 cm of drop at 300 m)", not t._impacts.is_empty() and absf(t._impacts[0]["pos"].y - 1.6) < 0.1 + 0.05, str(t._impacts[0]["pos"].y if not t._impacts.is_empty() else "none"))
	var head := _dummy(t, 70.0, ["helmet3"])
	await t.get_tree().physics_frame
	t._fly(SecretArms.CELL, Vector3(70, 1.66, 0), Vector3(0, 0, -1))
	t.check("tempest rail: helmet, no wall, still kills", head.dead)
	await _chain(t)


static func _chain(t: RangeTest) -> void:
	var fx := TempestFx.new()
	t.add_child(fx)
	var near := FakeBot.new()
	var far := FakeBot.new()
	t.add_child(near)
	t.add_child(far)
	near.global_position = Vector3(90, 0, -12)
	far.global_position = Vector3(90, 0, -30)
	var bots := [near, far]
	fx.bots_fn = func(): return bots
	t.bal.impact.connect(func(i): fx._on_hit(i["pos"], i["ammo"]))
	t._wall(Vector3(90, 1.5, -10), Vector3(4, 3, 0.5), "steel_target", 0.5)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t._fly(SecretArms.CELL, Vector3(90, 1.2, 0), Vector3(0, 0, -1))
	t.check("tempest chain lightning: kills a bot within 4 m of the impact, spares one farther away", near.body.dead and not far.body.dead)
	for n in [fx, near, far]:
		n.queue_free()
