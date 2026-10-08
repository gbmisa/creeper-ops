class_name EnemyMortarFire
## Targeting, the telegraph, and the terrain-shader ring for an enemy mortar (§4.3).
## A Spotter's line of sight is the only way onto the Operative.
## The operative HUD shows SPOTTED while a mortar has them. The log line stays too.


static var extra: Array = []  # other telegraph rings this frame (castle trebuchets), Vector4(x, z, r, 1)


static func volley(host, hive: Dictionary, dt: float) -> void:
	for item in hive.get("mortars", []):
		var m: Dictionary = item
		if not m.alive or not m.grown:
			continue
		if m.telegraph != null:
			advance(host, m, dt)
			continue
		m.cd = float(m.cd) - dt
		var picked := aim(host, m)
		var op := str(picked.get("kind", "")) == "operative"
		if op and not bool(m.spotted):
			Bus.say("SPOTTED", "bad")
		m.spotted = op
		if float(m.cd) > 0.0 or picked.is_empty():
			if float(m.cd) < 0.0:
				m.cd = 0.0
			continue
		var node := picked.node as Node3D
		m.cd = Config.MORTAR_INTERVAL
		m.telegraph = { "at": node.position, "t": 0.0, "whistled": false }
		Sfx.play("thump", m.pos)
		advance(host, m, 0.0)


static func advance(host, m: Dictionary, dt: float) -> void:
	var shot: Dictionary = m.telegraph
	shot.t = float(shot.t) + dt
	if float(shot.t) >= Config.MORTAR_TELEGRAPH - Config.MORTAR_WHISTLE and not bool(shot.whistled):
		shot.whistled = true
		Sfx.play("whistle", shot.at)
	if float(shot.t) < Config.MORTAR_TELEGRAPH:
		return
	var at: Vector3 = shot.at
	m.telegraph = null
	EnemyMortarHit.detonate(host, at)


static func aim(host, m: Dictionary) -> Dictionary:
	var from: Vector3 = m.pos
	var best: Dictionary = {}
	var score := -1
	var nearest := INF
	for q in host.prey.call():
		var prey: Dictionary = q
		if not prey.alive.call():
			continue
		var node := prey.node as Node3D
		var cells := Vector2(node.position.x - from.x, node.position.z - from.z).length() / Config.CELL
		if cells < Config.MORTAR_MIN_RANGE or cells > Config.MORTAR_RANGE:
			continue
		var kind := str(prey.get("kind", ""))
		var band := 1
		if kind == "unit":
			continue
		if kind == "operative":
			if not sees(host, m, node.position):
				continue
			band = 3
		elif bool(prey.get("weapon", false)) or str(prey.get("type", "")) == "terp":
			band = 2
		if band > score or (band == score and cells < nearest):
			score = band
			nearest = cells
			best = prey
	return best


static func sees(host, m: Dictionary, at: Vector3) -> bool:
	for item in host.raiders.list:
		var r: Dictionary = item
		if not r.alive or str(r.get("mid", "")) != str(m.mid):
			continue
		if str((r.tier as Dictionary).get("special", "")) != "spotter":
			continue
		var eye: Vector3 = (r.node as Node3D).position + Vector3.UP * 1.2
		var chest := at + Vector3.UP * 1.2
		var dist := eye.distance_to(chest)
		if dist > Config.MORTAR_SIGHT or dist < 0.05:
			continue
		var hit: Variant = host.world.grid.raycast(eye, (chest - eye).normalized(), dist)
		if hit == null or eye.distance_to(hit as Vector3) > dist - 0.75:
			return true
	return false


static func watch(host, hive: Dictionary, dt: float) -> void:
	var feet: Variant = _feet(host)
	for item in hive.get("mortars", []):
		var m: Dictionary = item
		if feet == null:
			if float(m.get("channel", 0.0)) > 0.0:
				m.channel = 0.0
			continue
		EnemyMortars.sabotage(host, m, feet as Vector3, dt)


static func spotter(host, m: Dictionary) -> void:
	var hive: Dictionary = m.hive
	host.raiders.spawn(hive, RaiderDefs.named("Spotter"), true)
	var r: Dictionary = host.raiders.list.back()
	r.guard = true
	r["post"] = m.pos
	r["mid"] = m.mid
	(r.node as Node3D).position = m.pos + Vector3(2.2, 0, 0)
	m.spotter = r
	m.spotter_t = 0.0


static func shells(host) -> void:
	var mat: ShaderMaterial = host.world.terrain_mat
	if mat == null:
		return
	var packed := PackedVector4Array()
	packed.resize(8)
	var i := 0
	var blast := Config.MORTAR_BLAST * Config.CELL
	for n in host.nests:
		var hive: Dictionary = n
		for item in hive.get("mortars", []):
			var m: Dictionary = item
			if m.telegraph == null or i >= 8:
				continue
			var shot: Dictionary = m.telegraph
			var k := clampf(float(shot.t) / Config.MORTAR_TELEGRAPH, 0.0, 1.0)
			var at: Vector3 = shot.at
			packed[i] = Vector4(at.x, at.z, lerpf(0.6, blast, k), 1.0)
			i += 1
	for item in host.hub_mortars:
		var hub_m: Dictionary = item
		if hub_m.telegraph == null or i >= 8:
			continue
		var hub_shot: Dictionary = hub_m.telegraph
		var hk := clampf(float(hub_shot.t) / Config.MORTAR_TELEGRAPH, 0.0, 1.0)
		var hat: Vector3 = hub_shot.at
		packed[i] = Vector4(hat.x, hat.z, lerpf(0.6, blast, hk), 1.0)
		i += 1
	for v in extra:
		if i < 8:
			packed[i] = v
			i += 1
	mat.set_shader_parameter("shells", packed)


static func any_spotted(host) -> bool:
	for n in host.nests:
		var hive: Dictionary = n
		for item in hive.get("mortars", []):
			var m: Dictionary = item
			if m.alive and bool(m.spotted):
				return true
	return false


static func _feet(host) -> Variant:
	if host.operative == null:
		return null
	var fps := host.operative.call() as FpsMode
	if fps == null or fps.world == null:
		return null
	return fps.controller.pos
