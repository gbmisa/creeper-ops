class_name Hives
## Hive state (§3.3): active, razed, outpost. Stage follows pressure. New parts grow in and
## can be killed while small. Rebuilding and Blight live in HiveSite.


const BY_STAGE := [
	["core", "pit_a"],
	["pit_b", "spitter_a"],
	["launcher", "spitter_b"],
	["pit_c"],
	["mortar"],
]


static func stage_for(p: float) -> int:
	if p >= Config.HIVE_P4:
		return 4
	if p >= Config.HIVE_P3:
		return 3
	if p >= Config.HIVE_P2:
		return 2
	if p >= Config.HIVE_P1:
		return 1
	return 0


static func channels(hive: Dictionary) -> int:
	var n := 0
	for part in hive.parts:
		var p: Dictionary = part
		if p.alive and p.grown and str(p.kind) == "pit":
			n += 1
	return n


static func find(hive: Dictionary, kind: String) -> Dictionary:
	for part in hive.parts:
		var p: Dictionary = part
		if p.alive and str(p.kind) == kind:
			return p
	return {}


static func base_hp(host, hive: Dictionary, kind: String) -> float:
	if kind == "core":
		return Config.HIVE_CORE_BASE + Config.HIVE_CORE_PER_P * host.pressure()
	if kind == "pit":
		return Config.HIVE_PIT_HP
	if kind == "spitter":
		return Config.HIVE_SPITTER_HP
	if kind == "launcher":
		return Config.HIVE_LAUNCHER_HP
	if kind == "roost":
		return Config.FLYER_ROOST_HP
	return Config.HIVE_MORTAR_HP


static func bind(host, hive: Dictionary, d: Dictionary) -> void:
	var spec := d
	if not d.has("slots"):
		spec = HiveShape.cells(host.world.grid, int(hive.x), int(hive.z))
	hive["blight"] = (spec.blight as Array).duplicate()
	hive["slots"] = (spec.slots as Dictionary).duplicate()
	hive["floor"] = float(spec.floor)
	hive["berm"] = int(spec.get("raised", 0))
	hive["sample"] = spec.get("sample", Vector2i(-1, -1))
	hive["stage"] = 0
	hive["state"] = "active"
	hive["parts"] = []
	hive["rebuild_t"] = 0.0
	hive["boosted"] = false
	HiveSite.anchor(host, hive)
	HiveSite.zone(host, hive, true)
	unlock_to(host, hive, 0)


static func sync(host, hive: Dictionary) -> void:
	if str(hive.state) != "active":
		return
	unlock_to(host, hive, stage_for(host.pressure()))
	EnemyMortars.reconcile(host, hive)


static func unlock_to(host, hive: Dictionary, want: int) -> void:
	var have: Array = hive.parts
	if want > int(hive.stage) or have.is_empty():
		var start := 0 if have.is_empty() else int(hive.stage) + 1
		if want < int(hive.stage):
			_drop(host, hive, want)
		else:
			for s in range(start, want + 1):
				_add(host, hive, s, s == 0 and start == 0)
			hive.stage = want
	elif want < int(hive.stage):
		_drop(host, hive, want)
	_boost(hive)
	_caps(host, hive)


static func _add(host, hive: Dictionary, stage: int, grown: bool) -> void:
	var ids: Array = BY_STAGE[stage]
	for id in ids:
		if str(id) == "mortar":
			continue  # EnemyMortars builds the body. Stage 4 still grants the HP bonus.
		if not _id(hive, str(id)).is_empty():
			continue
		HiveParts.spawn(host, hive, str(id), stage, grown)


static func _id(hive: Dictionary, id: String) -> Dictionary:
	for part in hive.parts:
		var p: Dictionary = part
		if str(p.id) == id:
			return p
	return {}


static func _drop(host, hive: Dictionary, want: int) -> void:
	if want < 4 and bool(hive.boosted):
		for part in hive.parts:
			var p: Dictionary = part
			if int(p.stage) <= want and p.alive:
				p.hp = float(p.hp) / Config.HIVE_STAGE4_HP
		hive.boosted = false
	var keep: Array = []
	for part in hive.parts:
		var p: Dictionary = part
		if int(p.stage) <= want:
			keep.append(p)
		else:
			HiveParts.forget(host.world, p)
	hive.parts = keep
	hive.stage = want


static func _boost(hive: Dictionary) -> void:
	if int(hive.stage) < 4 or bool(hive.boosted):
		return
	hive.boosted = true
	hive["fresh_boost"] = true


