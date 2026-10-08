class_name EnemyMortars
## Enemy mortars (§4.3). Stage 3 builds one, stage 4 a second. Any active hive also builds
## one within 60 s after the Node has had no walking route for 60 s. Each mortar keeps a
## Spotter. A shell is a growing red ring on the terrain shader, then a blast.
## Killed mortars are not rebuilt. Sabotage (hold E, 3 s, within 2 m) pays 5 Salvage.


static func tick(host, dt: float) -> void:
	note_route(host, dt)
	for n in host.nests:
		var hive: Dictionary = n
		reconcile(host, hive)
		_grow(host, hive, dt)
		EnemyMortarFire.volley(host, hive, dt)
		EnemyMortarFire.watch(host, hive, dt)
	EnemyMortarFire.shells(host)


static func note_route(host, dt: float) -> void:
	if _open(host):
		host.seal = 0.0
		host.seal_arm = 0.0
		return
	var before := float(host.seal)
	host.seal = before + dt
	if host.seal < Config.MORTAR_SEAL:
		return
	var was := maxf(0.0, before - Config.MORTAR_SEAL)
	host.seal_arm = float(host.seal_arm) + (host.seal - Config.MORTAR_SEAL - was)


static func reconcile(host, hive: Dictionary) -> void:
	if not hive.has("mortars"):
		hive["mortars"] = []
	if str(hive.state) != "active":
		clear(host, hive)
		return
	var list: Array = hive.mortars
	var need := _want(host, hive)
	while list.size() > need:
		var last: Dictionary = list.back()
		if bool(last.alive) and bool(last.grown):
			break
		_kill(host, last, false)
		list.pop_back()
	_boost(hive, list)
	while list.size() < need:
		list.append(_make(host, hive, list.size()))


static func clear(host, hive: Dictionary) -> void:
	if not hive.has("mortars"):
		hive["mortars"] = []
		return
	for item in hive.mortars:
		_kill(host, item, false)
	hive.mortars = []


static func ready(host, m: Dictionary) -> void:
	m.grown = true
	m.grow = 0.0
	var node := m.node as Node3D
	if node != null and is_instance_valid(node):
		node.scale = Vector3.ONE
	EnemyMortarFire.spotter(host, m)


static func aim(host, m: Dictionary) -> Dictionary:
	return EnemyMortarFire.aim(host, m)


## Hold E started the channel. Returns true the frame the mortar comes down.
static func sabotage(host, m: Dictionary, feet: Vector3, dt: float) -> bool:
	if not m.alive or float(m.channel) <= 0.0:
		return false
	var p: Vector3 = m.pos
	if Vector2(feet.x - p.x, feet.z - p.z).length() > Config.MORTAR_SABOTAGE_RANGE:
		m.channel = 0.0
		return false
	m.channel = float(m.channel) - dt
	if float(m.channel) > 0.0:
		return false
	_kill(host, m, true)
	return true


