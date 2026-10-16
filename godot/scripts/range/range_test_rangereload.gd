class_name RangeTestRangeReload
## F69: on the range map a reload makes a fresh full mag and ignores the inventory (10 reloads per action kind, after
## firing part of the mag); no stale mag stays in Gun.spares. Skirmish (infinite off) keeps using the inventory.


static func _partly_fired(g: Gun, left: int) -> void:
	while g.mag.count() > left:
		g.mag.pop()
	g.needs_cycle = false
	g.fire_cd = 0.0


static func run(t: RangeTest) -> void:
	for id in ["ak47", "garand", "shotgun", "pkm", "revolver"]:
		var inv := Inventory.new()
		var gi := inv.make(id)
		var g: Gun = gi["gun"]
		g.spares.clear()
		var rl := InvReload.new(inv)
		rl.infinite = true
		var before := JSON.stringify(inv.to_dict())
		var ok := true
		var why := ""
		for k in 10:
			var tube: bool = g.def["action"] == "tube"
			var cap := int(g.stat("mag"))
			_partly_fired(g, 0 if g.def["action"] == "enbloc" else 1 + k % 3)
			if g.def["action"] == "enbloc":
				g.chamber = ""
			var presses := cap - g.mag.count() if tube else 1
			for p in presses:
				if rl.begin(gi, k % 2 == 1) != "ok":
					ok = false
					why = "begin %d" % k
					break
				if not g.spares.is_empty() and g.spares[0].count() > cap:
					ok = false
				g.update(10.0)
				rl.finish(gi)
			var total := g.mag.count() + (1 if g.chamber != "" and g.def["action"] == "detachable" else 0)
			if not ((total == cap or (g.def["action"] == "detachable" and total == cap + 1 and g.mag.count() >= cap - 1)) and g.spares.is_empty() and not gi.has("staged")):
				ok = false
				why = "round %d total %d/%d spares %d" % [k, total, cap, g.spares.size()]
			if not ok:
				break
		t.check("range reload: %s (%s) full 10x, no stale mag" % [id, g.def["action"]], ok, why)
		t.check("range reload: %s leaves the inventory untouched" % id, JSON.stringify(inv.to_dict()) == before)
