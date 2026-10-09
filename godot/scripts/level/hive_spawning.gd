class_name SporeNests
extends RefCounted
## Hive spawner (was spore_nests.gd). Each active hive breeds raiders; grown pits are the
## channels, so killing pits slows the clock. Stage, parts, Blight and rebuilding live in
## hives.gd. The class name stays SporeNests: Game, castles and the smoke already use it.
## Nests die when the Core dies (Operative or Lance only). The objective id is still "nests".

var world: World
var nests: Array[Dictionary] = []
var raiders: Raiders
var structures: StructureManager = null
var stockpile: Stockpile = null
var prey := func() -> Array: return []
var goal_cells := func() -> Array: return []
var time := 0.0
var tier := 0
var raiding := false
var schedule: Dictionary = {}
var level: Dictionary = {}
var overrun_t := 0.0
var seal := 0.0
var seal_arm := 0.0
var operative: Callable = func(): return null
var node_pos := func() -> Vector3: return Vector3.ZERO
var builder = null                 # EnemyBuilder: Lance scale inside a Shield Dome
var flyers: Flyers
var hub_mortars: Array = []       # finished hub mortars; shells() draws their telegraphs


func _init(w: World, defs: Array, sched: Dictionary = {}, lvl: Dictionary = {}) -> void:
	world = w
	schedule = sched
	level = lvl
	raiders = Raiders.new(w)
	raiders.loot_host = self
	flyers = Flyers.new(self)
	for d in defs:
		nests.append(_make_nest(d))


func enemies() -> Array:
	var out := []
	for n in nests:
		if not n.alive:
			continue
		for part in n.parts:
			var p: Dictionary = part
			if p.alive and str(p.kind) != "core":
				out.append(p.enemy)
	for r in raiders.list:
		out.append(r.enemy)
	for n in nests:
		for item in n.get("mortars", []):
			var m: Dictionary = item
			if m.alive:
				out.append(m.enemy)
	return out


func alive_count() -> int:
	return nests.filter(func(n): return n.alive).size()


func minutes() -> float:
	return time / 60.0


func pressure() -> float:
	return Pressure.value(level, time)


func spawn_interval() -> float:
	return lerpf(Config.NEST_SPAWN_START, Config.NEST_SPAWN_MIN, pressure())


func capacity() -> int:
	return clampi(roundi(lerpf(float(Config.NEST_CAP_START), float(Config.NEST_CAP_MAX), pressure())),
		Config.NEST_CAP_START, Config.NEST_CAP_MAX)


## Seconds until the next spawn. More grown pits, shorter wait. No pits: never.
func spawn_wait(n: Dictionary) -> float:
	return _wait(n, not raiding or _guards(n) < Config.NEST_GUARDS)


func _make_nest(d: Dictionary) -> Dictionary:
	var nest := { "name": d.name, "x": int(d.x), "z": int(d.z), "alive": true,
		"timer": randf() * 4.0, "count": 0, "rate": float(d.get("rate", 1.0)) }
	Hives.bind(self, nest, d)
	var pos: Vector3 = nest.pos
	world.markers.append({ "pos": pos + Vector3(0, 2.5, 0), "color": Color("a8ff5a"), "minor": true,
		"label": func(): return "Spore Nest (breeding %ss)" % RaiderDefs.newest(pressure()).name,
		"visible": func(): return nest.alive })
	return nest


func pick_tier() -> Dictionary:
	return RaiderDefs.pick(pressure())


func _escalate() -> void:
	if alive_count() == 0:
		return
	if not raiding and time >= _raid_delay():
		raiding = true
		for n in nests:
			var g := raiders.list.filter(func(r): return r.nest == n and r.guard)
			for i in range(Config.NEST_GUARDS, g.size()):
				g[i].guard = false
		Bus.say("Spore Nests are sending raiders at your base. Snipers and units can stop them.", "bad")
	if time >= _tier_time(tier + 1):
		tier += 1
		Sfx.play("alarm")
		Bus.say("The nests have grown: they now breed %ss. Kill them before it gets worse." % RaiderDefs.newest(pressure()).name, "bad")


func update(dt: float) -> void:
	time += dt
	_escalate()
	_overrun(dt)
	for n in nests:
		Hives.tick(self, n, dt)
		if not n.alive:
			continue
		var sac := n.node.get_node("Sac") as Node3D
		var growth: float = 1.0 + minutes() * 0.1
		sac.scale = sac.scale.lerp(Vector3.ONE * growth * (1.0 + 0.08 * sin(time * 3.0 + n.x)), 0.2)
		n.timer += dt
		try_spawn(n)
	EnemyMortars.tick(self, dt)
	flyers.update(dt)
	raiders.update(dt, prey.call(), goal_cells.call())


