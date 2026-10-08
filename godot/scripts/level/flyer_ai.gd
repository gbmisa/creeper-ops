class_name FlyerAi
## Per-type flyer behaviour (Stage 19). Bats dive, Gasbags bomb creeper, Wyverns breathe fire.
## Targets are Structures from host.structures (bats and Gasbags) or the prey list (Wyvern cone).
## A flyer with `node_bias` (a sealed-Node flock) heads for the Command Node first.


static func step(fl: Flyers, f: Dictionary, dt: float) -> void:
	f.cd = float(f.cd) - dt
	f.think = float(f.think) - dt
	match str(f.type):
		"Spore Bat": _bat(fl, f, dt)
		"Gasbag": _gasbag(fl, f, dt)
		"Wyvern": _wyvern(fl, f, dt)


static func _sm(fl: Flyers) -> StructureManager:
	return fl.host.structures


static func _live(s) -> bool:
	return s != null and not (s as Structure).dead


## Nearest structure by ground distance. `prefer` types count as 30 m nearer. Beacons are skipped.
static func pick_structure(fl: Flyers, f: Dictionary, prefer: Array, weapons_only := false) -> Structure:
	var sm := _sm(fl)
	if sm == null:
		return null
	var p := (f.node as Node3D).position
	if bool(f.node_bias):
		var n := sm.command_node()
		if n != null and not n.dead:
			return n
	var best: Structure = null
	var bs := INF
	for s in sm.list:
		if s.dead or s.type == "beacon" or (weapons_only and not bool(s.def.get("weapon", false))):
			continue
		var d := Vector2(s.pos.x - p.x, s.pos.z - p.z).length()
		if prefer.has(s.type):
			d -= 30.0
		if d < bs:
			bs = d
			best = s
	return best


## The structure with most neighbours within `radius` cells: where a Gasbag's blobs hurt most.
static func pick_cluster(fl: Flyers, f: Dictionary, radius: float) -> Structure:
	var sm := _sm(fl)
	if sm == null:
		return null
	if bool(f.node_bias):
		return pick_structure(fl, f, [])
	var p := (f.node as Node3D).position
	var best: Structure = null
	var bs := -INF
	for s in sm.list:
		if s.dead or s.type == "beacon":
			continue
		var n := 0
		for o in sm.list:
			if not o.dead and Vector2(o.x - s.x, o.z - s.z).length() <= radius:
				n += 1
		var score := float(n) - Vector2(s.pos.x - p.x, s.pos.z - p.z).length() * 0.02
		if score > bs:
			bs = score
			best = s
	return best


static func _retarget(f: Dictionary, s: Structure, every: float) -> void:
	f.target = s
	f.think = every


static func _orbit(fl: Flyers, f: Dictionary, around: Vector3, r: float) -> Vector3:
	var a: float = float(f.phase) + fl.time * 0.8
	return around + Vector3(cos(a) * r, 0, sin(a) * r)


static func _idle(fl: Flyers, f: Dictionary, dt: float) -> void:
	fl.fly(f, _orbit(fl, f, f.home, 10.0), dt, 0.6)


# ---- Spore Bat ---------------------------------------------------------------------
static func _bat(fl: Flyers, f: Dictionary, dt: float) -> void:
	var node := f.node as Node3D
	var row: Dictionary = f.row
	var t = f.target
	if (not _live(t)) and float(f.think) <= 0.0:
		_retarget(f, pick_structure(fl, f, ["relay", "collector"]), 1.0)
		t = f.target
	if not _live(t):
		_idle(fl, f, dt)
		return
	var s := t as Structure
	var flat := Vector2(s.pos.x - node.position.x, s.pos.z - node.position.z).length()
	match str(f.state):
		"cruise":
			var goal := s.pos if flat > Config.FLYER_DIVE_RANGE * 2.0 else _orbit(fl, f, s.pos, 2.5)
			fl.fly(f, goal, dt)
			if flat < Config.FLYER_DIVE_RANGE and float(f.cd) <= 0.0:
				f.state = "dive"
		"dive":
			var low := s.pos.y + 1.4
			fl.fly(f, s.pos, dt, 1.0, low, 22.0)
			if absf(node.position.y - low) < 0.6 and flat < 2.0:
				_bite(fl, f, s, float(row.dive_dmg))
				f.cd = float(row.dive_every)
				f.state = "climb"
		"climb":
			fl.fly(f, _orbit(fl, f, s.pos, 3.0), dt)
			var up: float = fl.ground_max(node.position.x, node.position.z) + float(row.alt)
			if node.position.y >= up - 0.8:
				f.state = "cruise"
				_retarget(f, null, 0.0)


static func _bite(fl: Flyers, f: Dictionary, s: Structure, dmg: float) -> void:
	fl.world.effects.burst(s.pos + Vector3(0, 1, 0), Color("a8ff5a"), 1.2, 0.2)
	Sfx.play("hurt", s.pos)
	_sm(fl).damage(s, dmg)
	if s.dead:
		fl.stats.structures += 1


