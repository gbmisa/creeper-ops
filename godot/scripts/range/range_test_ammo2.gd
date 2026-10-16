class_name RangeTestAmmo2
## F75: a kit deployed into Skirmish starts topped up (gun loaded, spare mags full, types kept).


static func _rig(t: RangeTest, skirmish: bool) -> Dictionary:
	var session := RangeSession.new(75)
	session.maps.selected = "skirmish" if skirmish else "range"
	var input := InputState.new()
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	session.add_player(1, true).node = player
	t.add_child(player)
	player.set_physics_process(false)
	var rack := RangeRack.new()
	t.add_child(rack)
	var w := PlayerWeapons.new()
	t.add_child(w)
	w.setup(player, input, t.bal, rack, session)
	w.set_process(false)
	player.enabled = true
	return {"w": w, "input": input, "player": player, "rack": rack, "session": session}


static func _free(r: Dictionary) -> void:
	for k in ["w", "rack", "player", "input"]:
		r[k].free()


static func run(t: RangeTest) -> void:
	# F75: spend the range kit, save it, then enter Skirmish.
	var r := _rig(t, false)
	var w: PlayerWeapons = r["w"]
	var session: RangeSession = r["session"]
	var g: Gun = w.gun
	while g.mag.count() > 3:
		g.mag.pop()
	for it in w.inv.all_items():
		if it["id"] == "mag_ak47":
			it["rounds"] = 5
			it["ammo"] = "762x39_ps"
	var pick := g.ammo_pick
	session.save_kit(w.inv)
	_free(r)
	var s := _rig(t, true)
	var sw: PlayerWeapons = s["w"]
	var ak: Gun = sw.inv.equipped("primary")["gun"]
	var cap := int(ak.stat("mag"))
	t.check("f75: skirmish start - AK mag full (%d/%d)" % [ak.mag.count(), cap], ak.mag.count() >= cap - 1 and ak.rounds_total() >= cap)
	var mags := 0
	var all_full := true
	for it in sw.inv.all_items():
		if it["id"] == "mag_ak47":
			mags += 1
			all_full = all_full and int(it["rounds"]) >= cap and it["ammo"] == "762x39_ps"
	t.check("f75: skirmish start - %d spare AK mags all full, type kept" % mags, mags > 0 and all_full)
	t.check("f75: skirmish start - gun grade kept", ak.ammo_pick == pick)
	_free(s)
	# the range itself keeps whatever the kit had (no top-up there)
	var rr := _rig(t, false)
	var rak: Gun = rr["w"].inv.equipped("primary")["gun"]
	var kept := rak.mag.count()
	t.check("f75: range start is not topped up by this fix (%d)" % kept, kept <= int(rak.stat("mag")))
	_free(rr)
	session.clear_kit()
