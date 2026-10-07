class_name SporeNests
extends RefCounted
## Spore Nests: surface spawners in Blight zones (where turrets can't be built). They breed
## ground Raiders (raiders.gd) and grow stronger the longer the mission runs: they spawn
## faster, hold more, toughen up, and breed higher Config.RAIDER_TIERS over time. The first
## NEST_GUARDS of each nest stay home; after the level's raid_delay the rest march.
## That is the clock: kill the nests early or face Behemoths later.
## Nests die to unit fire or the Operative. Snipers kill raiders. Beams are surface-to-air and burn flying enemies.

var world: World
var nests: Array[Dictionary] = []
var raiders: Raiders
var prey := func() -> Array: return []        # injected by Game: [{ node, radius, alive, hit }]
var goal_cells := func() -> Array: return []  # injected by Game: cells of grounded structures
var time := 0.0
var tier := 0       # highest unlocked tier index
var raiding := false
var schedule: Dictionary = {}  # level RAID_SCHEDULE; empty falls back to Config


func _init(w: World, defs: Array, sched: Dictionary = {}) -> void:
	world = w
	schedule = sched
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


## Growth curves, all driven by mission time.
func minutes() -> float:
	return time / 60.0


func spawn_interval() -> float:
	return maxf(Config.NEST_SPAWN_MIN, Config.NEST_SPAWN_START * pow(Config.NEST_SPAWN_RAMP, minutes()))


func capacity() -> int:
	return mini(Config.NEST_CAP_MAX, Config.NEST_CAP_START + floori(minutes() * Config.NEST_CAP_PER_MIN))


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
		"label": func(): return "Spore Nest (breeding %ss)" % Config.RAIDER_TIERS[tier].name,
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


## Newest unlocked tier half the time, otherwise any lower one.
func pick_tier() -> Dictionary:
	var i := tier if randf() < 0.5 else randi_range(0, tier)
	return Config.RAIDER_TIERS[i]


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
	var tiers: Array = Config.RAIDER_TIERS
	if tier + 1 < tiers.size() and time >= _tier_time(tier + 1):
		tier += 1
		Sfx.play("alarm")
		Bus.say("The nests have grown: they now breed %ss. Kill them before it gets worse." % tiers[tier].name, "bad")


func update(dt: float) -> void:
	time += dt
	_escalate()
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
		if n.timer >= interval and n.count < cap and raiders.list.size() < Config.RAIDER_MAX_TOTAL:
			n.timer = 0.0
			var guard: bool = not raiding or _guards(n) < Config.NEST_GUARDS
			raiders.spawn(n, pick_tier(), guard)
	raiders.update(dt, prey.call(), goal_cells.call())


func _guards(n: Dictionary) -> int:
	return raiders.list.filter(func(r): return r.nest == n and r.guard).size()


func _raid_delay() -> float:
	return float(schedule.get("raid_delay", Config.NEST_RAID_DELAY))


func _tier_time(i: int) -> float:
	var times: Array = schedule.get("tier_times", Config.RAIDER_TIER_TIMES)
	if i < 0 or i >= times.size():
		return INF
	return float(times[i])
