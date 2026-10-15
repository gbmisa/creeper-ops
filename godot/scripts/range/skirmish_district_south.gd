class_name SkirmishDistrictSouth
## Track EXPAND phase 1: south district — checkpoint town. The compound's south gate becomes the
## town entrance; a short street of 2-storey houses (ramp access like the hotel), a shop, a church
## and a water tower. Tight CQB alleys. New file; gameplay colliders only.
extends RefCounted


static func build(layout: SkirmishLayout) -> void:
	_houses(layout)
	_shop(layout)
	_church(layout)
	_water_tower(layout)
	_street_props(layout)
	_covers_patrol(layout)


## Two-storey house with an exterior ramp to the upper floor (hotel pattern).
static func _house(l: SkirmishLayout, x0: float, z0: float) -> void:
	var r := Rect2(x0, z0, 8.0, 7.0)
	var h := 3.0
	var col: Color = SkirmishData.BRICK
	SkirmishParts.building(l, r, 0.0, h,
		{"s": [[x0 + 3.0, x0 + 5.0]], "n": [[x0 + 2.0, x0 + 4.0, 1.0], [x0 + 5.0, x0 + 7.0, 1.0]], "e": [[z0 + 2.0, z0 + 4.0, 1.0]]},
		"brick", col)
	# upper floor: slab with a ramp lane along the west wall, walls with windows, roof slab
	var lane_x := r.position.x + 0.2 + 2.0
	var top_z := r.position.y + 4.0
	SkirmishParts.slab(l, Rect2(r.position.x, r.position.y, r.size.x, top_z - r.position.y), h, 0.2, "concrete", Color(0.4, 0.4, 0.38))
	SkirmishParts.slab(l, Rect2(lane_x, top_z, r.end.x - lane_x, r.end.y - top_z), h, 0.2, "concrete", Color(0.4, 0.4, 0.38))
	SkirmishParts.ramp(l, Vector3(lane_x - 1.0, 0.0, r.end.y - 1.5), Vector3(lane_x - 1.0, h, top_z), 2.0, Color(0.45, 0.45, 0.42))
	SkirmishParts.building(l, r, h, h,
		{"s": [[x0 + 3.0, x0 + 5.0, 1.0]], "n": [[x0 + 3.0, x0 + 5.0, 1.0]], "w": [[z0 + 2.0, z0 + 4.0, 1.0]]},
		"brick", col)
	SkirmishParts.slab(l, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), h * 2.0 + 0.2, 0.2, "concrete", Color(0.3, 0.3, 0.32))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(r.get_center().x, h - 0.4, r.get_center().y)
	lamp.omni_range = 9.0
	lamp.light_energy = 1.0
	lamp.light_color = Color(1.0, 0.85, 0.65)
	l.add_child(lamp)


static func _houses(l: SkirmishLayout) -> void:
	_house(l, -20.0, 68.0)
	_house(l, 12.0, 68.0)
	_house(l, -20.0, 82.0)
	_house(l, 12.0, 82.0)


static func _shop(l: SkirmishLayout) -> void:
	var r := Rect2(24.0, 70.0, 10.0, 8.0)
	SkirmishParts.building(l, r, 0.0, 3.2,
		{"w": [[71.0, 77.0, 0.6]], "s": [[27.0, 29.0]], "n": [[30.0, 32.0, 1.2]]},
		"plywood", SkirmishData.PLASTER)
	SkirmishParts.slab(l, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), 3.4, 0.2, "concrete", Color(0.3, 0.3, 0.32))
	# awning posts + counter inside
	for px in [24.6, 33.4]:
		RangeLayout.box(l, "awning", Vector3(px, 1.4, 69.2), Vector3(0.25, 2.8, 0.25), "wood_plank", 0.25, SkirmishData.WOOD)
	RangeLayout.box(l, "counter", Vector3(29, 0.55, 74), Vector3(4.0, 1.1, 0.8), "wood_plank", 1.0, Color(0.45, 0.33, 0.2))


