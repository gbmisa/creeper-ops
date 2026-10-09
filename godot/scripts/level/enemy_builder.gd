class_name EnemyBuilder
extends RefCounted
## Enemy construction (§4.5). Weavers grow a site; losing the castle freezes it. `hold` pauses the planner.

var world: World
var castles: Strongholds
var nests: SporeNests
var structures: StructureManager
var stockpile: Stockpile
var list: Array = []
var queue: Array = []
var weavers: Array = []
var mortars: Array = []
var hold := false
var time := 0.0
var _seq := 1
var _cool := {}


func _init(w: World, cs: Strongholds, sn: SporeNests, sm: StructureManager, pile: Stockpile) -> void:
	world = w
	castles = cs
	nests = sn
	structures = sm
	stockpile = pile
	w.updaters.append(update)
	Bus.terrain_changed.connect(_on_terrain)


## Terrain edits (enemy mortars, hive growth, burrowers, breaches) skip only
## player-occupied cells, so the ground can move under an enemy structure after it is
## placed. Re-seat anything whose cell changed so it stands on the visible ground.
func _on_terrain(w: World, cells: Array) -> void:
	if w != world:
		return
	var touched := {}
	for c in cells:
		touched[c] = true
	for raw in list:
		var s: Dictionary = raw
		if not bool(s.alive):
			continue
		if not touched.has(s.cell):
			continue
		var p := world.grid.cell_ground(s.cell.x, s.cell.y)
		var node := s.node as Node3D
		if node != null and is_instance_valid(node):
			node.position = p
		s.pos = p


func update(dt: float) -> void:
	time += dt
	EnemyBuildWork.income(self, dt)
	if not hold:
		EnemyBuildWork.plan(self, dt)
	EnemyBuildCrew.weavers(self, dt)
	EnemyBuildWork.progress(self, dt)
	EnemyBuildFight.tick(self, dt)
	EnemyBuildCrew.sabotage(self, dt)


func shields(cell: Vector2i) -> bool:
	var radius := float(EnemyStructures.DEFS["dome"].radius)
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and bool(s.grown) and str(s.kind) == "dome" and (s.cell as Vector2i).distance_to(cell) <= radius:
			return true
	return false


func blocks(x: int, z: int) -> bool:
	var radius := float(EnemyStructures.DEFS["pylon"].radius)
	var at := Vector2i(x, z)
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and bool(s.grown) and str(s.kind) == "pylon" and (s.cell as Vector2i).distance_to(at) <= radius:
			return true
	return false


func occupies(x: int, z: int) -> bool:
	var at := Vector2i(x, z)
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and s.cell == at:
			return true
	for raw in queue:
		if raw.cell == at:
			return true
	return false


func lance_scale(at: Vector3) -> float:
	var cell := world.grid.world_to_cell(at.x, at.z)
	if shields(cell):
		return float(EnemyStructures.DEFS["dome"].lance)
	return 1.0

func on_lance(at: Vector3) -> void:
	var reach := Config.LANCE_RADIUS * Config.CELL
	var scale := lance_scale(at)
	for raw in list.duplicate():
		var s: Dictionary = raw
		if bool(s.alive) and Vector2(s.pos.x - at.x, s.pos.z - at.z).length() <= reach:
			hurt(s, Config.HIVE_LANCE_DMG * scale)

func splash(at: Vector3, reach: float, dmg: float) -> void:
	for raw in list.duplicate():
		var s: Dictionary = raw
		if bool(s.alive) and Vector2(s.pos.x - at.x, s.pos.z - at.z).length() <= reach:
			hurt(s, dmg)


func nullify(x: int, z: int) -> bool:
	for raw in list.duplicate():
		var s: Dictionary = raw
		if bool(s.alive) and str(s.kind) == "pump" and Vector2(s.cell.x - x, s.cell.y - z).length() <= Config.NULLIFY_RANGE:
			kill(s, false)
			Bus.say("Creeper Pump nullified.", "good")
			return true
	return false

func pump_near(x: int, z: int) -> bool:
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and str(s.kind) == "pump" and Vector2(s.cell.x - x, s.cell.y - z).length() <= Config.NULLIFY_RANGE:
			return true
	return false


func enemies() -> Array:
	var out: Array = []
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive):
			out.append(s.enemy)
	return out


func snipe_foes() -> Array:
	var out: Array = []
	for raw in weavers:
		var w: Dictionary = raw
		if bool(w.alive):
			out.append(w)
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive):
			out.append(s)
	return out


