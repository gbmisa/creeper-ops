class_name SkirmishDistrictWest
## Track EXPAND phase 1: west district — birch forest + river. Birch trunks (colliders), rocks, a
## shallow river with a road bridge and a footbridge, a ruined pump house. Flanking routes.
## New file; gameplay colliders only (visual foliage is Opus phase 2).
extends RefCounted

const WATER_C := Color(0.15, 0.35, 0.5, 0.75)


static func build(layout: SkirmishLayout) -> void:
	_river(layout)
	_bridges(layout)
	_forest(layout)
	_rocks(layout)
	_pump_house(layout)
	_covers_patrol(layout)


## Shallow river: visual water plane (no collider, bots wade), low banks each side.
static func _river(l: SkirmishLayout) -> void:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 200.0)
	water.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WATER_C
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.25
	mat.metallic = 0.35
	water.material_override = mat
	water.position = Vector3(-85, 0.06, 0)
	l.add_child(water)
	for bx in [-89.6, -80.4]:
		RangeLayout.box(l, "bank", Vector3(bx, 0.3, 0), Vector3(1.2, 0.6, 200.0), "dirt_berm", 0.6, Color(0.3, 0.28, 0.18))


## Road bridge (z=0) and footbridge (z=-40): slabs with approach ramps.
static func _bridges(l: SkirmishLayout) -> void:
	SkirmishParts.slab(l, Rect2(-93.0, -4.0, 16.0, 8.0), 0.7, 0.4, "wood_plank", Color(0.4, 0.3, 0.2))
	SkirmishParts.ramp(l, Vector3(-97.0, 0.0, 0), Vector3(-93.0, 0.7, 0), 8.0, Color(0.4, 0.36, 0.24))
	SkirmishParts.ramp(l, Vector3(-73.0, 0.0, 0), Vector3(-77.0, 0.7, 0), 8.0, Color(0.4, 0.36, 0.24))
	SkirmishParts.slab(l, Rect2(-86.5, -41.5, 3.0, 3.0), 0.7, 0.3, "wood_plank", Color(0.42, 0.32, 0.22))
	for sx in [-1.0, 1.0]:
		SkirmishParts.ramp(l, Vector3(-85 + sx * 5.0, 0.0, -40), Vector3(-85 + sx * 1.5, 0.7, -40), 3.0, Color(0.4, 0.36, 0.24))


## Birch trunks as thin colliders (deterministic scatter; avoids river, bridges, pump house, extract).
static func _forest(l: SkirmishLayout) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var placed := 0
	var guard := 0
	var trunk_c := Color(0.82, 0.8, 0.74)
	while placed < 26 and guard < 400:
		guard += 1
		var x := rng.randf_range(-106.0, -64.0)
		var z := rng.randf_range(-48.0, 48.0)
		if absf(x + 85.0) < 7.0:
			continue  # river
		if absf(z) < 8.0 and absf(x + 85.0) < 12.0:
			continue  # road bridge
		if absf(z + 40.0) < 6.0 and absf(x + 85.0) < 9.0:
			continue  # footbridge
		if Vector2(x - -95.0, z - 30.0).length() < 9.0:
			continue  # pump house
		if Vector2(x - -95.0, z - -20.0).length() < 7.0:
			continue  # extract
		var h := rng.randf_range(2.6, 3.4)
		RangeLayout.box(l, "birch", Vector3(x, h * 0.5, z), Vector3(0.35, h, 0.35), "wood_plank", 0.35, trunk_c)
		placed += 1


static func _rocks(l: SkirmishLayout) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var rock_c := Color(0.42, 0.42, 0.4)
	for i in 10:
		var x := rng.randf_range(-105.0, -65.0)
		var z := rng.randf_range(-45.0, 45.0)
		if absf(x + 85.0) < 7.0:
			continue
		var s := rng.randf_range(0.8, 1.8)
		RangeLayout.box(l, "rock", Vector3(x, s * 0.4, z), Vector3(s, s * 0.8, s * rng.randf_range(0.7, 1.2)), "concrete", s, rock_c)
		l.covers.append(Vector3(x + s, 0, z))


## Ruined pump house: three walls, no roof.
static func _pump_house(l: SkirmishLayout) -> void:
	var r := Rect2(-99.0, 27.0, 6.0, 6.0)
	var col := Color(0.48, 0.47, 0.44)
	SkirmishParts.wall(l, "x", r.position.y, r.position.x, r.end.x, 0.0, 2.5, 0.25, [], "concrete", col)
	SkirmishParts.wall(l, "z", r.position.x, r.position.y, r.end.y, 0.0, 2.5, 0.25, [[29.0, 31.0]], "concrete", col)
	SkirmishParts.wall(l, "z", r.end.x, r.position.y, r.end.y, 0.0, 1.2, 0.25, [], "concrete", col)
	# pump block inside
	RangeLayout.box(l, "pump", Vector3(-96, 0.6, 30), Vector3(2.0, 1.2, 1.4), "sheet_metal", 1.2, Color(0.35, 0.25, 0.15))
	l.covers.append(Vector3(-96, 0, 28.0))
	l.covers.append(Vector3(-96, 0, 32.0))


static func _covers_patrol(l: SkirmishLayout) -> void:
	for p in [Vector2(-75, 10), Vector2(-95, -30), Vector2(-70, -35), Vector2(-100, 15), Vector2(-80, 40)]:
		l.patrol.append(Vector3(p.x, 0, p.y))
	l.loot_crates.append({"pos": Vector3(-96, 0, 30), "loot": ["ammo"], "taken": false})


static func enemies() -> Array:
	return [
		{"kind": "rifleman", "at": [-75, 10], "route": [[-75, 0], [-75, 20], [-95, 20], [-95, 0]], "ally": -1},
		{"kind": "rifleman", "at": [-95, -30], "route": [[-100, -35], [-90, -35], [-90, -25], [-100, -25]], "ally": -1},
		{"kind": "shotgunner", "at": [-95, 30], "route": [[-98, 25], [-92, 25], [-92, 35], [-98, 35]], "ally": -1},
	]
