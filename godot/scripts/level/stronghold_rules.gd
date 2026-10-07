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
	return { "id": row.id, "name": row.get("name", row.id), "owner": "enemy", "state": "hostile",
		"walls": walls, "gates": gates,
		"winch": { "hp": Config.CASTLE_WINCH_HP, "max_hp": Config.CASTLE_WINCH_HP },
		"crown": { "hp": Config.CROWN_HP, "max_hp": Config.CROWN_HP },
		"capture": { "progress": 0.0, "away": 0.0, "retake": 0.0 },
		"pump": { "material": 0.0, "intake": 0.0, "jam": 0.0 }, "garrison_timer": 0.0,
		"sockets": CastleTurrets.new_sockets(lay) }


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
	var f := faction(c.owner)
	var cells: Array[Vector2i] = []
	for i in lay.gates.size():
		for cell in lay.gates[i].cells:
			g.gate[g.idx(cell.x, cell.y)] = f if c.gates[i].hp > 0.0 else Grid.Faction.NONE
			cells.append(cell)
	for cell in lay.bridge:
		g.deck_owner[g.idx(cell.x, cell.y)] = f if c.winch.hp > 0.0 else Grid.Faction.ALL
		cells.append(cell)
	for cell in lay.courtyard:  # you build in the courtyard of a castle you hold
		if g.material[g.idx(cell.x, cell.y)] == Grid.Mat.NATURAL:
			g.blocked[g.idx(cell.x, cell.y)] = 0 if c.owner == "player" else 1
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


## Is the courtyard sealed to raiders, so they must break something to get in?
static func sealed(c: Dictionary, lay: Dictionary) -> bool:
	if c.owner != "player" or c.gates.any(func(gt): return gt.hp <= 0.0):
		return false
	return lay.raised or c.walls.all(func(wl): return wl.hp > 0.0)


static func to_hostile(world: World, c: Dictionary, lay: Dictionary, regrow: float) -> void:
	c.state = "hostile"
	c.crown.hp = c.crown.max_hp * regrow
	c.capture = { "progress": 0.0, "away": 0.0, "retake": 0.0 }
	c.garrison_timer = 0.0
	CastleTurrets.clear(c)
	set_owner(world, c, lay, "enemy")


static func to_held(world: World, c: Dictionary, lay: Dictionary) -> void:
	c.state = "held"
	c.capture.retake = 0.0
	set_owner(world, c, lay, "player")


## Operative in the capture zone: on the column top.
static func in_zone(lay: Dictionary, p: Variant) -> bool:
	if p == null:
		return false
	var cell := Vector2i(floori(p.x / Config.CELL), floori(p.z / Config.CELL))
	return cell in lay.spire.column and p.y >= (lay.spire.top - 0.5) * Config.LEVEL_H


static func in_courtyard(lay: Dictionary, p: Vector3) -> bool:
	var r: Rect2i = lay.rect.grow(-2)
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
