class_name StrongholdRules
## State changes for castles (static; Strongholds owns the data). A castle's mutable state
## is a plain dictionary (saveable, no Node references):
##   { id, name, owner: "enemy" | "player", state: "hostile" | "capturing" | "held" | "siege",
##     walls: [{ hp, max_hp }] (index-aligned with layout.segments), gates: [{ hp, max_hp }],
##     winch: { hp, max_hp }, crown: { hp, max_hp }, capture: { progress, away, retake },
##     pump: { material, intake, jam }, garrison_timer }
## Layouts (cells) come from CastleShape and are rebuilt from level data, so they stay out
## of the state.


static func new_state(row: Dictionary, lay: Dictionary) -> Dictionary:
	var walls := []
	for s in lay.segments:
		walls.append({ "hp": Config.CASTLE_WALL_HP, "max_hp": Config.CASTLE_WALL_HP })
	var gates := []
	for gt in lay.gates:
		gates.append({ "hp": Config.CASTLE_GATE_HP, "max_hp": Config.CASTLE_GATE_HP })
	return { "id": row.id, "name": row.get("name", row.id), "owner": "enemy", "state": "hostile", "yield": row.get("yield", 1.0),
		"walls": walls, "gates": gates,
		"winch": { "hp": Config.CASTLE_WINCH_HP, "max_hp": Config.CASTLE_WINCH_HP },
		"crown": { "hp": Config.CROWN_HP, "max_hp": Config.CROWN_HP },
		"capture": { "progress": 0.0, "away": 0.0, "retake": 0.0 },
		"pump": { "material": 0.0, "intake": 0.0, "jam": 0.0 }, "garrison_timer": 0.0,
		"sockets": CastleTurrets.new_sockets(lay), "stage": 0, "ring": CastleStages.new_state(),
		"engines": CastleEngines.new_state(row, lay) }


static func faction(owner: String) -> int:
	return Grid.Faction.PLAYER if owner == "player" else Grid.Faction.ENEMY


## Hand the castle to `owner`: gates and the drawbridge are re-hung for the new owner (a
## destroyed gate or winch is rebuilt). Breached walls stay breached until repaired.
static func set_owner(world: World, c: Dictionary, lay: Dictionary, owner: String) -> void:
	c.owner = owner
	for gt in c.gates:
		gt.hp = gt.max_hp
	c.winch.hp = c.winch.max_hp
	sync_grid(world, c, lay)


## Writes gate and deck ownership into the grid from the state (also used after loading).
static func sync_grid(world: World, c: Dictionary, lay: Dictionary) -> void:
	var g := world.grid
	var cells: Array[Vector2i] = []
	for i in lay.gates.size():  # concentric: the outer ring is yours from the gate stage on
		var f := faction(CastleStages.ring_owner(c, lay, lay.gates[i].get("ring", "outer")))
		for cell in lay.gates[i].cells:
			g.gate[g.idx(cell.x, cell.y)] = f if c.gates[i].hp > 0.0 else Grid.Faction.NONE
			cells.append(cell)
	var fb := faction(CastleStages.ring_owner(c, lay, "outer"))
	for cell in lay.bridge:
		g.deck_owner[g.idx(cell.x, cell.y)] = fb if c.winch.hp > 0.0 else Grid.Faction.ALL
		cells.append(cell)
	var bailey := {}
	for cell in lay.get("bailey", []):
		bailey[cell] = true
	var open_bailey := CastleStages.bailey_open(c, lay)
	for cell in lay.courtyard:  # you build in the courtyard of a castle you hold (and a bailey you took)
		if g.material[g.idx(cell.x, cell.y)] == Grid.Mat.NATURAL:
			var mine: bool = c.owner == "player" or (open_bailey and bailey.has(cell))
			g.blocked[g.idx(cell.x, cell.y)] = 0 if mine else 1
	if not cells.is_empty():
		world.terrain_changed(cells)  # walkers re-plan; heights are unchanged


static func breach(world: World, c: Dictionary, lay: Dictionary, i: int) -> void:
	c.walls[i].hp = 0.0
	var edits := []
	for cell in lay.segments[i].cells:
		edits.append({ "x": cell.x, "z": cell.y, "height": lay.yard, "material": Grid.Mat.NATURAL })
	TerrainEdit.apply(world, edits)


