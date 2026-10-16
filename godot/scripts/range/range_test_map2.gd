class_name RangeTestMap2
## MAP-2 Skirmish layout checks: buildings keep alleys between them, no cover straddles a wall, every door is
## walkable from the spawn (a point just inside and outside each one), every loot crate and bot point is reachable,
## and the tower sees down the sniper street while the old-town plaza stays out of its sight. Door and reach checks
## cover the old town (WEST, x < OLD_TOWN_X), the part MAP-2 built: the barracks / warehouse navmesh has known
## pre-MAP-2 gaps (HANDOFF.md).

const GAP := 2.5        # m: narrowest alley between two buildings
const DOOR_IN := 1.2    # m: probe distance either side of a door
const TOWER_EYE := Vector3(-47, 7.6, -44)
const WEST := ["hotel", "garage", "storehouse", "pumphouse", "cottage", "clinic", "bunkhouse", "row_a", "workshop", "office"]
const OLD_TOWN_X := -12.0


static func _rect(a: Array) -> Rect2:
	return Rect2(a[0], a[1], a[2] - a[0], a[3] - a[1])


static func _cover_rect(c: Array) -> Rect2:
	return Rect2(float(c[1]) - float(c[3]) * 0.5, float(c[2]) - float(c[4]) * 0.5, float(c[3]), float(c[4]))


static func run(t: RangeTest, map: RID) -> void:
	var rects := {}
	for id in SkirmishData.BUILDINGS:
		rects[id] = _rect(SkirmishData.BUILDINGS[id]["rect"])
	rects["tower"] = _rect(SkirmishData.TOWER["rect"])
	var tight := []
	var ids := rects.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if (rects[ids[i]] as Rect2).grow(GAP * 0.5 - 0.01).intersects((rects[ids[j]] as Rect2).grow(GAP * 0.5 - 0.01)):
				tight.append("%s/%s" % [ids[i], ids[j]])
	t.check("map2: at least %.1f m between buildings" % GAP, tight.is_empty(), str(tight))
	var straddle := []
	for c in SkirmishData.COVER:
		var cr := _cover_rect(c)
		for id in SkirmishData.BUILDINGS:
			var r: Rect2 = rects[id]
			if cr.intersects(r.grow(0.4)) and not r.grow(-0.6).encloses(cr):
				straddle.append("%s@%s/%s" % [c[0], Vector2(c[1], c[2]), id])
	t.check("map2: no cover piece cuts through a building wall", straddle.is_empty(), str(straddle))
	var stuck := []
	for p in _door_probes():
		if not _reaches(map, SkirmishData.SPAWN, p, 0.8):
			stuck.append(str(Vector2(p.x, p.z)))
	t.check("map2: every old-town door walkable from the spawn (inside and outside)", stuck.is_empty(), str(stuck))
	var lost := []
	var pts: Array[Vector3] = []
	for l in SkirmishData.LOOT:
		pts.append(Vector3(l[0], 0, l[1]))
	for e in SkirmishData.ENEMIES:
		if e["kind"] != "marksman":
			pts.append(Vector3(e["at"][0], 0, e["at"][1]))
		for q in e["route"]:
			pts.append(Vector3(q[0], 0, q[1]))
	for p in pts:
		if p.x >= OLD_TOWN_X:
			continue
		if not _reaches(map, SkirmishData.SPAWN, p, 1.4):
			lost.append(str(Vector2(p.x, p.z)))
	t.check("map2: every old-town loot crate and bot start / route point is reachable", lost.is_empty(), str(lost))
	var space: PhysicsDirectSpaceState3D = t.get_viewport().world_3d.direct_space_state
	var seen := 0
	for z in [0.0, 10.0, 20.0, 30.0]:
		if BotPerception.los(space, TOWER_EYE, [Vector3(-49.0, 1.3, z)]):
			seen += 1
	t.check("map2: the tower sees down the sniper street (%d / 4)" % seen, seen >= 3)
	t.check("map2: the old-town plaza is hidden from the tower", not BotPerception.los(space, TOWER_EYE, [Vector3(-38, 1.3, -2), Vector3(-38, 1.6, -2)]))


## Points DOOR_IN inside and outside every ground-floor door.
static func _door_probes() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for id in WEST:
		var d: Dictionary = SkirmishData.BUILDINGS[id]
		var r := _rect(d["rect"])
		for side in d["open"]:
			for o in d["open"][side]:
				if o.size() > 2 and float(o[2]) > 0.0:
					continue   # window
				var m := (float(o[0]) + float(o[1])) * 0.5
				for s in [-1.0, 1.0]:   # -1 inside, +1 outside
					match side:
						"n": out.append(Vector3(m, 0, r.position.y - s * DOOR_IN))
						"s": out.append(Vector3(m, 0, r.end.y + s * DOOR_IN))
						"w": out.append(Vector3(r.position.x - s * DOOR_IN, 0, m))
						"e": out.append(Vector3(r.end.x + s * DOOR_IN, 0, m))
	return out


static func _reaches(map: RID, from: Vector3, to: Vector3, tol: float) -> bool:
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	if path.size() < 2:
		return false
	var end := path[path.size() - 1]
	return Vector2(end.x - to.x, end.z - to.z).length() < tol
