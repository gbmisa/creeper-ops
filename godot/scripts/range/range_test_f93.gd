class_name RangeTestF93
## F93: the Skirmish spawn has standing-height cover right in front of it and on each early lane, and no cover
## piece sits on the spawn, the rack, a loot crate or a bot's start / patrol point.

const STAND := 1.7  # m: hides a standing player


static func _rect(c: Array, grow: float) -> Rect2:
	return Rect2(float(c[1]) - float(c[3]) * 0.5 - grow, float(c[2]) - float(c[4]) * 0.5 - grow, float(c[3]) + grow * 2.0, float(c[4]) + grow * 2.0)


static func run(t: RangeTest) -> void:
	var sp := SkirmishData.SPAWN
	var near := false
	var lanes := {"left": false, "centre": false, "right": false}
	for c in SkirmishData.COVER:
		if float(c[5]) < STAND:
			continue
		var cz := float(c[2])
		var cx := float(c[1])
		if cz < sp.z and Vector2(cx - sp.x, cz - sp.z).length() < 4.5:
			near = true
		if cz > 20.0 and cz < 47.0:
			lanes["left" if cx < -5.0 else ("right" if cx > 5.0 else "centre")] = true
	t.check("f93: standing cover within 4.5 m in front of the spawn", near)
	t.check("f93: standing cover on every early lane %s" % str(lanes), lanes.values().all(func(v): return v))
	var spots: Array[Vector2] = [Vector2(sp.x, sp.z), Vector2(SkirmishData.RACK_POS.x, SkirmishData.RACK_POS.z)]
	for l in SkirmishData.LOOT:
		spots.append(Vector2(l[0], l[1]))
	for e in SkirmishData.ENEMIES:
		spots.append(Vector2(e["at"][0], e["at"][1]))
		for r in e["route"]:
			spots.append(Vector2(r[0], r[1]))
	var bad := []
	for c in SkirmishData.COVER:
		for s in spots:
			if _rect(c, 0.6).has_point(s):
				bad.append("%s@%s on %s" % [c[0], Vector2(c[1], c[2]), s])
	t.check("f93: no cover on the spawn, rack, loot or a bot's start / route", bad.is_empty(), str(bad))
