class_name RangeTestExpand
## Track EXPAND phase 1 checks for `--range-test`: every district reachable from every spawn,
## each extract's condition, the boss-death unlock, and a headless perf proxy (node count,
## build + navmesh-bake ms; real fps needs a display run at 1600x900).

static var t: RangeTest


static func run(test: RangeTest, session: RangeSession, player: TacticalPlayer) -> void:
	t = test
	var game := SkirmishGame.new()
	t.add_child(game)
	game.build_world()
	var t0 := Time.get_ticks_msec()
	var lay := game.layout
	var build_ms := Time.get_ticks_msec() - t0
	var t1 := Time.get_ticks_msec()
	game.session = session
	_start_min(game, session)
	var bake_ms := Time.get_ticks_msec() - t1
	var map := lay.region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	for i in 30:
		await t.get_tree().physics_frame
	_reach(t, map)
	_extracts(t, game)
	_boss_unlock(t, game)
	_counts(t, lay, game, build_ms, bake_ms)
	game.queue_free()


## Minimal start: we only need layout + extracts + bots, no player/weapons/labels.
static func _start_min(game: SkirmishGame, session: RangeSession) -> void:
	game.session = session
	game.bal = t.bal
	game.log = RangeHitLog.new()
	t.add_child(game.log)
	game.layout.bake()
	for e in SkirmishData.EXTRACTS:
		game.extracts.append({"pos": e["pos"], "cond": e["cond"], "name": e["name"], "progress": 0.0, "call_progress": 0.0})
	game.spawn_enemies()


## 3 spawns x 4 district sample points: every district reachable on foot from every spawn.
static func _reach(test: RangeTest, map: RID) -> void:
	var districts := {
		"north": [Vector3(-25, 0, -66), Vector3(8, 0, -62), Vector3(-8, 4.5, -80)],
		"east": [Vector3(78, 0, 0), Vector3(88, 0, -15), Vector3(102, 0, 20)],
		"south": [Vector3(0, 0, 75), Vector3(-27, 0, 93), Vector3(29, 0, 74)],
		"west": [Vector3(-96, 0, 30), Vector3(-85, 0, 0), Vector3(-75, 0, 10)],
	}
	for name in districts:
		var ok := true
		var why := ""
		for s in SkirmishData.SPAWNS:
			for p in districts[name]:
				if not _reaches(map, s, p, 3.0):
					ok = false
					why += " spawn %s -> %s" % [s, p]
		test.check("district %s reachable from all 3 spawns" % name, ok, why)


static func _reaches(map: RID, from: Vector3, to: Vector3, tol: float) -> bool:
	var navmap := map
	var f: Vector3 = NavigationServer3D.map_get_closest_point(navmap, from)
	var tt: Vector3 = NavigationServer3D.map_get_closest_point(navmap, to)
	if f.distance_to(from) > 2.0 or tt.distance_to(to) > 2.0:
		return false
	var path := NavigationServer3D.map_get_path(navmap, f, tt, true)
	return path.size() > 1 and path[path.size() - 1].distance_to(tt) < tol


static func _extracts(test: RangeTest, game: SkirmishGame) -> void:
	test.check("3 extracts defined", game.extracts.size() == 3)
	test.check("extract conditions: open / boss / call",
		game.extracts[0]["cond"] == "open" and game.extracts[1]["cond"] == "boss" and game.extracts[2]["cond"] == "call")
	test.check("extract status icons", game.extract_status(0) == "OPEN" and game.extract_status(1) == "LOCKED" and game.extract_status(2) == "CALL")


static func _boss_unlock(test: RangeTest, game: SkirmishGame) -> void:
	var boss: ScavBot = null
	for b in game.bots:
		if b.kind == "boss":
			boss = b
	test.check("boss exists", boss != null)
	if boss == null:
		return
	game._on_bot_died(boss)
	test.check("Warlord death unlocks DEPOT extract", game.boss_dead and game.extract_status(1) == "OPEN")
	var depot_in := SkirmishData.EXTRACTS[1]["pos"] + Vector3(1, 0, 0)
	game.tick_extract(SkirmishData.EXTRACT_TIME + 1.0, depot_in)
	test.check("DEPOT extract finishes after unlock", game.tick_extract(0.0, depot_in) == 1)


static func _counts(test: RangeTest, lay: SkirmishLayout, game: SkirmishGame, build_ms: int, bake_ms: int) -> void:
	test.check("bot count is 24", game.bots.size() == 24)
	var nodes := _count_nodes(lay)
	print("[range] expand perf: %d nodes, build %d ms, navmesh bake %d ms (headless proxy; fps needs a 1600x900 display run)" % [nodes, build_ms, bake_ms])
	test.check("extract markers built for all 3 extracts", lay.extract_markers.size() == 3)


static func _count_nodes(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count_nodes(ch)
	return c
