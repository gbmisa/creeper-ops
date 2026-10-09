class_name SmokeBurrow
## Burrower telegraph checks: the underground dust trail is visible (smoke puffs
## while burrowed), the burrower is unhittable while down, surfaces for ~1.5 s
## next to a weapon, detonates for 60 damage in a 1.5-cell splash, and re-burrows
## if alive. Called from SmokeTest.run and --smoke=burrow.


static func run(g) -> void:
	_trail(g)
	_unhittable_down(g)
	_surface_window(g)
	_detonation(g)


static func _clear(nests: SporeNests) -> void:
	for x in nests.raiders.list.duplicate():
		nests.raiders.kill(x)


static func _spawn_burrower(nests: SporeNests) -> Dictionary:
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	nests.raiders.spawn(nest, RaiderDefs.named("Burrower"), false)
	var r: Dictionary = nests.raiders.list.back()
	r.guard = false
	return r


static func _free(sm: StructureManager, grid: Grid, x0: int, z0: int) -> Vector2i:
	for z in range(z0, z0 + 20):
		for x in range(x0, x0 + 20):
			if grid.in_bounds(x, z) and sm.structure_at(x, z) == null:
				return Vector2i(x, z)
	return Vector2i(x0, z0)


static func _smoke_count(g) -> int:
	var n := 0
	for it in g.surface.effects._items:
		if it.kind == "smoke":
			n += 1
	return n


static func _trail(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	_clear(nests)
	var spot := _free(sm, grid, 30, 30)
	var cannon: Structure = sm.place("cannon", spot.x, spot.y, true)
	var r := _spawn_burrower(nests)
	var start: Vector3 = grid.cell_ground(spot.x, spot.y) + Vector3(30.0, 0, 0)
	start.y = grid.smooth_y(start.x, start.z)
	r.node.position = start
	var row := cannon.prey.duplicate() as Dictionary
	row["weapon"] = true
	var prey := [row]
	var before := _smoke_count(g)
	for i in 20:
		RaiderBurrow.step(nests.raiders, r, 0.1, prey)
	var after := _smoke_count(g)
	SmokeTest._check("burrower leaves a smoke trail", after > before,
		"(smoke items %d -> %d)" % [before, after])
	SmokeTest._check("burrower moves toward the weapon",
		(r.node.position as Vector3).distance_to(cannon.node.position) < 30.0, "")
	SmokeTest._check("burrower still underground", str(r.get("burrow")) == "down"
		and not (r.node as Node3D).visible, "")
	nests.raiders.kill(r)
	sm.remove(cannon)


static func _unhittable_down(g) -> void:
	var nests: SporeNests = g.hazards.nests
	_clear(nests)
	var r := _spawn_burrower(nests)
	SmokeTest._check("burrowed burrower ignores hits",
		RaiderBurrow.filter(nests.raiders, r, 10.0) == -1.0, "")
	nests.raiders.kill(r)


static func _surface_window(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	_clear(nests)
	var spot := _free(sm, grid, 34, 34)
	var cannon: Structure = sm.place("cannon", spot.x, spot.y, true)
	var r := _spawn_burrower(nests)
	var near: Vector3 = cannon.node.position + Vector3(1.0, 0, 0)
	near.y = grid.smooth_y(near.x, near.z)
	r.node.position = near
	var row := cannon.prey.duplicate() as Dictionary
	row["weapon"] = true
	Sfx.listener = near  # so the distance gate passes headless
	RaiderBurrow.step(nests.raiders, r, 0.1, [row])
	SmokeTest._check("burrower surfaces next to weapon",
		str(r.get("burrow")) == "up" and (r.node as Node3D).visible, "")
	SmokeTest._check("surfaced burrower is hittable",
		RaiderBurrow.filter(nests.raiders, r, 10.0) == 10.0, "")
	SmokeTest._check("surfacing plays the warning rumble",
		Sfx._last.has("burrower_rumble"), "")
	nests.raiders.kill(r)
	sm.remove(cannon)


static func _detonation(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.level.grid
	var nests: SporeNests = g.hazards.nests
	_clear(nests)
	var spot := _free(sm, grid, 38, 38)
	var cannon: Structure = sm.place("cannon", spot.x, spot.y, true)
	var r := _spawn_burrower(nests)
	var near: Vector3 = cannon.node.position + Vector3(1.0, 0, 0)
	near.y = grid.smooth_y(near.x, near.z)
	r.node.position = near
	var dealt := [0.0]
	var prey := [{ "node": cannon.node, "radius": 1.0,
		"alive": func(): return true,
		"hit": func(d): dealt[0] += d,
		"weapon": true }]
	RaiderBurrow.step(nests.raiders, r, 0.1, prey)  # surfaces
	Sfx.listener = near
	for i in 40:  # surface window is 1.5 s
		RaiderBurrow.step(nests.raiders, r, 0.1, prey)
		if str(r.get("burrow")) == "down":
			break
	SmokeTest._check("detonation deals 60 damage", is_equal_approx(dealt[0], 60.0),
		"(dealt %.1f)" % dealt[0])
	SmokeTest._check("detonation plays the unique blast",
		Sfx._last.has("burrower_blast"), "")
	SmokeTest._check("burrower re-burrows if alive",
		r.alive and str(r.get("burrow")) == "down" and not (r.node as Node3D).visible, "")
	nests.raiders.kill(r)
	sm.remove(cannon)
