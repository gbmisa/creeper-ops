class_name Terp
## A built, connected Terp works the nearest unfinished painted cell in range that no
## other Terp has claimed and that has no structure on it. One level per step.
## State on the structure is plain data: job = { x, z, paid, timer }.


static func tick(s: Structure, dt: float, mgr) -> void:
	var job: Dictionary = s.job
	if not job.is_empty() and not _ok(s, mgr, int(job.get("x", -1)), int(job.get("z", -1))):
		if s.in_flight > 0:
			s.job["x"] = -1  # let in-flight packets die without crediting the next cell
			return
		s.job = {}
		job = {}
	if job.is_empty():
		var c := _nearest(s, mgr)
		if c.x < 0:
			return
		s.job = { "x": c.x, "z": c.y, "paid": 0, "timer": 0.0 }
		return
	if int(job.paid) < Config.TERP_PACKETS:
		return
	var prev := float(job.timer)
	var t := prev + dt
	job.timer = t
	if prev <= 0.0 or int(prev / 0.25) != int(t / 0.25):
		_beam(s, mgr)
	if t >= Config.TERP_STEP_TIME:
		_step(s, mgr)


static func in_range(s: Structure, x: int, z: int) -> bool:
	var r := float(s.def.get("work_range", 7.0))
	var dx := s.x - x
	var dz := s.z - z
	return float(dx * dx + dz * dz) <= r * r + 0.001


static func _nearest(s: Structure, mgr) -> Vector2i:
	var g: Grid = mgr.world.grid
	var r := int(ceil(float(s.def.get("work_range", 7.0))))
	var best := Vector2i(-1, -1)
	var bd := INF
	var bi := 0x7fffffff
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := s.x + dx
			var z := s.z + dz
			if not _ok(s, mgr, x, z) or _held(mgr, x, z, s):
				continue
			var d := float(dx * dx + dz * dz)
			var i := g.idx(x, z)
			if d < bd - 0.001 or (absf(d - bd) < 0.001 and i < bi):
				best = Vector2i(x, z)
				bd = d
				bi = i
	return best


static func _ok(s: Structure, mgr, x: int, z: int) -> bool:
	var g: Grid = mgr.world.grid
	if not g.in_bounds(x, z) or not in_range(s, x, z):
		return false
	if TerpPaint.cell_reason(g, Vector2i(x, z)) != "":
		return false
	if mgr.world.occupied.call(x, z):
		return false
	var i := g.idx(x, z)
	var target := g.terp_target[i]
	return target >= 0.0 and absf(g.height[i] - target) > 0.001


static func _held(mgr, x: int, z: int, self_s: Structure) -> bool:
	for o in mgr.list:
		if o == self_s or o.type != "terp" or o.dead or o.job.is_empty():
			continue
		if int(o.job.get("x", -1)) == x and int(o.job.get("z", -1)) == z:
			return true
	return false


static func _step(s: Structure, mgr) -> void:
	var g: Grid = mgr.world.grid
	var x := int(s.job.x)
	var z := int(s.job.z)
	var i := g.idx(x, z)
	var before := g.height[i]
	var target := g.terp_target[i]
	var by := clampf(target - before, -1.0, 1.0)
	# 11b: Metal spends 2 Ore when the step starts and is laid from terp_mat.
	var mat := int(g.terp_mat[i])
	if mat != Grid.Mat.EARTH:
		mat = Grid.Mat.EARTH
	var changed := TerrainEdit.raise(mgr.world, [Vector2i(x, z)], by, mat)
	if changed.is_empty() or absf(g.height[i] - before) < 0.001:
		s.job = {}
		_sync(mgr)
		return
	var extra := int(s.job.paid) - Config.TERP_PACKETS
	s.job.paid = maxi(0, extra)
	s.job.timer = 0.0
	if absf(g.height[i] - g.terp_target[i]) < 0.001:
		g.terp_target[i] = -1.0
		g.terp_mat[i] = 0
		s.job = {}
	_sync(mgr)


static func _beam(s: Structure, mgr) -> void:
	var g: Grid = mgr.world.grid
	var x := int(s.job.get("x", -1))
	var z := int(s.job.get("z", -1))
	if not g.in_bounds(x, z):
		return
	var up := g.terp_target[g.idx(x, z)] > g.height_at(x, z)
	var col := Color("e2b15a") if up else Color("5aa0ff")
	mgr.world.effects.beam(s.link_point(), g.cell_ground(x, z) + Vector3(0, 0.3, 0), col, 0.22, 0.14)


static func _sync(mgr) -> void:
	var tint = mgr.world.get_meta("terp_tint") if mgr.world.has_meta("terp_tint") else null
	if tint != null:
		tint.sync()