## One spawn wave if the nest's timer is due. Returns how many raiders appeared.
func try_spawn(n: Dictionary) -> int:
	if not n.alive:
		return 0
	var guard := not raiding or _guards(n) < Config.NEST_GUARDS
	var ch := Hives.channels(n)
	if ch <= 0:
		return 0
	var batch := 1
	var cap := capacity() * ch
	if not guard and pressure() >= Config.GROUP_PRESSURE:
		var room: int = mini(cap - int(n.count), Config.RAIDER_MAX_TOTAL - raiders.list.size())
		batch = maxi(1, mini(RaiderGroups.size_for(pressure()), maxi(room, 1)))
	if float(n.timer) < _wait(n, guard) or int(n.count) >= cap or raiders.list.size() >= Config.RAIDER_MAX_TOTAL:
		return 0
	n.timer = 0.0
	var before := raiders.list.size()
	if batch > 1:
		RaiderGroups.spawn(raiders, n, RaiderGroups.compose(batch, pressure(), int(n.x) + int(time)))
	else:
		raiders.spawn(n, pick_tier(), guard)
	var spawned := raiders.list.size() - before
	if spawned > 0:
		_spawn_attack(n)
	return spawned


## The core pulses and a grown pit heaves when the nest breeds (models only).
static func _spawn_attack(n: Dictionary) -> void:
	var core := Hives.find(n, "core")
	if not core.is_empty():
		HiveParts.attack_anim(core)
	var pits := []
	for part in n.parts:
		var p: Dictionary = part
		if p.alive and p.grown and str(p.kind) == "pit":
			pits.append(p)
	if not pits.is_empty():
		var pit: Dictionary = pits[randi() % pits.size()]
		HiveParts.attack_anim(pit)


func _wait(n: Dictionary, guard: bool) -> float:
	var ch := Hives.channels(n)
	if ch <= 0:
		return INF
	var batch := 1
	if not guard and pressure() >= Config.GROUP_PRESSURE:
		batch = RaiderGroups.size_for(pressure())
	return spawn_interval() / float(n.get("rate", 1.0)) / float(ch) * float(batch if batch > 1 else 1)


func _overrun(dt: float) -> void:
	if pressure() < 1.0 or alive_count() == 0:
		overrun_t = 0.0
		return
	overrun_t += dt
	if overrun_t < Config.OVERRUN_INTERVAL:
		return
	overrun_t = 0.0
	var dest: Vector3 = node_pos.call()
	var wave := Config.OVERRUN_BASE + Config.OVERRUN_PER_TIER * Pressure.legacy_tier(pressure())
	for n in nests:
		if not n.alive:
			continue
		for _i in wave:
			if raiders.list.size() >= Config.RAIDER_MAX_TOTAL:
				return
			raiders.spawn(n, pick_tier(), false)
			var r: Dictionary = raiders.list.back()
			r.guard = false
			r["overrun"] = true
			r["rush"] = dest
	Bus.say("The nests overrun: a wave is marching straight at the Command Node.", "bad")


func on_lance(ats: Array) -> void:
	HiveParts.lance(self, ats)


func state() -> Dictionary:
	var rows: Array = []
	for n in nests:
		rows.append(Hives.pack(n))
	return { "time": time, "tier": tier, "raiding": raiding, "overrun_t": overrun_t, "hives": rows, "flyers": flyers.state() }


func load_state(d: Dictionary) -> void:
	time = float(d.time)
	tier = int(d.tier)
	raiding = bool(d.raiding)
	overrun_t = float(d.overrun_t)
	flyers.load_state(d.get("flyers", []))
	for row in d.hives:
		var src: Dictionary = row
		for n in nests:
			if str(n.name) == str(src.name):
				Hives.unpack(self, n, src)


func _guards(n: Dictionary) -> int:
	return raiders.list.filter(func(r): return r.nest == n and r.guard).size()


func _raid_delay() -> float:
	return float(schedule.get("raid_delay", Config.NEST_RAID_DELAY))


func _tier_time(i: int) -> float:
	var times: Array = schedule.get("tier_times", Config.RAIDER_TIER_TIMES)
	if i < 0 or i >= times.size():
		return INF
	return float(times[i])