func leech_count() -> int:
	var n := 0
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and bool(s.grown) and str(s.kind) == "leech" and not denied(s.cell):
			n += 1
	return n

func leech_at(cell: Vector2i) -> bool:
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and str(s.kind) == "leech" and s.cell == cell:
			return true
	return false

func denied(cell: Vector2i) -> bool:
	var s := structures.structure_at(cell.x, cell.y)
	return s != null and not s.dead and s.type == "miner"


func has(hub_id: String, kind: String) -> bool:
	if count_kind(hub_id, kind) > 0:
		return true
	for raw in queue:
		if str(raw.hub) == hub_id and str(raw.kind) == kind:
			return true
	return false


func count_kind(hub_id: String, kind: String) -> int:
	var n := 0
	for raw in list:
		var s: Dictionary = raw
		if bool(s.alive) and str(s.hub) == hub_id and str(s.kind) == kind:
			n += 1
	return n


func castle(hub_id: String) -> Dictionary:
	for raw in castles.list:
		var c: Dictionary = raw
		if str(c.id) == hub_id:
			return c
	return {}

func hurt(s: Dictionary, dmg: float) -> void:
	if not bool(s.alive):
		return
	s.hp = float(s.hp) - dmg
	if float(s.hp) <= 0.0:
		kill(s, false)


func kill(s: Dictionary, sabotage: bool) -> void:
	if not bool(s.get("alive", false)):
		return
	s.alive = false
	s.channel = 0.0
	EnemyBuildCrew.drop(self, int(s.id))
	EnemyBuildFight.stop_mortar(self, s)
	EnemyBuildCrew.unpaint(self, s)
	if s.has("target"):
		world.remove_target(s.target)
	if s.has("interact"):
		world.interactables.erase(s.interact)
	if s.has("marker"):
		world.markers.erase(s.marker)
	var node := s.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.queue_free()
	s.node = null
	if not sabotage:
		var def: Dictionary = EnemyStructures.DEFS[s.kind]
		queue.append({"hub": s.hub, "kind": s.kind, "cell": s.cell, "rubble": true, "cost": float(def.cost) * 0.5})
	list.erase(s)
	world.effects.burst(s.pos + Vector3.UP, Color("c45cff"), 2.2, 0.4)


func begin(c: Dictionary, kind: String, cell: Vector2i, rubble: bool, cost: float) -> Dictionary:
	var def: Dictionary = EnemyStructures.DEFS[kind]
	var use := float(def.cost) * (0.5 if rubble else 1.0)
	if cost > 0.0:
		use = cost
	var node := EnemyStructures.mesh(kind)
	var pos := world.place_at(node, cell.x, cell.y)
	node.scale = Vector3.ONE * 0.25
	var s := {
		"id": _seq, "kind": kind, "hub": c.id, "cell": cell, "pos": pos, "node": node,
		"hp": float(def.hp), "max_hp": float(def.hp), "alive": true, "grown": false, "rubble": rubble,
		"progress": 0.0, "cost": use, "born": time, "channel": 0.0, "cd": 0.0, "charge": 0.0,
		"wait": Config.ENEMY_WEAVER_RESPAWN, "painted": [], "mortar": {},
	}
	_seq += 1
	EnemyBuildCrew.arm(self, s, str(def.label))
	list.append(s)
	Bus.say("%s is raising a %s." % [str(c.name), str(def.label)], "warn")
	return s

func clear() -> void:
	queue.clear()
	for raw in list.duplicate():
		kill(raw, true)
	for raw in weavers.duplicate():
		EnemyBuildCrew.remove(self, raw)


func apply_channel(s: Dictionary, feet: Vector3, dt: float) -> bool:
	if not bool(s.alive) or float(s.channel) <= 0.0:
		return false
	if Vector2(feet.x - s.pos.x, feet.z - s.pos.z).length() > Config.MORTAR_SABOTAGE_RANGE:
		s.channel = 0.0
		Bus.say("Sabotage interrupted: you moved away from the %s." % EnemyStructures.DEFS[s.kind].label, "warn")
		return false
	s.channel = float(s.channel) - dt
	if float(s.channel) > 0.0:
		return false
	if stockpile != null:
		stockpile.add("salvage", Config.MORTAR_SALVAGE)
	kill(s, true)
	Bus.say("Sabotaged the %s. +%d Salvage." % [EnemyStructures.DEFS[s.kind].label, int(Config.MORTAR_SALVAGE)], "good")
	return true
