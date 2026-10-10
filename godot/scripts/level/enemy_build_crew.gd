class_name EnemyBuildCrew
## Weavers and Operative sabotage for enemy construction (§4.5). One Weaver per
## structure the hub is allowed to grow. Snipers and the Operative can kill a Weaver.


static func weavers(b, dt: float) -> void:
	for raw in b.weavers.duplicate():
		var w: Dictionary = raw
		var job := by_id(b, int(w.sid))
		if job.is_empty() or bool(job.grown) or not enemy(b, str(w.hub)) or not served(b, job):
			remove(b, w)
			continue
		move(b, w, job, dt)
	for raw in b.list:
		var s: Dictionary = raw
		if not bool(s.alive) or bool(s.grown) or not enemy(b, str(s.hub)) or not served(b, s):
			continue
		if weaver_for(b, int(s.id)) != null:
			s.wait = 0.0
			continue
		if float(s.wait) >= Config.ENEMY_WEAVER_RESPAWN:
			s.wait = 0.0
			move(b, send(b, s), s, dt)
		else:
			s.wait = float(s.wait) + dt


static func sabotage(b, dt: float) -> void:
	var feet: Variant = feet_of(b)
	for raw in b.list.duplicate():
		var s: Dictionary = raw
		if float(s.get("channel", 0.0)) <= 0.0:
			continue
		if feet == null:
			s.channel = 0.0
			continue
		b.apply_channel(s, feet as Vector3, dt)


static func send(b, s: Dictionary) -> Dictionary:
	var lay: Dictionary = b.castles.lays[s.hub]
	var home: Vector2i = lay.home
	var node := EnemyStructures.weaver()
	b.world.place_at(node, home.x, home.y)
	var w := {"sid": s.id, "hub": s.hub, "node": node, "hp": EnemyStructures.WEAVER_HP, "alive": true, "onsite": false}
	var hit := func(dmg: float, _p = null) -> void:
		if not bool(w.alive):
			return
		w.hp = float(w.hp) - dmg
		if float(w.hp) <= 0.0:
			EnemyBuildCrew.remove(b, w)
	w["enemy"] = {"node": node, "oy": 0.5, "radius": 0.4, "alive": func() -> bool: return bool(w.alive), "hit": hit}
	w["target"] = {"node": node, "oy": 0.5, "radius": 0.45, "alive": func() -> bool: return bool(w.alive), "on_hit": hit}
	b.world.add_target(w.target)
	b.weavers.append(w)
	return w


static func move(b, w: Dictionary, job: Dictionary, dt: float) -> void:
	var cell: Vector2i = job.cell
	var goal: Vector3 = b.world.grid.cell_ground(cell.x, cell.y)
	var node := w.node as Node3D
	var p := node.position
	var flat := Vector2(goal.x - p.x, goal.z - p.z)
	if flat.length() <= 1.5:
		w.onsite = true
		node.position = Vector3(goal.x, b.world.grid.stand_y(goal.x, goal.z, Grid.Faction.ENEMY), goal.z)
		return
	w.onsite = false
	var step := flat.normalized() * Config.ENEMY_WEAVER_SPEED * dt
	var nxt := slide(b, p, step)
	node.position = Vector3(nxt.x, b.world.grid.stand_y(nxt.x, nxt.y, Grid.Faction.ENEMY), nxt.y)


static func slide(b, p: Vector3, step: Vector2) -> Vector2:
	var grid: Grid = b.world.grid
	var field: RaiderField = b.nests.raiders.field
	var a := grid.world_to_cell(p.x, p.z)
	var try_all := Vector2(p.x + step.x, p.z + step.y)
	var to := grid.world_to_cell(try_all.x, try_all.y)
	if a == to or field.step_ok(a.x, a.y, to.x, to.y):
		return try_all
	var sx := Vector2(p.x + step.x, p.z)
	var bx := grid.world_to_cell(sx.x, sx.y)
	if a == bx or field.step_ok(a.x, a.y, bx.x, bx.y):
		return sx
	var sz := Vector2(p.x, p.z + step.y)
	var bz := grid.world_to_cell(sz.x, sz.y)
	if a == bz or field.step_ok(a.x, a.y, bz.x, bz.y):
		return sz
	return Vector2(p.x, p.z)


