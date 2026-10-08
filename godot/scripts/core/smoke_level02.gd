class_name SmokeLevel02
## Stage 16 checks: Level 2 builds (160 x 160, five castles), every castle is reachable on foot,
## towers are climbable, Sentinels fire fairly (range, line of sight, dodgeable bolts), a
## captured castle loses its garrison, and Level 1 castles gained no towers.
## Builds its own World from the Level 2 data, so it runs inside the Level 1 smoke game.


static func run(g) -> void:
	_level1_unchanged()
	var lvl := Levels.build(2)
	var grid: Grid = lvl.grid
	SmokeTest._check("L2: 160x160 with 5 castles", grid.w == 160 and grid.h == 160 and lvl.castles.size() == 5)
	SmokeTest._check("L2: 4-5 emitters, 2 delayed", lvl.emitters.size() >= 4 and lvl.emitters.filter(func(e): return e.get("start", 0.0) > 0.0).size() == 2)
	_reach(lvl)
	_towers(lvl)
	var w := World.new()
	w.setup("L2", grid, false)
	g.add_child(w)
	var castles := Strongholds.new(w, lvl.castles, SporeNests.new(w, lvl.nests, lvl.raid_schedule))
	var guards := CastleGuards.new(w, castles, lvl.castles)
	var want := 0
	for c in lvl.castles:
		want += c.guards
	SmokeTest._check("guards: all posted at t=0", guards.list.size() == want and guards.foes().size() == want, "(%d)" % want)
	SmokeTest._check("guards: range beats a Sniper", Config.GUARD_RANGE > StructureDefs.DEFS.sniper.range)
	_fire(w, guards, grid)
	_capture(w, castles, guards)
	w.queue_free()


static func _level1_unchanged() -> void:
	var l1 := Level01.build()
	var plain: bool = l1.castles.all(func(c): return c.layout.towers.is_empty() and c.layout.keep.is_empty())
	SmokeTest._check("L1: castle layouts have no towers or keep", plain)


static func _reach(lvl: Dictionary) -> void:
	var grid: Grid = lvl.grid
	var seen := LevelShape.walkable_from(grid, lvl.landing_hint)
	var raiders := RaiderField.new(grid)
	raiders.rebuild([lvl.landing_hint])
	for c in lvl.castles:
		var lay: Dictionary = c.layout
		var first: Vector2i = lay.climbs[0][0]
		var d: Vector2i = first - Vector2i(lay.rect.get_center())
		var out := Vector2i(signi(d.x), 0) if absi(d.x) > absi(d.y) else Vector2i(0, signi(d.y))
		var gate: Vector2i = lay.winch + Vector2i(-1, 0) if lay.raised else lay.gates[0].outer.back()
		var near_gate: Vector2i = lay.winch if lay.raised else gate
		var by_raider := false
		for o in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			by_raider = by_raider or raiders.dist[grid.idx(near_gate.x + o.x, near_gate.y + o.y)] >= 0
		SmokeTest._check("L2: %s climb route reachable on foot" % c.id, seen.has(first + out))
		SmokeTest._check("L2: %s gate approach reachable (Operative)" % c.id, seen.has(near_gate))
		SmokeTest._check("L2: %s gate approach reachable (raiders)" % c.id, by_raider)
	SmokeTest._check("L2: the Rift is reachable on foot", seen.has(Vector2i(lvl.rift.x, lvl.rift.z)))


## From the courtyard the Operative must reach every tower top by the wall walk.
static func _towers(lvl: Dictionary) -> void:
	var grid: Grid = lvl.grid
	for c in lvl.castles:
		var lay: Dictionary = c.layout
		var seen := LevelShape.walkable_from(grid, lay.courtyard[0])
		var bad: Array = lay.towers.filter(func(t): return not seen.has(t.centre))
		SmokeTest._check("L2: %s towers (%d) climbable from the courtyard" % [c.id, lay.towers.size()], not lay.towers.is_empty() and bad.is_empty())


class Dummy:
	var node := Node3D.new()
	var radius := 0.5
	var kind := "operative"
	var damage := 0.0
	var live := true


static func _prey(d: Dummy) -> Dictionary:
	return { "node": d.node, "radius": d.radius, "kind": d.kind, "alive": func(): return d.live, "hit": func(x, _p = null): d.damage += x }