# ---- Gasbag ------------------------------------------------------------------------
static func _gasbag(fl: Flyers, f: Dictionary, dt: float) -> void:
	var node := f.node as Node3D
	var t = f.target
	if (not _live(t) or float(f.think) <= 0.0):
		_retarget(f, pick_cluster(fl, f, 6.0), 6.0)
		t = f.target
	if not _live(t):
		_idle(fl, f, dt)
		return
	var s := t as Structure
	var left: float = fl.fly(f, s.pos, dt)
	if left < 2.5 and float(f.cd) <= 0.0:
		f.cd = float(f.row.drop_every)
		drop(fl, f)


## A creeper blob falls from the bag onto the cell below it.
static func drop(fl: Flyers, f: Dictionary) -> void:
	var node := f.node as Node3D
	var w := fl.world
	var c := w.grid.world_to_cell(node.position.x, node.position.z)
	if not w.grid.in_bounds(c.x, c.y):
		return
	var from := node.position + Vector3(0, -1.0, 0)
	var to := w.grid.cell_ground(c.x, c.y)
	var amount := float(f.row.drop_amount)
	fl.stats.drops += 1
	Sfx.play("drip", node.position)
	w.effects.lob(from, to, { "color": Color("88ff55"), "size": 0.7, "time": 0.8, "arc": 0.0,
		"on_arrive": func():
			w.creeper.add(c.x, c.y, amount)
			w.effects.burst(to, Color("88ff55"), 2.0, 0.4)
			Sfx.play("pop", to) })


# ---- Wyvern ------------------------------------------------------------------------
## Prey the Wyvern hunts: the Operative within `hunt` metres, else the nearest weapon.
static func _wyvern_goal(fl: Flyers, f: Dictionary) -> Dictionary:
	var node := f.node as Node3D
	var op = fl.host.operative.call()
	if op != null and (op.prey as Dictionary).has("node"):
		var q: Dictionary = op.prey
		if (q.alive as Callable).call():
			var qp: Vector3 = (q.node as Node3D).position
			if Vector2(qp.x - node.position.x, qp.z - node.position.z).length() <= float(f.row.hunt):
				return { "pos": qp + Vector3(0, 1.0, 0), "operative": true }
	var s := pick_structure(fl, f, [], true)
	if s == null:
		s = pick_structure(fl, f, [])
	if s == null:
		return {}
	return { "pos": s.pos + Vector3(0, 1.0, 0), "operative": false }


static func _wyvern(fl: Flyers, f: Dictionary, dt: float) -> void:
	var node := f.node as Node3D
	var row: Dictionary = f.row
	if float(f.breath) > 0.0:
		f.breath = float(f.breath) - dt
		fl.fly(f, node.position + (f.aim as Vector3).normalized() * 0.1, dt, 0.2)
		_breathe(fl, f, dt)
		return
	if float(f.think) <= 0.0:
		f.think = 0.5
		f["goal"] = _wyvern_goal(fl, f)
	var goal: Dictionary = f.get("goal", {})
	if goal.is_empty():
		_idle(fl, f, dt)
		return
	var gp: Vector3 = goal.pos
	var flat := Vector2(gp.x - node.position.x, gp.z - node.position.z).length()
	var hold: float = float(row.breath_range) * 0.6
	if flat > hold:
		fl.fly(f, gp, dt)
	else:
		fl.fly(f, _orbit(fl, f, gp, hold), dt, 0.5)
	if flat <= float(row.breath_range) * 0.85 and float(f.cd) <= 0.0:
		f.cd = float(row.breath_every)
		f.breath = float(row.breath_time)
		f.aim = gp - node.position
		Sfx.play("roar", node.position)


## Fire cone: everything in the prey list inside the cone takes dps * dt.
static func _breathe(fl: Flyers, f: Dictionary, dt: float) -> void:
	var node := f.node as Node3D
	var row: Dictionary = f.row
	var dir := (f.aim as Vector3).normalized()
	var origin := node.position + dir * 1.2
	var reach: float = row.breath_range
	var half: float = row.breath_half_angle
	var tip := origin + dir * reach
	if fmod(fl.time, 0.1) < dt:
		fl.world.effects.burst(origin + dir * reach * 0.6, Color("ff7a2a"), reach * 0.35, 0.2)
		fl.world.effects.burst(tip, Color("ffc040"), reach * 0.25, 0.15)
	for q in fl.host.prey.call():
		if not (q.alive as Callable).call():
			continue
		var to: Vector3 = (q.node as Node3D).position + Vector3(0, 0.8, 0) - origin
		var d := to.length()
		if d > reach + float(q.get("radius", 1.0)) or d < 0.01:
			continue
		if dir.angle_to(to) <= half + atan2(float(q.get("radius", 1.0)), d):
			(q.hit as Callable).call(float(row.breath_dps) * dt)
	if float(f.breath) <= 0.0:
		f.aim = Vector3.ZERO
