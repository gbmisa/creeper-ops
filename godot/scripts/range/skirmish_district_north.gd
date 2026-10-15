class_name SkirmishDistrictNorth
## Track EXPAND phase 1: north district — radar hill. Terraced elevation (3 levels), switchback
## ramps, bunker entrances at the base, a second (bigger) radar array on top, marksman posts
## with long sightlines south. New file; gameplay colliders only (dressing is Opus phase 2).
extends RefCounted

const DIRT := Color(0.32, 0.30, 0.18)
const CONCRETE_C := Color(0.5, 0.5, 0.47)


static func build(layout: SkirmishLayout) -> void:
	_hill(layout)
	_ramps(layout)
	_radar_array(layout)
	_bunkers(layout)
	_marksman_posts(layout)
	_covers_patrol(layout)


## Three stacked earth terraces: T1 top 1.5 m, T2 top 3.0 m, T3 top 4.5 m.
static func _hill(l: SkirmishLayout) -> void:
	RangeLayout.box(l, "hill1", Vector3(0, 0.75, -85), Vector3(40, 1.5, 40), "dirt_berm", 1.5, DIRT)
	RangeLayout.box(l, "hill2", Vector3(0, 1.5, -85), Vector3(28, 3.0, 28), "dirt_berm", 3.0, DIRT.darkened(0.05))
	RangeLayout.box(l, "hill3", Vector3(0, 2.25, -85), Vector3(16, 4.5, 16), "dirt_berm", 4.5, DIRT.darkened(0.1))


## Switchback road up the hill, climbing the south face of each terrace from outside
## (ramps must not cut through the solid terrace boxes): west up T1, east up T2, west up T3.
static func _ramps(l: SkirmishLayout) -> void:
	var col := Color(0.4, 0.36, 0.24)
	SkirmishParts.ramp(l, Vector3(-8, 0.0, -60), Vector3(-8, 1.5, -65), 3.0, col)
	SkirmishParts.ramp(l, Vector3(8, 1.5, -66), Vector3(8, 3.0, -71), 3.0, col)
	SkirmishParts.ramp(l, Vector3(-8, 3.0, -72), Vector3(-8, 4.5, -77), 3.0, col)


## Second, bigger radar array on the hilltop: pedestal, panel array, dome.
static func _radar_array(l: SkirmishLayout) -> void:
	var metal := Color(0.55, 0.58, 0.6)
	RangeLayout.box(l, "radar_base", Vector3(-3, 5.5, -88), Vector3(3.0, 2.0, 3.0), "concrete", 2.0, CONCRETE_C)
	for i in 3:
		var px := -5.2 + i * 2.2
		RangeLayout.box(l, "radar_panel", Vector3(px, 8.0, -88), Vector3(2.0, 3.0, 0.25), "sheet_metal", 0.25, metal)
	RangeLayout.box(l, "radar_beam", Vector3(-3, 6.6, -88), Vector3(7.0, 0.3, 0.5), "sheet_metal", 0.3, metal.darkened(0.2))
	# radome on a short mast beside the array
	RangeLayout.box(l, "dome_mast", Vector3(4, 5.5, -88), Vector3(0.8, 2.0, 0.8), "sheet_metal", 0.8, metal.darkened(0.3))
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	dome.mesh = sm
	dome.material_override = RangeLayout.colour(Color(0.85, 0.86, 0.88))
	dome.position = Vector3(4, 7.4, -88)
	l.add_child(dome)
	var sb := StaticBody3D.new()
	sb.collision_layer = TacticalConfig.LAYER_WORLD
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.6
	cs.shape = shape
	sb.add_child(cs)
	sb.position = Vector3(4, 7.4, -88)
	l.add_child(sb)


## Two bunker entrances flanking the hill base, doors facing the compound.
static func _bunkers(l: SkirmishLayout) -> void:
	for bx in [-25.0, 25.0]:
		var r := Rect2(bx - 3.0, -72.0, 6.0, 5.0)
		SkirmishParts.building(l, r, 0.0, 2.5, {"s": [[bx - 1.0, bx + 1.0]]}, "concrete", CONCRETE_C)
		SkirmishParts.slab(l, Rect2(r.position - Vector2(0.15, 0.15), r.size + Vector2(0.3, 0.3)), 2.7, 0.2, "concrete", CONCRETE_C.darkened(0.1))


## Sandbag U-rings: one on T3 by the array, one on T2 overlooking the south approach.
static func _marksman_posts(l: SkirmishLayout) -> void:
	var bag := Color(0.45, 0.4, 0.28)
	for cx in [3.9, 6.1]:
		RangeLayout.box(l, "sandbag", Vector3(cx, 5.05, -80), Vector3(0.5, 1.1, 3.0), "concrete", 0.5, bag)
	RangeLayout.box(l, "sandbag", Vector3(5.0, 5.05, -78.6), Vector3(2.7, 1.1, 0.5), "concrete", 0.5, bag)
	for cx in [-11.1, -8.9]:
		RangeLayout.box(l, "sandbag", Vector3(cx, 3.55, -75), Vector3(0.5, 1.1, 3.0), "concrete", 0.5, bag)
	RangeLayout.box(l, "sandbag", Vector3(-10.0, 3.55, -73.6), Vector3(2.7, 1.1, 0.5), "concrete", 0.5, bag)


static func _covers_patrol(l: SkirmishLayout) -> void:
	for c in [[-8, -62], [8, -62], [-20, -70], [20, -70], [-24, -90], [24, -90]]:
		l.covers.append(Vector3(c[0], 0, c[1]))
	for p in [Vector2(0, -64), Vector2(-22, -72), Vector2(22, -80), Vector2(0, -62)]:
		l.patrol.append(Vector3(p.x, 0, p.y))


## New roster rows for this district (roster rows in SkirmishData.ENEMIES are untouched).
static func enemies() -> Array:
	return [
		{"kind": "marksman", "at": [5, -80], "y": 4.6, "route": [], "ally": -1, "spot": 2},
		{"kind": "rifleman", "at": [-25, -66], "route": [[-25, -66], [-22, -78], [22, -78], [25, -66]], "ally": -1},
	]
