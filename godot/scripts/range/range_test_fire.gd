class_name RangeTestFire
## F59: every gun, equipped on the live player as the game does, fires through PlayerWeapons._trigger (the path a click
## reaches), hip and ADS, and the magazine drops by one per shot.

const ROUNDS := 3


static func run(t: RangeTest) -> void:
	var r: Dictionary = RangeTestAttach._rig(t)
	var w: PlayerWeapons = r["w"]
	var ids: Array = WeaponDefs.ORDER.duplicate()
	for id in WeaponDefs.RACK_ROWS.reduce(func(a, row): return a + row, []):
		if not ids.has(id):
			ids.append(id)
	for id in ids:
		for ads in [false, true]:
			var g := _equip(r, id)
			w.trigger_ads = ads
			w.ads_amt = 1.0 if ads else 0.0
			var shots := 0
			for n in ROUNDS:
				var before := g.mag.count() + (1 if g.chamber != "" else 0)
				g.fire_cd = 0.0
				if g.needs_cycle:  # the bolt / pump / tube cycle the game runs on release
					g.release()
					g.update(10.0)
				g.busy_kind = ""
				g.busy_t = 0.0
				w.draw_t = 0.0
				w.trigger_down = false
				w._trigger()
				w.trigger_down = true
				w._trigger()
				if g.mag.count() + (1 if g.chamber != "" else 0) < before:
					shots += 1
				w.trigger_down = false
				w._trigger()
			t.check("fire: %s %s fires %d of %d through the player path" % [id, "ADS" if ads else "hip", shots, ROUNDS], shots == ROUNDS, "fired %d, chamber=%s mag=%d" % [shots, g.chamber, g.mag.count()])
	w.trigger_ads = false
	w.trigger_down = false


## Puts a fresh gun in its slot (pistols go to the holster) and draws it.
static func _equip(r: Dictionary, id: String) -> Gun:
	var w: PlayerWeapons = r["w"]
	var slot := "holster" if WeaponDefs.of(id)["class"] == "pistol" else "primary"
	for s in ["primary", "holster"]:
		var old = w.inv.equipped(s)
		if old != null:
			w.inv.remove(old)
	var it: Dictionary = w.inv.make(id)
	w.inv.place(it, slot)
	w.gun_item = {}
	w.sync()
	w.select_slot(slot)
	w.draw_t = 0.0
	return w.gun
