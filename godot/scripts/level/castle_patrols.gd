class_name CastlePatrols
## Garrison life on hostile concentric castles (Stage 21b P6): two raiders walk the
## outer wall walk between towers, and a Warden stands in the keep hall beside the
## crown. Both reuse the normal raider combat AI (the guard branch of Raiders._think):
## the patrol route is just a waypoint list on the raider dict, read by waypoint().
## Live state lives in the views dict (v.patrol = { nest, wall: [r, r], warden: r,
## route: [Vector2i] }): the castle dict itself stays plain data (state()/load_state
## round-trip it). Patrols and the warden are extra on top of the bailey garrison
## (CASTLE_GARRISON is unchanged); they respawn on the garrison timer and are gone
## once the castle is held.


## First hostile tick: build the route and spawn the guards. Cheap afterwards.
static func ensure(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	if v.has("patrol"):
		return
	var grid: Grid = s.world.grid
	var route := wall_route(grid, lay)
	if route.is_empty():
		return
	var raiders: Raiders = s.nests.raiders
	var nest := { "name": "wall", "pos": grid.cell_ground(route[route.size() / 2].x, route[route.size() / 2].y), "count": 0 }
	var wall: Array = []
	for k in 2:
		raiders.spawn(nest, s.nests.pick_tier(), true)
		var r: Dictionary = raiders.list.back()
		var cell: Vector2i = route[route.size() * (1 + 2 * k) / 4 % route.size()]
		r.node.position = grid.cell_ground(cell.x, cell.y)
		r["wall_patrol"] = { "cells": route, "i": (route.find(cell) + 1) % route.size() }
		wall.append(r)
	v["patrol"] = { "nest": nest, "wall": wall, "warden": _spawn_warden(s, lay, v), "route": route }


## The garrison timer fired: replace dead wall patrols and the hall guard.
static func on_garrison_tick(s: Strongholds, c: Dictionary, lay: Dictionary, v: Dictionary) -> void:
	if not v.has("patrol"):
		ensure(s, c, lay, v)
		return
	var p: Dictionary = v.patrol
	var raiders: Raiders = s.nests.raiders
	var grid: Grid = s.world.grid
	var wall: Array = []
	for r in p.wall:
		if r.alive:
			wall.append(r)
	while wall.size() < 2:
		raiders.spawn(p.nest, s.nests.pick_tier(), true)
		var r: Dictionary = raiders.list.back()
		var route: Array = p.route
		var cell: Vector2i = route[randi() % route.size()]
		r.node.position = grid.cell_ground(cell.x, cell.y)
		r["wall_patrol"] = { "cells": route, "i": (route.find(cell) + 1) % route.size() }
		wall.append(r)
	p.wall = wall
	if not (p.warden as Dictionary).alive:
		p.warden = _spawn_warden(s, lay, v)


## Capture: the patrols and the hall guard are gone.
static func clear(s: Strongholds, v: Dictionary) -> void:
	if not v.has("patrol"):
		return
	var raiders: Raiders = s.nests.raiders
	for r in v.patrol.wall:
		if r.alive:
			raiders.kill(r)
	if (v.patrol.warden as Dictionary).alive:
		raiders.kill(v.patrol.warden)
	v.erase("patrol")


## Retake: the old patrols stand down to ordinary garrison; fresh ones spawn on the wall.
static func release(v: Dictionary) -> void:
	if not v.has("patrol"):
		return
	for r in v.patrol.wall:
		if r.alive:
			r.erase("wall_patrol")
	if (v.patrol.warden as Dictionary).alive:
		(v.patrol.warden as Dictionary).erase("hall_guard")
	v.erase("patrol")


## The patrol raider's current goal: the next wall-walk cell, advancing when close.
static func waypoint(r: Dictionary) -> Vector2:
	var wp: Dictionary = r.wall_patrol
	var cells: Array = wp.cells
	var p: Vector3 = r.node.position
	var cell: Vector2i = cells[int(wp.i)]
	var dx := (cell.x + 0.5) * Config.CELL - p.x
	var dz := (cell.y + 0.5) * Config.CELL - p.z
	if dx * dx + dz * dz < 4.0:  # within 2 m: step to the next cell
		wp.i = (int(wp.i) + 1) % cells.size()
		cell = cells[int(wp.i)]
	return Vector2((cell.x + 0.5) * Config.CELL, (cell.y + 0.5) * Config.CELL)


## The patrol route: the longest contiguous walk-height stretch of the outer wall walk
## (one row of the 2-thick wall, same side, breached cells skipped), with the nearest
## walk-level tower door hung on each end ("lay.segments of ring outer + tower doors").
static func wall_route(grid: Grid, lay: Dictionary) -> Array[Vector2i]:
	var walk := int(lay.get("wall_top", 0))
	var rect: Rect2i = lay.rect
	var best: Array[Vector2i] = []
	for side in ["n", "s", "w", "e"]:
		var ts: Array = []  # [t, cell] for walk-height cells of the k=0 row
		for sg in lay.segments:
			if sg.get("ring", "outer") != "outer" or sg.side != side:
				continue
			for cell in sg.cells:
				var c: Vector2i = cell
				if grid.height_at(c.x, c.y) != walk:
					continue
				var tk := _tk(rect, side, c)
				if tk.y == 0:
					ts.append([tk.x, c])
		ts.sort_custom(func(a, b): return a[0] < b[0])
		var run: Array[Vector2i] = []
		var cur: Array[Vector2i] = []
		var pt := -99
		for e in ts:
			if e[0] != pt + 1 and not cur.is_empty():
				if cur.size() > run.size():
					run = cur.duplicate()
				cur = []
			cur.append(e[1])
			pt = e[0]
		if cur.size() > run.size():
			run = cur
		if run.size() > best.size():
			best = run
	if best.is_empty():
		return []
	var doors: Array[Vector2i] = []
	for t in lay.towers:
		for d in t.get("doors", []):
			var dc: Vector2i = d
			if grid.height_at(dc.x, dc.y) == walk:
				doors.append(dc)
	var route: Array[Vector2i] = []
	var d0 := _nearest(doors, best[0], 5)
	if d0 != Vector2i(-1, -1):
		route.append(d0)
	for c in best:
		if not route.has(c):
			route.append(c)
	var d1 := _nearest(doors, best[best.size() - 1], 5)
	if d1 != Vector2i(-1, -1) and not route.has(d1):
		route.append(d1)
	return route


## (t, k) of a wall cell on `side` (inverse of CastleShape.at).
static func _tk(rect: Rect2i, side: String, c: Vector2i) -> Vector2i:
	match side:
		"n": return Vector2i(c.x - rect.position.x, c.y - rect.position.y)
		"s": return Vector2i(c.x - rect.position.x, rect.end.y - 1 - c.y)
		"w": return Vector2i(c.y - rect.position.y, c.x - rect.position.x)
	return Vector2i(c.y - rect.position.y, rect.end.x - 1 - c.x)


static func _nearest(doors: Array[Vector2i], to: Vector2i, max_d: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := max_d * max_d + 1
	for d in doors:
		var q := (d - to).length_squared()
		if q < bd:
			bd = q
			best = d
	return best


## One Warden (the existing roster row) in the keep hall beside the crown.
static func _spawn_warden(s: Strongholds, lay: Dictionary, v: Dictionary) -> Dictionary:
	var raiders: Raiders = s.nests.raiders
	var grid: Grid = s.world.grid
	var cell := _hall_cell(grid, lay, v)
	var nest := { "name": "hall", "pos": grid.cell_ground(cell.x, cell.y), "count": 0 }
	raiders.spawn(nest, RaiderDefs.named("Warden"), true)
	var r: Dictionary = raiders.list.back()
	r.node.position = nest.pos
	r["hall_guard"] = true
	return r


## A keep-hall cell beside the crown: 1.5-3.5 cells from it (never inside the dais).
static func _hall_cell(grid: Grid, lay: Dictionary, v: Dictionary) -> Vector2i:
	var cc := Vector2i.ZERO
	var crown := v.get("crown") as Node3D
	if crown:
		cc = grid.world_to_cell(crown.position.x, crown.position.z)
	var cells: Array = lay.zones.keep.cells
	for cell in cells:
		var d := Vector2(cell - cc).length()
		if d >= 1.5 and d <= 3.5:
			return cell
	var best: Vector2i = cells[0]
	var bd := 1e9
	for cell in cells:
		var d := Vector2(cell - cc).length()
		if d < bd:
			bd = d
			best = cell
	return best
