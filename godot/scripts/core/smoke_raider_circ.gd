class_name SmokeRaiderCirc
## Raiders must not circle: a raider that can only crawl toward its goal idles
## instead of orbiting an unreachable point (e.g. a patrol point circling
## behind a wall). Walk animation speed must match actual ground speed, and
## holding position to shoot must idle the walk clip instead of leaving a
## stale sprint playing while standing still.


static func run(g) -> void:
	_blocked_walk_rests(g)
	_open_ground_not_stuck(g)
	_pocket_no_circle(g)
	_walk_anim_matches_speed(g)
	_hold_position_idles_anim(g)
	_pad(g, 40, 40, 70, 50)  # leave the terrain flat for the next group


static func _pad(g, x0: int, z0: int, x1: int, z1: int) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h })
	TerrainEdit.apply(g.surface, edits)


static func _wall(g, x0: int, z0: int, x1: int, z1: int, levels: float) -> void:
	var grid: Grid = g.surface.grid
	var h: float = grid.height_at(x0, z0 - 2)
	var edits := []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			edits.append({ "x": x, "z": z, "height": h + levels * Config.LEVEL_H })
	TerrainEdit.apply(g.surface, edits)


static func _clear(g) -> void:
	for it in g.surface.effects.lobs():
		it.dead = true
	g.surface.effects.update(0.0)
	for o in g.hazards.nests.raiders.list.duplicate():
		g.hazards.nests.raiders.kill(o)


static func _spawn_at(g, who: String, cell: Vector2i) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	var nest: Dictionary = nests.nests.filter(func(n): return n.alive)[0]
	nests.raiders.spawn(nest, RaiderDefs.named(who), true)
	var r := nests.raiders.list.back() as Dictionary
	r.guard = true
	(r.node as Node3D).position = g.surface.grid.cell_ground(cell.x, cell.y)
	return r