static func demo(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var hive: Dictionary = nests.nests[0]
	reconcile(nests, hive)
	var m: Dictionary = _make(nests, hive, 0)
	(hive.mortars as Array).append(m)
	var grid: Grid = g.surface.grid
	var pos := grid.cell_ground(48, 30)
	(m.node as Node3D).position = pos
	m.pos = pos
	(m.interact as Dictionary).pos = pos
	ready(nests, m)
	var at := grid.cell_ground(48, 36)
	m.telegraph = { "at": at, "t": 0.4, "whistled": false }
	m.cd = Config.MORTAR_INTERVAL
	EnemyMortarFire.shells(nests)


static func _want(host, hive: Dictionary) -> int:
	var n := 0
	if int(hive.stage) >= 4:
		n = 2
	elif int(hive.stage) >= 3:
		n = 1
	if float(host.seal) >= Config.MORTAR_SEAL and float(host.seal_arm) >= Config.MORTAR_SEAL_BUILD:
		n = maxi(n, 1)
	return n


static func _open(host) -> bool:
	if host.structures == null:
		return true
	var node: Structure = host.structures.command_node()
	if node == null or node.is_flying():
		return true
	var any := false
	for n in host.nests:
		var hive: Dictionary = n
		if str(hive.state) != "active":
			continue
		any = true
		if host.raiders.field.reachable(hive.pos, node.pos, 2.0):
			return true
	return not any


static func _boost(hive: Dictionary, list: Array) -> void:
	if int(hive.stage) < 4:
		return
	for item in list:
		var m: Dictionary = item
		if not m.alive or bool(m.get("boosted", false)):
			continue
		m.boosted = true
		m.max_hp = float(m.max_hp) * Config.HIVE_STAGE4_HP
		m.hp = float(m.hp) * Config.HIVE_STAGE4_HP


static func _make(host, hive: Dictionary, index: int) -> Dictionary:
	var cell := _cell(hive, index)
	var node := HiveMeshes.part("mortar")
	var pos: Vector3 = host.world.place_at(node, cell.x, cell.y)
	var hp := Config.HIVE_MORTAR_HP
	var boosted := int(hive.stage) >= 4
	if boosted:
		hp *= Config.HIVE_STAGE4_HP
	var m := {
		"mid": "%s#%d" % [str(hive.name), index], "hive": hive, "node": node, "pos": pos,
		"alive": true, "grown": false, "grow": Config.HIVE_GROW, "hp": hp, "max_hp": hp,
		"boosted": boosted, "cd": Config.MORTAR_INTERVAL, "telegraph": null, "channel": 0.0,
		"spotted": false, "spotter": {}, "spotter_t": 0.0,
	}
	node.scale = Vector3.ONE * 0.15
	var hit := func(dmg: float, _p = null): _hurt(host, m, dmg)
	m["enemy"] = { "node": node, "oy": 0.9, "radius": 1.1, "alive": func(): return m.alive, "hit": hit }
	m["target"] = { "node": node, "oy": 0.9, "radius": 1.15, "alive": func(): return m.alive, "on_hit": hit }
	host.world.add_target(m.target)
	var it := {
		"pos": pos, "radius": Config.MORTAR_SABOTAGE_RANGE,
		"prompt": func(): return "[E] Sabotage the mortar" if m.alive else "",
		"use": func():
			if m.alive:
				m.channel = Config.MORTAR_SABOTAGE_TIME,
	}
	m["interact"] = it
	host.world.interactables.append(it)
	return m


static func _cell(hive: Dictionary, index: int) -> Vector2i:
	var slots: Dictionary = hive.get("slots", {})
	var core := slots.get("core", Vector2i(int(hive.x), int(hive.z))) as Vector2i
	var first := slots.get("mortar", core + Vector2i(-2, -1)) as Vector2i
	if index <= 0:
		return first
	var mirror := Vector2i(core.x - (first.x - core.x), core.y - (first.y - core.y))
	if mirror == first:
		mirror = core + Vector2i(2, -1)
	return mirror


static func _hurt(host, m: Dictionary, dmg: float) -> void:
	if not m.alive:
		return
	m.hp = float(m.hp) - dmg
	if float(m.hp) <= 0.0:
		_kill(host, m, false)


static func _kill(host, m: Dictionary, pay: bool) -> void:
	if not bool(m.get("alive", false)) and m.get("node") == null:
		return
	m.alive = false
	m.channel = 0.0
	m.telegraph = null
	m.spotted = false
	if pay and host.stockpile != null:
		host.stockpile.add("salvage", Config.MORTAR_SALVAGE)
		host.world.effects.burst(m.pos + Vector3.UP, Color("ff8844"), 2.5, 0.4)
	if m.has("target"):
		host.world.remove_target(m.target)
	if m.has("interact"):
		host.world.interactables.erase(m.interact)
	var node := m.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.queue_free()
	m["node"] = null
	var spot: Dictionary = m.get("spotter", {})
	if not spot.is_empty() and bool(spot.get("alive", false)):
		host.raiders.kill(spot)
	m.spotter = {}


static func _grow(host, hive: Dictionary, dt: float) -> void:
	for item in hive.get("mortars", []):
		var m: Dictionary = item
		if not m.alive or m.grown:
			_spotter_clock(host, m, dt)
			continue
		m.grow = float(m.grow) - dt
		var k := 1.0 - clampf(float(m.grow) / Config.HIVE_GROW, 0.0, 1.0)
		var node := m.node as Node3D
		if node != null and is_instance_valid(node):
			node.scale = Vector3.ONE * lerpf(0.15, 1.0, k)
		if float(m.grow) <= 0.0:
			ready(host, m)


static func _spotter_clock(host, m: Dictionary, dt: float) -> void:
	if not m.alive or not m.grown:
		return
	var spot: Dictionary = m.spotter
	if not spot.is_empty() and bool(spot.get("alive", false)):
		m.spotter_t = 0.0
		return
	m.spotter_t = float(m.spotter_t) + dt
	if float(m.spotter_t) >= Config.MORTAR_SPOTTER_RESPAWN:
		EnemyMortarFire.spotter(host, m)