static func _caps(host, hive: Dictionary) -> void:
	var mul := Config.HIVE_STAGE4_HP if int(hive.stage) >= 4 else 1.0
	var fresh := bool(hive.get("fresh_boost", false))
	hive["fresh_boost"] = false
	for part in hive.parts:
		var p: Dictionary = part
		if not p.alive:
			continue
		var old_max := float(p.max_hp)
		var full := float(p.hp) >= old_max - 0.01
		p.max_hp = base_hp(host, hive, str(p.kind)) * mul
		if full:
			p.hp = p.max_hp
		elif fresh:
			p.hp = float(p.hp) * Config.HIVE_STAGE4_HP
		if str(p.kind) == "core":
			hive.hp = p.hp


static func tick(host, hive: Dictionary, dt: float) -> void:
	if str(hive.state) == "active":
		# Bookkeeping (stage unlocks, HP caps, mortar count) only changes with pressure or damage,
		# so it runs every HIVE_SYNC_INTERVAL; growth and combat run every frame.
		hive["sync_t"] = float(hive.get("sync_t", 0.0)) - dt
		if float(hive.sync_t) <= 0.0:
			hive.sync_t = Config.HIVE_SYNC_INTERVAL
			sync(host, hive)
			FlyerLaunch.sync(host, hive)
			_boost(hive)
			_caps(host, hive)
		age(hive, dt)
		HiveParts.combat(host, hive, dt)
	else:
		HiveSite.tick(host, hive, dt)


static func age(hive: Dictionary, dt: float) -> void:
	for part in hive.parts:
		var p: Dictionary = part
		if not p.alive or p.grown:
			continue
		p.grow = float(p.grow) - dt
		var k := 1.0 - clampf(float(p.grow) / Config.HIVE_GROW, 0.0, 1.0)
		var node := p.get("node") as Node3D
		if node != null and is_instance_valid(node):
			node.scale = Vector3.ONE * lerpf(0.15, 1.0, k)
		if float(p.grow) <= 0.0:
			p.grown = true
			p.grow = 0.0
			if node != null and is_instance_valid(node):
				node.scale = Vector3.ONE


static func raze(host, hive: Dictionary) -> void:
	if str(hive.state) != "active":
		return
	hive.state = "razed"
	hive.alive = false
	for part in (hive.parts as Array).duplicate():
		HiveParts.forget(host.world, part)
	hive.parts = []
	EnemyMortars.reconcile(host, hive)
	HiveSite.drop_anchor(hive)
	HiveSite.zone(host, hive, false)
	Loot.drop(host.world, hive.pos, Config.HIVE_SALVAGE, host.stockpile, host.operative)
	host.world.effects.burst(hive.pos + Vector3.UP, Color("a8ff5a"), 6.0, 0.8)
	Sfx.play("boom", hive.pos)
	Bus.say("Hive razed: %s. The Blight clears." % str(hive.name), "good")
	Bus.nest_destroyed.emit(hive)
	if host.alive_count() == 0:
		Bus.objective_done.emit("nests")


static func pack(hive: Dictionary) -> Dictionary:
	var parts: Array = []
	for part in hive.parts:
		var p: Dictionary = part
		parts.append({
			"id": p.id, "kind": p.kind, "stage": p.stage, "x": p.x, "z": p.z,
			"hp": p.hp, "max_hp": p.max_hp, "alive": p.alive, "grown": p.grown, "grow": p.grow,
		})
	return {
		"name": hive.name, "state": hive.state, "stage": hive.stage, "alive": hive.alive,
		"hp": hive.hp, "rebuild_t": hive.rebuild_t, "timer": hive.timer,
		"boosted": hive.get("boosted", false), "parts": parts,
	}


static func unpack(host, hive: Dictionary, data: Dictionary) -> void:
	for part in (hive.parts as Array).duplicate():
		HiveParts.forget(host.world, part)
	hive.parts = []
	EnemyMortars.clear(host, hive)
	HiveSite.drop_anchor(hive)
	hive.state = str(data.state)
	hive.stage = int(data.stage)
	hive.alive = bool(data.alive)
	hive.hp = float(data.hp)
	hive.rebuild_t = float(data.rebuild_t)
	hive.timer = float(data.timer)
	hive.boosted = bool(data.get("boosted", false))
	if not hive.alive:
		HiveSite.zone(host, hive, false)
		return
	HiveSite.anchor(host, hive)
	HiveSite.zone(host, hive, true)
	for row in data.parts:
		var src: Dictionary = row
		if bool(src.alive):
			HiveParts.restore(host, hive, src)