## A raider walking into a tall wall gives up and idles instead of pacing.
static func _blocked_walk_rests(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_wall(g, 52, 42, 52, 48, 4.0)  # tall north-south wall
	_clear(g)
	var r := _spawn_at(g, "Spitter", Vector2i(50, 45))  # 4 m from the wall
	var raiders = g.hazards.nests.raiders
	var node: Node3D = r.node
	var goal := Vector2(node.position.x + 30.0, node.position.z)  # straight through the wall
	var engaged := false
	for i in 160:  # 8 s: reach wall (~1.3 s), stuck 1.5 s, rest 2 s, repeat
		raiders._walk(r, goal, 0.05)
		if float(r.get("_stuck_rest", 0.0)) > 0.0 or float(r.get("_stuck_t", 0.0)) > 1.0:
			engaged = true
	var st: int = int(node.get_meta("_anim_state", -1))
	SmokeTest._check("blocked raider rests instead of pacing",
		engaged and st == CreatureAnim.ST_IDLE,
		"(engaged %s, anim state %d)" % [engaged, st])
	_clear(g)


## Open ground: full-speed walking never trips the stuck detector.
static func _open_ground_not_stuck(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var r := _spawn_at(g, "Spitter", Vector2i(44, 45))
	var raiders = g.hazards.nests.raiders
	var from: Vector3 = (r.node as Node3D).position
	for i in 40:  # 2 s across flat ground
		raiders._walk(r, Vector2(from.x + 30.0, from.z), 0.05)
	var to: Vector3 = (r.node as Node3D).position
	var moved := Vector2(to.x - from.x, to.z - from.z).length()
	SmokeTest._check("open-ground walk not flagged stuck",
		moved > 4.0 and float(r.get("_stuck_t", 0.0)) < 0.01 and float(r.get("_stuck_rest", 0.0)) < 0.01,
		"(moved %.1f m)" % moved)
	_clear(g)


## Three guard spitters walled into a 1-cell pocket, chasing an orbiting patrol
## point they can never reach: they must idle far more than they pace.
static func _pocket_no_circle(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_wall(g, 54, 44, 54, 46, 4.0)  # west
	_wall(g, 54, 44, 56, 44, 4.0)  # north
	_wall(g, 54, 46, 56, 46, 4.0)  # south
	_wall(g, 56, 44, 56, 46, 4.0)  # east: 1-cell box at (55,45)
	_clear(g)
	var grid: Grid = g.surface.grid
	var raiders = g.hazards.nests.raiders
	var home := grid.cell_ground(55, 45)
	var pack := []
	var prev := []
	for i in 3:
		var r := _spawn_at(g, "Spitter", Vector2i(55, 45))
		pack.append(r)
		prev.append((r.node as Node3D).position)
	var t := 0.0
	var path := 0.0
	var idle_samples := 0
	for i in 400:  # 20 s
		t += 0.05
		for j in pack.size():  # same orbit Raiders._patrol uses; unreachable here
			var r: Dictionary = pack[j]
			var a := t * 0.5 + float(r.get("phase", 0.0))
			raiders._walk(r, Vector2(home.x + cos(a) * 4.0, home.z + sin(a) * 4.0), 0.05)
			if int((r.node as Node3D).get_meta("_anim_state", -1)) == CreatureAnim.ST_IDLE:
				idle_samples += 1
		for j in pack.size():
			var pp: Vector3 = (pack[j].node as Node3D).position
			path += Vector2(pp.x - prev[j].x, pp.z - prev[j].z).length()
			prev[j] = pp
	# Free circling would cover ~150 m (baseline measured pre-fix geometry);
	# with stuck->rest they idle most of the time.
	SmokeTest._check("walled-in raiders idle instead of circling",
		path < 50.0 and idle_samples > 400,
		"(path %.1f m, idle %d/1200 samples)" % [path, idle_samples])
	_clear(g)


## Walk clip speed matches actual ground speed (no full-sprint legs while sliding).
static func _walk_anim_matches_speed(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var r := _spawn_at(g, "Spitter", Vector2i(44, 45))
	var node: Node3D = r.node
	var player: AnimationPlayer = node.get_meta("_anim_player")
	if player == null:
		SmokeTest._check("spitter has a model player", false, "(no .glb?)")
		_clear(g)
		return
	var sc: float = float(node.get_meta("_anim_scale", 1.0))
	var raiders = g.hazards.nests.raiders
	var from: Vector3 = node.position
	raiders._walk(r, Vector2(from.x + 30.0, from.z), 0.5)
	var want := 3.0 / (CreatureAnim.WALK_SPEED * sc)  # spitter speed 3.0 m/s
	SmokeTest._check("walk anim matches ground speed",
		absf(player.speed_scale - want) < 0.2,
		"(scale %.2f want %.2f)" % [player.speed_scale, want])
	_clear(g)


## A spitter holding position to shoot idles its walk clip (no stale sprint).
static func _hold_position_idles_anim(g) -> void:
	_pad(g, 40, 40, 70, 50)
	_clear(g)
	var r := _spawn_at(g, "Spitter", Vector2i(46, 44))
	var node: Node3D = r.node
	var player: AnimationPlayer = node.get_meta("_anim_player")
	if player == null:
		SmokeTest._check("spitter has a model player", false, "(no .glb?)")
		_clear(g)
		return
	var raiders = g.hazards.nests.raiders
	# Sprint first so the walk clip is playing fast (the stale state).
	var from: Vector3 = node.position
	raiders._walk(r, Vector2(from.x + 20.0, from.z), 0.5)
	var sprinting: float = player.speed_scale
	# Hold position: fake target 32 m out (in 40 m range, beyond 26 m standoff).
	var fake := Node3D.new()
	fake.position = node.position + Vector3(32.0, 0, 0)
	for i in 20:
		RaiderShots._move(raiders, r, 0.05, { "node": fake }, r.tier)
	fake.queue_free()
	var st: int = int(node.get_meta("_anim_state", -1))
	SmokeTest._check("holding spitter idles its walk clip",
		sprinting > 2.0 and st == CreatureAnim.ST_IDLE and is_equal_approx(player.speed_scale, 1.0),
		"(was %.2f, state %d, now %.2f)" % [sprinting, st, player.speed_scale])
	_clear(g)
