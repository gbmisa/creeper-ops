class_name SkirmishDistrictEast
## Track EXPAND phase 1: east district — motor pool + fuel depot. Two enterable hangars, three
## fuel tanks, a rail siding with wagons, mid-range cover. New file; gameplay colliders only.
extends RefCounted

const METAL := Color(0.35, 0.38, 0.34)
const RUST := Color(0.5, 0.28, 0.16)


static func build(layout: SkirmishLayout) -> void:
	_hangars(layout)
	_fuel_tanks(layout)
	_rail_siding(layout)
	_covers_patrol(layout)


static func _hangars(l: SkirmishLayout) -> void:
	for hz in [-15.0, 15.0]:
		var r := Rect2(66.0, hz - 7.0, 24.0, 14.0)
		# open ends east/west (10 m doors), corrugated walls
		SkirmishParts.building(l, r, 0.0, 5.0,
			{"e": [[hz - 5.0, hz + 5.0]], "w": [[hz - 5.0, hz + 5.0]], "n": [[72.0, 74.0, 2.0]], "s": [[72.0, 74.0, 2.0]]},
			"sheet_metal", METAL)
		SkirmishParts.slab(l, Rect2(r.position - Vector2(0.2, 0.2), r.size + Vector2(0.4, 0.4)), 5.2, 0.2, "sheet_metal", METAL.darkened(0.15))
		# workbench crates inside
		RangeLayout.box(l, "bench", Vector3(70, 0.5, hz + 4), Vector3(3.0, 1.0, 1.2), "wood_plank", 1.0, Color(0.45, 0.33, 0.2))
		RangeLayout.box(l, "bench", Vector3(86, 0.5, hz - 4), Vector3(3.0, 1.0, 1.2), "wood_plank", 1.0, Color(0.45, 0.33, 0.2))


static func _fuel_tanks(l: SkirmishLayout) -> void:
	for tz in [-25.0, -15.0, -5.0]:
		SkirmishParts.cylinder(l, Vector3(95, 3.0, tz), 3.0, 6.0, "sheet_metal", RUST)
		# hazard ring posts
		for a in [0.0, 1.57, 3.14, 4.71]:
			RangeLayout.box(l, "bollard", Vector3(95 + cos(a) * 4.6, 0.5, tz + sin(a) * 4.6),
				Vector3(0.35, 1.0, 0.35), "concrete", 0.35, Color(0.7, 0.6, 0.2))


static func _rail_siding(l: SkirmishLayout) -> void:
	var rail_c := Color(0.25, 0.25, 0.27)
	for rx in [101.0, 103.0]:
		RangeLayout.box(l, "rail", Vector3(rx, 0.15, 0), Vector3(0.25, 0.3, 70.0), "sheet_metal", 0.3, rail_c)
	for wz in [-20.0, 0.0, 20.0]:
		RangeLayout.box(l, "wagon", Vector3(102, 1.7, wz), Vector3(2.8, 3.0, 8.0), "sheet_metal", 3.0, Color(0.4, 0.22, 0.14))
		RangeLayout.box(l, "wagon_roof", Vector3(102, 3.3, wz), Vector3(3.0, 0.2, 8.2), "sheet_metal", 0.2, Color(0.3, 0.18, 0.12))


static func _covers_patrol(l: SkirmishLayout) -> void:
	for c in [[64, 2.2, 2.0, 1.2, 1.2], [92, -28, 1.4, 1.4, 1.4], [92, 28, 1.4, 1.4, 1.4], [70, 0, 3.0, 0.6, 1.1]]:
		var st: Array = SkirmishData.COVER_STYLE["crate" if c[4] < 1.5 else "barrier"]
		RangeLayout.box(l, "cover", Vector3(c[0], c[4] * 0.5, c[1]), Vector3(c[2], c[4], c[3]), st[0], minf(c[2], c[3]), st[1])
		l.covers.append(Vector3(c[0], 0, c[1]))
	for p in [Vector2(72, 0), Vector2(96, -12), Vector2(96, 12), Vector2(84, 30), Vector2(66, -30)]:
		l.patrol.append(Vector3(p.x, 0, p.y))
	# loot by the hangars
	l.loot_crates.append({"pos": Vector3(78, 0, -15), "loot": ["ammo"], "taken": false})
	l.loot_crates.append({"pos": Vector3(78, 0, 15), "loot": ["ammo", "meds"], "taken": false})


static func enemies() -> Array:
	return [
		{"kind": "rifleman", "at": [75, -15], "route": [[68, -15], [82, -15], [82, -5], [68, -5]], "ally": -1},
		{"kind": "rifleman", "at": [75, 15], "route": [[68, 15], [82, 15], [82, 25], [68, 25]], "ally": -1},
		{"kind": "shotgunner", "at": [96, -20], "route": [[91, -25], [101, -25], [101, -15], [91, -15]], "ally": -1},
	]
