class_name SporeNests
extends RefCounted
## Spore Nests: surface spawners in Blight zones (where turrets can't be built). They breed
## ground Raiders (raiders.gd) and grow stronger the longer the mission runs: they spawn
## faster, hold more, and breed higher RaiderDefs rows as pressure rises. The first
## NEST_GUARDS of each nest stay home; after the level's raid_delay the rest march.
## That is the clock: kill the nests early or face Behemoths later.
## Nests die to unit fire or the Operative. Snipers kill raiders. Beams are surface-to-air and burn flying enemies.

var world: World
var nests: Array[Dictionary] = []
var raiders: Raiders
var prey := func() -> Array: return []        # injected by Game: [{ node, radius, alive, hit }]
var goal_cells := func() -> Array: return []  # injected by Game: cells of grounded structures
var time := 0.0
var tier := 0       # highest unlocked tier index (RAID_SCHEDULE; spawning stays on this until 8b)
var raiding := false
var schedule: Dictionary = {}  # level RAID_SCHEDULE; empty falls back to Config
var level: Dictionary = {}     # for Pressure.value
var overrun_t := 0.0
## Where overrun waves walk. Game injects the Command Node; tests can override it.
var node_pos := func() -> Vector3: return Vector3.ZERO
## nest.rate (default 1) speeds a nest's spawns; CastleRaids raises it near enemy castles.


func _init(w: World, defs: Array, sched: Dictionary = {}, lvl: Dictionary = {}) -> void:
	world = w
	schedule = sched
	level = lvl
	raiders = Raiders.new(w)
	for d in defs:
		nests.append(_make_nest(d))


## Everything units should shoot at: { node, oy, radius, alive, hit }.
func enemies() -> Array:
	var out := []
	for n in nests:
		if n.alive:
			out.append(n.enemy)
	for r in raiders.list:
		out.append(r.enemy)
	return out


func alive_count() -> int:
	return nests.filter(func(n): return n.alive).size()


## Growth curves. Spawn interval and cap read pressure (§4.1); HP growth still uses minutes.
func minutes() -> float:
	return time / 60.0


func pressure() -> float:
	return Pressure.value(level, time)


func spawn_interval() -> float:
	return lerpf(Config.NEST_SPAWN_START, Config.NEST_SPAWN_MIN, pressure())


func capacity() -> int:
	return clampi(roundi(lerpf(float(Config.NEST_CAP_START), float(Config.NEST_CAP_MAX), pressure())),
		Config.NEST_CAP_START, Config.NEST_CAP_MAX)


func _make_nest(d: Dictionary) -> Dictionary:
	var node := HazardMeshes.nest()
	var pos := world.place_at(node, d.x, d.z)
	var nest := { "name": d.name, "x": d.x, "z": d.z, "node": node, "pos": pos, "hp": Config.NEST_HP,
		"alive": true, "timer": randf() * 4.0, "count": 0 }
	var hit := func(dmg: float, _p = null): _hit_nest(nest, dmg)
	nest["enemy"] = { "node": node, "oy": 0.8, "radius": 1.4, "alive": func(): return nest.alive, "hit": hit }
	nest["target"] = { "node": node, "radius": 1.6, "oy": 1.0, "alive": func(): return nest.alive, "on_hit": hit }
	world.add_target(nest.target)
	world.markers.append({ "pos": pos + Vector3(0, 2.5, 0), "color": Color("a8ff5a"), "minor": true,
		"label": func(): return "Spore Nest (breeding %ss)" % RaiderDefs.newest(pressure()).name,
		"visible": func(): return nest.alive })
	return nest


func _hit_nest(nest: Dictionary, dmg: float) -> void:
	if not nest.alive:
		return
	nest.hp -= dmg
	(nest.node.get_node("Sac") as Node3D).scale = Vector3.ONE * 1.25
	if nest.hp > 0.0:
		return
	nest.alive = false
	world.effects.burst(nest.pos + Vector3.UP, Color("a8ff5a"), 6.0, 0.8)
	nest.node.queue_free()
	world.remove_target(nest.target)
	Sfx.play("boom", nest.pos)
	Bus.say("Spore Nest destroyed (%s)." % nest.name, "good")
	Bus.nest_destroyed.emit(nest)
	if alive_count() == 0:
		Bus.objective_done.emit("nests")


## Weighted toward the newest row unlocked at the current pressure (RaiderDefs.pick).
func pick_tier() -> Dictionary:
	return RaiderDefs.pick(pressure())


func _escalate() -> void:
	if alive_count() == 0:
		return
	if not raiding and time >= _raid_delay():
		raiding = true
		for n in nests:  # extra guards bred during the grace period march out now
			var g := raiders.list.filter(func(r): return r.nest == n and r.guard)
			for i in range(Config.NEST_GUARDS, g.size()):
				g[i].guard = false
		Bus.say("Spore Nests are sending raiders at your base. Snipers and units can stop them.", "bad")
	if time >= _tier_time(tier + 1):
		tier += 1  # legacy 0..3 band; castle-raid size and the old smoke still read it
		Sfx.play("alarm")
		Bus.say("The nests have grown: they now breed %ss. Kill them before it gets worse." % RaiderDefs.newest(pressure()).name, "bad")


func update(dt: float) -> void:
	time += dt
	_escalate()
	_overrun(dt)
	var interval := spawn_interval()
	var cap := capacity()
	var growth: float = 1.0 + minutes() * 0.1
	for n in nests:
		if not n.alive:
			continue
		n.hp = minf(Config.NEST_HP * growth, n.hp + Config.NEST_HP * Config.NEST_HP_GROWTH / 60.0 * dt)
		var sac := n.node.get_node("Sac") as Node3D
		sac.scale = sac.scale.lerp(Vector3.ONE * growth * (1.0 + 0.08 * sin(time * 3.0 + n.x)), 0.2)
		n.timer += dt
		var guard: bool = not raiding or _guards(n) < Config.NEST_GUARDS
		var batch := 1
		if not guard and pressure() >= Config.GROUP_PRESSURE:
			var room: int = mini(cap - n.count, Config.RAIDER_MAX_TOTAL - raiders.list.size())
			batch = maxi(1, mini(RaiderGroups.size_for(pressure()), room))
		var wait: float = interval / float(n.get("rate", 1.0)) * float(batch if batch > 1 else 1)
		if n.timer >= wait and n.count < cap and raiders.list.size() < Config.RAIDER_MAX_TOTAL:
			n.timer = 0.0
			if batch > 1:
				RaiderGroups.spawn(raiders, n, RaiderGroups.compose(batch, pressure(), n.x + int(time)))
			else:
				raiders.spawn(n, pick_tier(), guard)
	raiders.update(dt, prey.call(), goal_cells.call())


## At pressure 1, each active nest sends a wave straight at the Node. Ignores guard slots
## and the per-nest cap; still stops at RAIDER_MAX_TOTAL so the sim cannot explode.
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


func _guards(n: Dictionary) -> int:
	return raiders.list.filter(func(r): return r.nest == n and r.guard).size()


func _raid_delay() -> float:
	return float(schedule.get("raid_delay", Config.NEST_RAID_DELAY))


func _tier_time(i: int) -> float:
	var times: Array = schedule.get("tier_times", Config.RAIDER_TIER_TIMES)
	if i < 0 or i >= times.size():
		return INF
	return float(times[i])
