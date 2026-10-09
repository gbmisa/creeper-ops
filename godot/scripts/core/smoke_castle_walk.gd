class_name SmokeCastleWalk
## Stage 7 movement checks: the Operative really climbs a castle's pillar route and the
## spire (scripted PlayerController with fake keys), raiders can't, and drawbridge decks
## are solid for every faction (the gate is the defense, not the bridge). Called from
## SmokeStrongholds.run.


## Holds keys for the controller instead of reading the keyboard.
class FakeInput extends InputState:
	var hold := {}
	var press := {}

	func held(id: String) -> bool:
		return hold.has(id)

	func act(id: String) -> bool:
		return press.has(id)


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var grid: Grid = g.surface.grid
	var keep: Dictionary = castles.lays.ashmoat
	var raised: Dictionary = castles.lays.bastion
	_pillars(grid, keep)
	_spire(castles, grid, raised)  # Ashmoat is concentric (no spire ramp) since Stage 21
	_raider_proof(g, castles, grid, keep)
	_bridge(g, castles, grid, raised)


## Walks (or jumps when asked) toward a cell centre; returns the controller after landing.
static func _go(pc: PlayerController, grid: Grid, inp: FakeInput, to: Vector2i, jump: bool, push := 0.0) -> void:
	var goal := grid.cell_center(to.x, to.y)
	inp.hold = { "op_forward": true }
	inp.press = { "jump": true } if jump else {}
	for i in 150:
		var d := Vector2(goal.x - pc.pos.x, goal.z - pc.pos.z)
		if d.length() < 0.25 and pc.on_ground:
			break
		pc.yaw = atan2(-d.x, -d.y)
		pc.update(1.0 / 60.0, inp, grid)
		inp.press = {}
		if push > 0.0 and i == 0:  # a jump pad's kick (Strongholds._pad) on the first frame
			pc.vel_y = push
			pc.on_ground = false
	inp.hold = {}


static func _cell(pc: PlayerController, grid: Grid) -> Vector2i:
	return grid.world_to_cell(pc.pos.x, pc.pos.z)


static func _pillars(grid: Grid, lay: Dictionary) -> void:
	var route: Array = lay.climbs[0]
	var cam := Camera3D.new()
	var pc := PlayerController.new(cam)
	var inp := FakeInput.new()
	var first: Vector2i = route[0]
	var start: Vector2i = first + (first - lay.rect.get_center()).sign() * Vector2i(1, 0)  # apron beside pillar 1
	pc.spawn(grid, start.x, start.y)
	_go(pc, grid, inp, first, false)
	SmokeTest._check("castle: pillar 1 is a step up from the apron", _cell(pc, grid) == first)
	var ok := true
	for i in range(1, route.size()):
		_go(pc, grid, inp, route[i], true)
		ok = ok and _cell(pc, grid) == route[i]
	SmokeTest._check("castle: Operative jumps the pillar route", ok, "(at %s)" % _cell(pc, grid))
	var last: Vector2i = route.back()
	var wall: Vector2i = last + (lay.rect.get_center() - last).sign() * Vector2i(2, 0)
	_go(pc, grid, inp, wall, true)
	SmokeTest._check("castle: last jump lands on the wall walk", _cell(pc, grid) == wall
		and absf(pc.pos.y - lay.wall_top * Config.LEVEL_H) < 0.05, "(%s y %.2f)" % [_cell(pc, grid), pc.pos.y])
	pc.spawn(grid, start.x, start.y)
	_go(pc, grid, inp, route[2], false)
	SmokeTest._check("castle: no walking up the pillars", _cell(pc, grid) != route[2])
	inp.free()
	cam.free()


static func _spire(castles: Strongholds, grid: Grid, lay: Dictionary) -> void:
	var sp: Dictionary = lay.spire
	var walk := _reach(grid, sp.entry + Vector2i(-2, 0), Config.CLIMB, 99.0, Grid.Faction.PLAYER)
	SmokeTest._check("spire: ramp walkable to the jump pad", walk.has(sp.pad[0]))
	SmokeTest._check("spire: column top not walkable", not walk.has(sp.centre))
	SmokeTest._check("spire: indestructible", TerrainEdit.raise(castles.world, [sp.centre], -3.0).is_empty())
	var cam := Camera3D.new()
	var pc := PlayerController.new(cam)
	var inp := FakeInput.new()
	pc.spawn(grid, sp.pad[0].x, sp.pad[0].y)
	pc.on_ground = true
	castles._pad(lay, pc)
	var kick := pc.vel_y
	SmokeTest._check("spire: jump pad launches", kick > Config.JUMP_V * 1.5, "(%.1f m/s)" % kick)
	pc.spawn(grid, sp.pad[0].x, sp.pad[0].y)
	_go(pc, grid, inp, sp.centre, false, kick)
	SmokeTest._check("spire: pad lands the Operative on top", StrongholdRules.in_zone(lay, pc.pos),
		"(%s y %.1f, top %.1f)" % [_cell(pc, grid), pc.pos.y, sp.top * Config.LEVEL_H])
	inp.free()
	cam.free()