static func arm(b, s: Dictionary, label: String) -> void:
	var hit := func(dmg: float, _p = null) -> void:
		b.hurt(s, float(dmg))
	s["enemy"] = {"node": s.node, "oy": 1.0, "radius": 1.0, "alive": func() -> bool: return bool(s.alive), "hit": hit}
	s["target"] = {"node": s.node, "oy": 1.0, "radius": 1.1, "alive": func() -> bool: return bool(s.alive), "on_hit": hit, "max_hp": float(s.max_hp)}
	if EnemyStructures.DEFS.get(str(s.kind), {}).get("no_charge", false):
		s.target["no_charge"] = true  # sabotage only: never offers or needs a demolition charge
	b.world.add_target(s.target)
	var it := {
		"pos": s.pos, "radius": Config.MORTAR_SABOTAGE_RANGE,
		"prompt": func() -> String: return _prompt(s, label),
		"use": func() -> void:
			if bool(s.alive) and float(s.channel) <= 0.0:
				s.channel = Config.MORTAR_SABOTAGE_TIME
				Sfx.play("lift")
				Bus.say("Sabotaging the %s: stay close for %ds — destroys it%s." % [label, ceili(Config.MORTAR_SABOTAGE_TIME), _pay(s)], "info"),
		"channel_frac": func() -> float: return 1.0 - float(s.channel) / Config.MORTAR_SABOTAGE_TIME,
		"channel_what": label,
	}
	if str(s.kind) == "mortar":
		it = DemoCharge.interactable(b.world, s.pos, Config.MORTAR_SABOTAGE_RANGE, func() -> bool: return bool(s.alive), s.target)
		s.target["charge_kill"] = func() -> void: b.kill(s, true)
		var flash := func(_d: float, _p = null) -> void: b.world.effects.burst(s.pos + Vector3.UP, Color("ffcc88"), 0.5, 0.15)
		s.target["on_hit"] = flash  # guns only flash a mortar; a planted charge destroys it
		s.enemy["hit"] = flash
		s.enemy["targetable"] = func(): return false
		s.enemy["immune"] = true  # units must not waste ammo on it (UnitSupply.acquire)
	s["interact"] = it
	b.world.interactables.append(it)
	var marker := {
		"pos": s.pos + Vector3(0, 3.2, 0), "color": EnemyStructures.DEFS[s.kind].color, "minor": true,
		"label": label, "visible": func() -> bool: return bool(s.alive),
	}
	s["marker"] = marker
	b.world.markers.append(marker)


static func _prompt(s: Dictionary, label: String) -> String:
	if not bool(s.alive):
		return ""
	if float(s.channel) > 0.0:
		return "Sabotaging the %s — destroys it%s..." % [label, _pay(s)]
	return "[%s] Sabotage the %s (destroys it%s)" % [Keybinds.short("use"), label, _pay(s)]


## The payout note for a prompt, matching EnemyBuilder's payout ("" when it pays nothing).
static func _pay(s: Dictionary) -> String:
	var def: Dictionary = EnemyStructures.DEFS.get(s.get("kind", ""), {})
	var pay := int(def.get("salvage", Config.MORTAR_SALVAGE))
	return ", +%d Salvage" % pay if pay > 0 else ""


static func onsite(b, s: Dictionary) -> bool:
	for raw in b.weavers:
		var w: Dictionary = raw
		if bool(w.alive) and int(w.sid) == int(s.id) and bool(w.onsite):
			return true
	return false


static func served(b, s: Dictionary) -> bool:
	var mine: Array = []
	for raw in b.list:
		var o: Dictionary = raw
		if bool(o.alive) and not bool(o.grown) and str(o.hub) == str(s.hub):
			mine.append(o)
	mine.sort_custom(func(a: Dictionary, c: Dictionary) -> bool:
		if bool(a.rubble) != bool(c.rubble):
			return bool(a.rubble)
		return float(a.born) < float(c.born))
	var n := mini(EnemyStructures.slots(b.nests.pressure()), mine.size())
	for i in n:
		if int(mine[i].id) == int(s.id):
			return true
	return false


static func unpaint(b, s: Dictionary) -> void:
	var grid: Grid = b.world.grid
	for raw in s.get("painted", []):
		var cell: Vector2i = raw
		if zone_held(b, cell, int(s.id)):
			continue
		var i := grid.idx(cell.x, cell.y)
		if grid.zone[i] == Grid.Zone.BLIGHT:
			grid.zone[i] = Grid.Zone.NONE
	s.painted = []


static func zone_held(b, cell: Vector2i, except_id: int) -> bool:
	for raw in b.list:
		var o: Dictionary = raw
		if int(o.id) == except_id or not bool(o.alive) or str(o.kind) != "pylon":
			continue
		if cell in o.get("painted", []):
			return true
	for raw in b.nests.nests:
		var hive: Dictionary = raw
		if str(hive.get("state", "")) != "active":
			continue
		if cell in hive.get("blight", []):
			return true
	return false


static func enemy(b, hub_id: String) -> bool:
	var c: Dictionary = b.castle(hub_id)
	return not c.is_empty() and str(c.owner) == "enemy"


static func by_id(b, id: int) -> Dictionary:
	for raw in b.list:
		var s: Dictionary = raw
		if int(s.id) == id and bool(s.alive):
			return s
	return {}


static func weaver_for(b, id: int):
	for raw in b.weavers:
		var w: Dictionary = raw
		if bool(w.alive) and int(w.sid) == id:
			return w
	return null


static func drop(b, id: int) -> void:
	for raw in b.weavers.duplicate():
		if int(raw.sid) == id:
			remove(b, raw)


static func remove(b, w: Dictionary) -> void:
	if not bool(w.get("alive", false)) and not b.weavers.has(w):
		return
	w.alive = false
	if w.has("target"):
		b.world.remove_target(w.target)
	var node := w.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.queue_free()
	b.weavers.erase(w)


static func feet_of(b) -> Variant:
	var fps = b.nests.operative.call()
	if fps == null:
		return null
	return fps.controller.pos