## A spot `cells` from `post` with a clear line, and clear lines to where it would sidestep.
static func _spot(guards: CastleGuards, post: Vector3, cells: float, grid: Grid, sidestep := 30.0) -> Variant:
	for a in 16:
		var dir := Vector3(cos(a * TAU / 16.0), 0, sin(a * TAU / 16.0))
		var p := post + dir * cells * Config.CELL
		var side := Vector3(-dir.z, 0, dir.x) * sidestep
		var pts := [p, p + side, p - side]
		if pts.all(func(q): return grid.in_bounds(floori(q.x / Config.CELL), floori(q.z / Config.CELL)) \
				and guards.line_clear(post, Vector3(q.x, grid.smooth_y(q.x, q.z), q.z))):
			return { "p": p, "side": side.normalized() }
	return null


static func _fire(w: World, guards: CastleGuards, grid: Grid) -> void:
	var s: Dictionary = guards.list[0]
	var post: Vector3 = s.post
	var spot = _spot(guards, post, 25.0, grid)
	SmokeTest._check("guards: found a clear 25-cell firing line", spot != null)
	if spot == null:
		return
	var d := Dummy.new()
	d.node.position = Vector3(spot.p.x, grid.smooth_y(spot.p.x, spot.p.z), spot.p.z)
	var q := _prey(d)
	guards.prey = func(): return [q]
	SmokeTest._check("guards: see a target in range with line of sight", not guards.pick(post, [q]).is_empty())
	var far = _spot(guards, post, 41.0, grid, 0.0)
	if far != null:
		var f := Dummy.new()
		f.node.position = Vector3(far.p.x, grid.smooth_y(far.p.x, far.p.z), far.p.z)
		SmokeTest._check("guards: a clear line beyond GUARD_RANGE is ignored", guards.line_clear(post, f.node.position) and guards.pick(post, [_prey(f)]).is_empty())
	else:
		SmokeTest._check("guards: found a clear 41-cell line for the range test", false)
	# Terrain between post and target blocks the shot.
	var mid := post.lerp(d.node.position, 0.5)
	var cell := grid.world_to_cell(mid.x, mid.z)
	var saved := {}
	for c in grid.cells_in_radius(cell.x, cell.y, 3.0):
		saved[c] = grid.height_at(c.x, c.y)
		grid.set_height(c.x, c.y, 34.0)
	SmokeTest._check("guards: terrain blocks line of sight", guards.pick(post, [q]).is_empty())
	for c in saved:
		grid.set_height(c.x, c.y, saved[c])
	# Only this Sentinel is ready: a stationary target is hit, with a visible charge first.
	for o in guards.list:
		o.cd = 1.0e9
	s.cd = 0.0
	var saw_charge := false
	var saw_bolt := false
	for i in 220:
		guards.update(0.05)
		w.effects.update(0.05)
		saw_charge = saw_charge or s.charge >= 0.0
		saw_bolt = saw_bolt or not w.effects.lobs().is_empty()
	SmokeTest._check("guards: charge-up then a bolt in flight", saw_charge and saw_bolt)
	SmokeTest._check("guards: bolt hits a stationary Operative", is_equal_approx(d.damage, Config.GUARD_DMG_OPERATIVE) or d.damage >= Config.GUARD_DMG_OPERATIVE, "(%.0f dmg)" % d.damage)
	# A target that keeps walking is missed by the first bolt.
	d.damage = 0.0
	d.node.position = Vector3(spot.p.x, grid.smooth_y(spot.p.x, spot.p.z), spot.p.z)
	s.cd = 0.0
	s.charge = -1.0
	var first_hit := false
	for i in 150:  # 7.5 s: the first bolt fires after ~0.8 s and lands ~3 s later
		d.node.position += spot.side * Config.WALK * 0.05
		guards.update(0.05)
		w.effects.update(0.05)
		first_hit = first_hit or d.damage > 0.0
	SmokeTest._check("guards: bolt misses an Operative who keeps moving", not first_hit)
	# A sniper-style hit kills a Sentinel (hp, target list, foes).
	s.enemy.hit.call(Config.SENTINEL.hp + 1.0)
	SmokeTest._check("guards: can be shot dead", not s.alive and not guards.foes().has(s))


static func _capture(w: World, castles: Strongholds, guards: CastleGuards) -> void:
	var c: Dictionary = castles.list[0]
	var id: String = c.id
	c.state = "capturing"
	guards.update(0.05)
	SmokeTest._check("guards: capture clears the garrison", guards.alive_at(id) == 0)
	c.state = "hostile"
	for i in int(Config.GUARD_RESPAWN * 2.0 / 0.5):
		guards.update(0.5)
	SmokeTest._check("guards: a retaken castle regrows its garrison", guards.alive_at(id) > 0)
