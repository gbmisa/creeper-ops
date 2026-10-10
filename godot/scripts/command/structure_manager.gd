class_name StructureManager
extends Node3D
## Owns every surface structure: lifecycle, occupancy, damage, flight, and the per-frame
## tick. Rules live in Placement / Network / Packets / CollectorField / Mover / WeaponLogic /
## StructureBehaviors / StructureUpkeep (creeper contact, construction, bars).

const DROP_POD_TIME := 3.0

var world: World
var economy: Economy
var stockpile: Stockpile
var deposits: Deposits
var hazards = null            # SurfaceHazards (set by Game)
var enemy_build = null        # EnemyBuilder (set by Game): blight, shields, sniper foes
var list: Array[Structure] = []
var occupied := {}            # grid idx -> Structure
var selected_beacon: Structure = null
var dirty := true
var network: Network
var packets: Packets
var field: CollectorField
var level: Dictionary = {}   # live level dict (unlocks); set by Game


func setup(w: World, eco: Economy) -> void:
	name = "Structures"
	world = w
	economy = eco
	w.occupied = func(x: int, z: int) -> bool: return occupied.has(w.grid.idx(x, z))
	network = Network.new()
	add_child(network)
	packets = Packets.new()
	packets.setup(network, eco)
	add_child(packets)
	field = CollectorField.new(w)


func command_node() -> Structure:
	for s in list:
		if s.type == "node":
			return s
	return null


func beacons() -> Array[Structure]:
	var out: Array[Structure] = []
	for s in list:
		if s.type == "beacon" and s.is_built():
			out.append(s)
	return out


func count_type(type: String) -> int:
	return list.filter(func(s): return s.type == type).size()


# ---- occupancy ------------------------------------------------------------------
func occupy(s: Structure) -> void:
	for c in Placement.footprint_cells(s.type, s.x, s.z):
		if world.grid.in_bounds(c.x, c.y):
			occupied[world.grid.idx(c.x, c.y)] = s


func vacate(s: Structure) -> void:
	for k in occupied.keys():
		if occupied[k] == s:
			occupied.erase(k)


func structure_at(x: int, z: int) -> Structure:
	return occupied.get(world.grid.idx(x, z)) if world.grid.in_bounds(x, z) else null


# ---- lifecycle --------------------------------------------------------------------
func place(type: String, x: int, z: int, instant := false) -> Structure:
	var s := Structure.new(type, x, z)
	if s.def.get("drop_pod", false) and not instant and not economy.spend(s.def.cost):
		return null
	if not _pay_ore(type, x, z, instant):
		return null
	s.pos = world.grid.cell_ground(x, z)
	s.node = Node3D.new()
	s.node.position = s.pos + Vector3(0, Mover.hover_offset(s), 0)
	s.body = StructureMeshes.make(type)
	s.node.add_child(s.body)
	var big := StructureDefs.footprint(type) > 0
	s.hp_bar = Bar.new(3.0 if big else 1.6, StructureMeshes.top_y(type) + 0.6)
	s.node.add_child(s.hp_bar)
	if s.has_ammo_store():
		s.ammo_bar = Bar.new(3.0 if big else 1.6, s.hp_bar.position.y - 0.25)
		s.node.add_child(s.ammo_bar)
	add_child(s.node)
	if instant:
		s.built = 1.0
		s.delivered = s.def.get("cost", 0)
		s.ammo = s.ammo_max()
	else:
		s.body.scale.y = 0.15
	s.prey = { "node": s.node, "radius": 2.5 if big else 1.0, "alive": func(): return not s.dead,
		"hit": func(d): damage(s, d) }
	occupy(s)
	list.append(s)
	dirty = true
	if not instant:
		Bus.metric.emit("placed", { "type": type })
	if type == "beacon" and not instant:
		selected_beacon = s
	return s


func remove(s: Structure, reason := "") -> void:
	if not list.has(s):
		return
	list.erase(s)
	s.dead = true
	vacate(s)
	if selected_beacon == s:
		selected_beacon = null
	if reason == "destroyed" or reason == "recycled":
		Bus.metric.emit("structure_lost" if reason == "destroyed" else "recycled",
			{ "type": s.type, "reason": reason, "wet": s.wet > Config.MIN_DEPTH, "built": s.is_built() })
	if reason != "":
		WeaponFx.death(world.effects, s, reason)  # P2: debris + dust for kills (visual only)
	if reason == "destroyed":
		Sfx.play("lost", s.pos)
		if s.type == "node":
			Bus.node_destroyed.emit()
		else:
			Bus.say("%s destroyed%s" % [s.def.label, " by creeper" if s.wet > Config.MIN_DEPTH else ""], "bad")
	s.node.queue_free()
	dirty = true
	Bus.structure_removed.emit(s)


