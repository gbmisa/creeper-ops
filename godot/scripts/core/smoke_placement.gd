class_name SmokePlacement
## Stage 9b P4 (Stage 12): level placement of Salvage Engines and Ore veins. Fresh grids, so the
## checks do not depend on what earlier smoke files dug or raised.


static func run(g) -> void:
	for n in [1, 2]:
		var lv := Levels.build(n)
		_level(n, lv)
	_cave()
	_cash(g)


static func _level(n: int, lv: Dictionary) -> void:
	var grid: Grid = lv.grid
	var tag := "L%d" % n
	var seen := SmokeEngines._flood(grid, lv.landing_hint)
	var rows: Array = lv.engines
	SmokeTest._check("placement %s: at least 3 engines" % tag, rows.size() >= 3, str(rows.size()))
	var kinds := {}
	var clear := true
	var reach := true
	var bad := []
	for r in rows:
		var was := clear
		kinds[r.kind] = true
		for s in r.sockets:
			reach = reach and seen.has(s.cell)
		for c in EngineDefs.body_cells(r):
			for h in lv.hives:  # never inside a hive's claim (r 6.15) or an emitter's footprint
				clear = clear and Vector2(c.x - h.x, c.y - h.z).length() > 7.0
			for e in lv.emitters:
				clear = clear and Vector2(c.x - e.x, c.y - e.z).length() > 3.0
			for cs in lv.castles:
				clear = clear and not Rect2i(int(cs.x) - 1, int(cs.z) - 1, int(cs.size) + 2, int(cs.size) + 2).has_point(c)
		if was and not clear:
			bad.append(r.id)
			clear = true
	clear = bad.is_empty()
	SmokeTest._check("placement %s: engines clear of hives, emitters and castle walls" % tag, clear, str(bad))
	SmokeTest._check("placement %s: every socket can be reached on foot from the landing site" % tag, reach)
	SmokeTest._check("placement %s: more than one kind of engine" % tag, kinds.size() >= 2, str(kinds.keys()))
	SmokeTest._check("placement %s: at least one engine within 40 cells of the landing site" % tag,
		rows.any(func(r): return Vector2(r.x - lv.landing_hint.x, r.z - lv.landing_hint.y).length() <= 40.0))
	var top_climb := rows.filter(func(r): return EngineDefs.kind(r).stair).size()
	SmokeTest._check("placement %s: some engines need the stair climbed" % tag, top_climb >= 2, str(top_climb))
	var ore_ok := true
	var ore_note := ""
	for o in lv.ores:
		var i := grid.idx(int(o.x), int(o.z))
		var good: bool = grid.blocked[i] == 0 and grid.zone[i] == Grid.Zone.NONE and seen.has(Vector2i(int(o.x), int(o.z)))
		for h in lv.hives:
			good = good and Vector2(int(o.x) - h.x, int(o.z) - h.z).length() > 7.0
		if not good:
			ore_ok = false
			ore_note = "%d,%d" % [int(o.x), int(o.z)]
	SmokeTest._check("placement %s: ore veins are buildable ground, reachable and outside hive claims" % tag, ore_ok, ore_note)


static func _cave() -> void:
	var cave := Cave01.build()
	var grid: Grid = cave.grid
	var seen := SmokeEngines._flood(grid, cave.pad)
	var rows: Array = cave.engines
	var reach := true
	var under := true
	for r in rows:
		for s in r.sockets:
			reach = reach and seen.has(s.cell)
		under = under and float(r.floor) + float(EngineDefs.kind(r).top) < float(cave.ceiling) - 1.0
	SmokeTest._check("placement cave: 1-2 engines", rows.size() >= 1 and rows.size() <= 2, str(rows.size()))
	SmokeTest._check("placement cave: every socket reachable from the pad and under the ceiling", reach and under)


## No network underground: a hooked cave engine pays 40% of its reserve at once.
static func _cash(g) -> void:
	var e: Dictionary = g.cave_engines.list[0]
	var s: Dictionary = e.sockets[0]
	var before: float = g.stockpile.salvage
	var reserve: float = e.reserve
	SmokeTest._check("cave engine: no 'build a Relay' refusal underground", EngineHook.ready(g.cave_engines, e, s)
		and EngineHook.prompt(g.cave_engines, e, s).contains("salvage the cache"))
	g.cave_engines.hook(e, s)
	SmokeTest._check("cave engine: hooking pays 40% of the reserve at once", is_equal_approx(g.stockpile.salvage - before, reserve * EngineDefs.CAVE_CASH)
		and float(e.reserve) == 0.0, str(g.stockpile.salvage - before))
	g.stockpile.salvage = before