## Damage to a wall segment, gate or winch. Returns true when it just broke.
static func damage(world: World, c: Dictionary, lay: Dictionary, part: String, i: int, dmg: float) -> bool:
	var p: Dictionary = c.winch if part == "winch" else c[part][i]
	if p.hp <= 0.0:
		return false
	p.hp -= dmg
	if p.hp > 0.0:
		return false
	p.hp = 0.0
	if part == "walls":
		breach(world, c, lay, i)
	else:
		sync_grid(world, c, lay)
	return true


## Is a ring (outer / inner; Stage 7 castles have only "outer") sealed to raiders, so they
## must break one of its gates or walls to get through? "" = any ring of the castle.
static func sealed(c: Dictionary, lay: Dictionary, ring := "") -> bool:
	if ring == "":
		return sealed(c, lay, "outer") or (lay.get("plan", "") == "concentric" and sealed(c, lay, "inner"))
	if CastleStages.ring_owner(c, lay, ring) != "player":
		return false
	for i in lay.gates.size():
		if lay.gates[i].get("ring", "outer") == ring and c.gates[i].hp <= 0.0:
			return false
	if lay.raised and ring == "outer":
		return true
	for i in lay.segments.size():
		if lay.segments[i].get("ring", "outer") == ring and c.walls[i].hp <= 0.0:
			return false
	return true


static func to_hostile(world: World, c: Dictionary, lay: Dictionary, regrow: float) -> void:
	c.state = "hostile"
	Bus.metric.emit("castle_hostile", { "name": c.name })
	c.crown.hp = c.crown.max_hp * regrow
	c.capture = { "progress": 0.0, "away": 0.0, "retake": 0.0 }
	c.garrison_timer = 0.0
	c["stage"] = 0
	c["ring"] = CastleStages.new_state()
	CastleTurrets.clear(c)
	set_owner(world, c, lay, "enemy")


static func to_held(world: World, c: Dictionary, lay: Dictionary) -> void:
	c.state = "held"
	Bus.metric.emit("castle_held", { "name": c.name })
	c.capture.retake = 0.0
	c["stage"] = lay.stages.size()
	set_owner(world, c, lay, "player")


## Operative in the final capture zone: the spire column top (Stage 7) or the keep hall.
static func in_zone(lay: Dictionary, p: Variant, zone := "keep") -> bool:
	if p == null or not lay.zones.has(zone):
		return false
	var z: Dictionary = lay.zones[zone]
	var cell := Vector2i(floori(p.x / Config.CELL), floori(p.z / Config.CELL))
	return cell in z.cells and p.y >= (z.y - 0.5) * Config.LEVEL_H and p.y < (z.y_max - 1.0) * Config.LEVEL_H


static func in_courtyard(lay: Dictionary, p: Vector3) -> bool:
	var r: Rect2i = lay.rect.grow(-2)
	return r.has_point(Vector2i(floori(p.x / Config.CELL), floori(p.z / Config.CELL)))


## Inside the inner ring (concentric) or the courtyard (Stage 7): where a siege retakes the castle.
static func in_ward(lay: Dictionary, p: Vector3) -> bool:
	if not lay.has("inner_rect"):
		return in_courtyard(lay, p)
	var r: Rect2i = lay.inner_rect.grow(-2)
	return r.has_point(Vector2i(floori(p.x / Config.CELL), floori(p.z / Config.CELL)))


## The crown nest is solid: push the Operative out of its husk.
static func crown_push(v: Dictionary, o) -> void:
	var cp: Vector3 = (v.crown as Node3D).position
	var d := Vector2(o.pos.x - cp.x, o.pos.z - cp.z)
	var r := Config.CROWN_RADIUS + Config.OP_RADIUS
	if d.length() >= r or absf(o.pos.y - cp.y) > 3.0:
		return
	d = d.normalized() if d.length() > 0.01 else Vector2(1, 0)
	o.pos.x = cp.x + d.x * r
	o.pos.z = cp.z + d.y * r