static func _church(l: SkirmishLayout) -> void:
	var r := Rect2(-32.0, 88.0, 10.0, 10.0)
	SkirmishParts.building(l, r, 0.0, 6.0,
		{"s": [[-28.0, -26.0]], "n": [[-28.0, -26.0, 2.0]], "e": [[91.0, 93.0, 2.0]], "w": [[91.0, 93.0, 2.0]]},
		"brick", SkirmishData.BRICK)
	SkirmishParts.slab(l, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), 6.2, 0.2, "concrete", Color(0.3, 0.3, 0.32))
	# steeple
	RangeLayout.box(l, "steeple", Vector3(-27, 8.0, 93), Vector3(2.5, 4.0, 2.5), "brick", 2.5, SkirmishData.BRICK.darkened(0.1))
	RangeLayout.box(l, "steeple_top", Vector3(-27, 10.5, 93), Vector3(1.2, 1.0, 1.2), "concrete", 1.0, Color(0.4, 0.4, 0.38))


static func _water_tower(l: SkirmishLayout) -> void:
	var cx := 28.0
	var cz := 94.0
	for sx in [-1.5, 1.5]:
		for sz in [-1.5, 1.5]:
			RangeLayout.box(l, "wt_leg", Vector3(cx + sx, 4.0, cz + sz), Vector3(0.4, 8.0, 0.4), "wood_plank", 0.4, SkirmishData.WOOD)
	SkirmishParts.cylinder(l, Vector3(cx, 9.5, cz), 2.5, 3.0, "sheet_metal", Color(0.45, 0.3, 0.2))
	RangeLayout.box(l, "wt_roof", Vector3(cx, 11.2, cz), Vector3(5.6, 0.3, 5.6), "sheet_metal", 0.3, Color(0.35, 0.22, 0.15))


static func _street_props(l: SkirmishLayout) -> void:
	# wrecked cars as street cover, lamps
	for c in [[-6, 72], [7, 79], [-7, 86], [6, 93]]:
		RangeLayout.box(l, "car", Vector3(c[0], 0.75, c[1]), Vector3(1.9, 1.5, 4.4), "sheet_metal", 1.5, Color(0.35, 0.2, 0.16))
		l.covers.append(Vector3(c[0] + 1.5, 0, c[1]))
		l.covers.append(Vector3(c[0] - 1.5, 0, c[1]))
	for lx in [-4.0, 4.0]:
		for lz in [66.0, 100.0]:
			RangeLayout.box(l, "lamp", Vector3(lx, 2.5, lz), Vector3(0.25, 5.0, 0.25), "sheet_metal", 0.25, Color(0.2, 0.2, 0.22))


static func _covers_patrol(l: SkirmishLayout) -> void:
	for p in [Vector2(0, 68), Vector2(-14, 76), Vector2(14, 84), Vector2(0, 92), Vector2(-27, 93), Vector2(28, 88)]:
		l.patrol.append(Vector3(p.x, 0, p.y))
	l.loot_crates.append({"pos": Vector3(-24, 0, 93), "loot": ["meds"], "taken": false})
	l.loot_crates.append({"pos": Vector3(29, 0, 74), "loot": ["ammo"], "taken": false})


static func enemies() -> Array:
	return [
		{"kind": "rifleman", "at": [-14, 73], "route": [[-18, 70], [-10, 70], [-10, 78], [-18, 78]], "ally": -1},
		{"kind": "rifleman", "at": [16, 85], "route": [[12, 82], [20, 82], [20, 90], [12, 90]], "ally": -1},
		{"kind": "rifleman", "at": [0, 95], "route": [[-6, 93], [6, 93], [6, 98], [-6, 98]], "ally": -1},
		{"kind": "pistol", "at": [-24, 88], "route": [[-28, 85], [-20, 85], [-20, 91], [-28, 91]], "ally": -1},
	]