## Held castle with intact walls: raiders outside can't reach the courtyard or the walk.
static func _raider_proof(g, castles: Strongholds, grid: Grid, lay: Dictionary) -> void:
	var c: Dictionary = castles.list[0]
	StrongholdRules.set_owner(g.surface, c, lay, "player")
	var outside: Vector2i = lay.climbs[0][0] + Vector2i(1, 0)
	var seen := _reach(grid, outside, Config.RAIDER_CLIMB, Config.RAIDER_DROP, Grid.Faction.ENEMY)
	var yard: Vector2i = lay.home
	var wall: Vector2i = lay.segments[0].cells[0]
	SmokeTest._check("castle: raiders can't get in or onto the walls", not seen.has(yard) and not seen.has(wall))
	var inside := _reach(grid, yard, Config.CLIMB, 99.0, Grid.Faction.PLAYER)
	SmokeTest._check("castle: corner stairs reach the wall walk", inside.has(wall))
	StrongholdRules.set_owner(g.surface, c, lay, "enemy")
	SmokeTest._check("castle: hostile gate lets raiders in", _reach(grid, outside, Config.RAIDER_CLIMB,
		Config.RAIDER_DROP, Grid.Faction.ENEMY).has(yard))


static func _bridge(g, castles: Strongholds, grid: Grid, lay: Dictionary) -> void:
	var c: Dictionary = castles.list[1]
	var head: Vector2i = lay.winch + Vector2i(-2, 0)
	var gate: Vector2i = lay.gates[0].cells[0] + Vector2i(1, 0)
	var deck: Vector2i = lay.bridge[0]
	var deck_w := grid.cell_center(deck.x, deck.y)
	SmokeTest._check("bridge: enemy deck carries raiders", _reach(grid, head, Config.RAIDER_CLIMB,
		Config.RAIDER_DROP, Grid.Faction.ENEMY).has(gate))
	# Lowered decks are solid for every faction now (Gregory: "that should be a solid object").
	var pop: Dictionary = _reach(grid, head, Config.CLIMB, 99.0, Grid.Faction.PLAYER)
	SmokeTest._check("bridge: Operative walks an enemy deck", pop.has(deck))
	SmokeTest._check("bridge: intact enemy gate still stops the Operative", not pop.has(lay.gates[0].cells[0]))
	SmokeTest._check("bridge: deck stands at deck level for the Operative",
		absf(grid.stand_y(deck_w.x, deck_w.z, Grid.Faction.PLAYER) - lay.yard * Config.LEVEL_H) < 0.01)
	SmokeTest._check("bridge: on_deck ignores faction",
		grid.on_deck(grid.idx(deck.x, deck.y), Grid.Faction.PLAYER)
		and grid.on_deck(grid.idx(deck.x, deck.y), Grid.Faction.ENEMY))
	StrongholdRules.damage(g.surface, c, lay, "winch", 0, 1e6)
	SmokeTest._check("bridge: winch down still writes deck_owner ALL",
		grid.deck_owner[grid.idx(deck.x, deck.y)] == Grid.Faction.ALL)
	StrongholdRules.set_owner(g.surface, c, lay, "player")
	SmokeTest._check("bridge: re-hung for the new owner",
		grid.deck_owner[grid.idx(deck.x, deck.y)] == Grid.Faction.PLAYER
		and not _reach(grid, head, Config.RAIDER_CLIMB, Config.RAIDER_DROP, Grid.Faction.ENEMY).has(lay.gates[0].cells[0]))
	StrongholdRules.set_owner(g.surface, c, lay, "enemy")


## Cells a walker reaches from `start` (8-way, Grid.step_ok).
static func _reach(grid: Grid, start: Vector2i, climb: float, drop: float, faction: int) -> Dictionary:
	var seen := { start: true }
	var open := [start]
	while not open.is_empty():
		var a: Vector2i = open.pop_back()
		for d in RaiderField.DIRS:
			var b: Vector2i = a + d
			if not seen.has(b) and grid.step_ok(a.x, a.y, b.x, b.y, climb, drop, faction):
				seen[b] = true
				open.append(b)
	return seen