func recycle(s: Structure) -> void:
	if s.type == "node":
		return
	economy.add(floorf((s.delivered - s.lost) * Config.RECYCLE_REFUND))
	world.effects.burst(s.node.position + Vector3.UP, Color("7fe0ff"), 2.0, 0.3)
	remove(s, "recycled")


func damage(s: Structure, amount: float) -> void:
	if s.dead:
		return
	s.hp -= amount
	s.hurt = 0.25
	if s.type == "node":
		Bus.node_hit.emit()
	if s.hp <= 0.0:
		remove(s, "destroyed")


func move(s: Structure, x: int, z: int) -> Dictionary:
	if s.is_flying():
		return { "ok": false, "reason": "Already moving" }
	var res := Placement.can_move(self, s, x, z)
	if res.ok:
		Mover.start(self, s, x, z)
	return res


func wet_depth(s: Structure) -> float:
	var d := 0.0
	for c in Placement.footprint_cells(s.type, s.x, s.z):
		d = maxf(d, world.creeper.depth_at(c.x, c.y))
	return d


func nearest_to(x: int, z: int, filter: Callable) -> Structure:
	var best: Structure = null
	var bd := INF
	for s in list:
		if filter.call(s):
			var d := Vector2(s.x - x, s.z - z).length()
			if d < bd:
				bd = d
				best = s
	return best


# ---- per frame --------------------------------------------------------------------
func update(dt: float, time: float) -> void:
	var node := command_node()
	for s in list:
		if s.type == "node" and s.is_flying():
			dirty = true  # its held links follow it (Network._hold_flying_node)
		if s.is_flying() and Mover.update(s, dt):
			dirty = true
			Sfx.play("build", s.pos)
			if s.type == "node":
				Bus.node_landed.emit()
	if dirty:
		network.rebuild(list)
		dirty = false
	var producing := node != null and not node.is_flying()
	packets.update(dt, list, _sender_ready())
	var reactor := 0.0
	var storage := 0.0
	var outpost_storage := 0.0
	var collectors := []
	for s in list.duplicate():
		StructureUpkeep.creeper_and_repair(self, s, dt)
		if s.dead:
			continue
		StructureUpkeep.construction(self, s, dt)
		StructureUpkeep.bars(s, time)
		if s.type == "outpost" and s.is_built():
			outpost_storage += Config.OUTPOST_STORAGE
		if not s.active:  # CW3 deactivate: no firing, mining, field or behaviour
			continue
		# A roaming weapon (Thor) fires from its magazine anywhere: off-network and in flight.
		var roams: bool = s.is_built() and s.def.get("roams", false)
		if roams:
			WeaponLogic.update(s, dt, self)
		if s.type == "miner":
			Miner.update(self, s, dt)
		if not s.is_built() or not s.connected or s.is_flying():
			continue
		if s.type == "collector":
			collectors.append(s)
		reactor += s.def.get("income", 0.0)
		storage += s.def.get("storage", 0.0)
		if not roams:
			WeaponLogic.update(s, dt, self)
		StructureBehaviors.update(s, dt, self, time)
	field.update(dt, collectors)
	economy.tick(dt, producing, field.income, field.cells, reactor, storage, outpost_storage)


## Miner must be on a live vein. Outpost pays its Ore when placed (instant test builds skip it).
func _pay_ore(type: String, x: int, z: int, instant: bool) -> bool:
	if type == "miner":
		var vein: Dictionary = deposits.ore_at(x, z) if deposits != null else {}
		return not vein.is_empty() and float(vein.get("left", 0.0)) >= 1.0
	if type == "outpost" and not instant:
		return stockpile != null and stockpile.spend("ore", Config.OUTPOST_ORE)
	return true


## Packets launch while any sender is built, connected and on the ground.
func _sender_ready() -> bool:
	for s in list:
		if s.def.get("sender", false) and s.is_built() and s.connected and not s.is_flying():
			return true
	return false
