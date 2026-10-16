class_name RangeTestNoAmmo
## F78: in Skirmish, R with no spare mag / rounds does nothing (no action signal, so no animation or sound; gun idle).


static func run(t: RangeTest) -> void:
	for id in ["ak47", "shotgun", "garand"]:
		var r := RangeTestAmmo2._rig(t, true)
		var w: PlayerWeapons = r["w"]
		for it in w.inv.all_items().duplicate():
			if it["id"] in ItemDefs.ROWS and ItemDefs.ROWS[it["id"]]["kind"] == "mag" or it["id"] in TacAmmoDefs.ROWS:
				w.inv.request_remove(it)
		w.give(id)
		var g: Gun = w.gun
		while g.mag.count() > 0:
			g.mag.pop()
		g.chamber = ""
		g.spares.clear()
		var acts := [0]
		w.action.connect(func(_k, _s): acts[0] += 1)
		r["input"].frame._pressed["t_reload"] = true
		w._commands()
		r["input"].frame._pressed.clear()
		t.check("f78: %s R with nothing to load - no animation/sound, gun idle" % id, acts[0] == 0 and g.busy_kind == "" and not w.gun_item.has("staged") and g.spares.is_empty())
		RangeTestAmmo2._free(r)


## Realistic run: shoot the gun dry, reload through every carried mag with R, then R again with nothing left.

	cycle(t)


static func cycle(t: RangeTest) -> void:
	var r := RangeTestAmmo2._rig(t, true)
	var w: PlayerWeapons = r["w"]
	var g: Gun = w.gun
	var acts := [0]
	w.action.connect(func(_k, _s): acts[0] += 1)
	var presses := 0
	for i in 8:
		while g.mag.count() > 0:
			g.mag.pop()
		g.chamber = ""
		g.needs_cycle = false
		r["input"].frame._pressed["t_reload"] = true
		w._process(0.016)
		r["input"].frame._pressed.clear()
		w._process(10.0)
		presses += 1
	var mags := 0
	for it in w.inv.all_items():
		if it["id"] == "mag_ak47":
			mags += 1
	# 3 spare mags: 3 reloads load; each returns an empty old mag (not usable), so reload 4+ must do nothing.
	t.check("f78: R past the last usable mag plays nothing (%d anims for %d presses)" % [acts[0], presses], acts[0] <= 3)
	RangeTestAmmo2._free(r)
