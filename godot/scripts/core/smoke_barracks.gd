class_name SmokeBarracks
## Barracks population cap (8) and soldier spawn/exit robustness. Called from SmokeTest.run.


static func run(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.surface.grid
	_cap(g, sm)
	_spawn_clear(g, sm, grid)
	_spawn_rally_on_barracks(g, sm, grid)
	_unstick(g, sm, grid)


static func _cap(g, sm: StructureManager) -> void:
	var b: Structure = sm.place("barracks", 40, 60, true)
	var ok := 0
	for i in 8:
		if StructureBehaviors.queue_unit(b, "soldier", g.units.living_for(b)):
			ok += 1
	SmokeTest._check("barracks cap is 8", ok == 8 and b.queue.size() == 8, "(queued %d)" % b.queue.size())
	SmokeTest._check("barracks refuses 9th unit", not StructureBehaviors.queue_unit(b, "soldier", g.units.living_for(b)),
		"(queue %d)" % b.queue.size())
	sm.remove(b)


static func _spawn_clear(g, sm: StructureManager, grid: Grid) -> void:
	var b: Structure = sm.place("barracks", 44, 60, true)
	for i in 8:
		g.units._on_trained("soldier", b)
	var free := true
	for u in g.units.list:
		var c := grid.world_to_cell(u.pos.x, u.pos.z)
		free = free and not g.surface.occupied.call(c.x, c.y)
	SmokeTest._check("8 soldiers spawn on free cells", g.units.list.size() == 8 and free,
		"(%d units)" % g.units.list.size())
	SmokeTest._sim(g, 25.0)
	var arrived := 0
	for u in g.units.list:
		if u.state == "idle" and u.path.is_empty():
			arrived += 1
	SmokeTest._check("8 soldiers reach the rally", arrived == 8, "(%d idle at rally)" % arrived)
	for u in g.units.list.duplicate():
		g.units.kill(u)
	sm.remove(b)


static func _spawn_rally_on_barracks(g, sm: StructureManager, grid: Grid) -> void:
	# Rally set on the barracks itself: the order goal is nudged to a free cell
	# instead of leaving the soldier pushing against the wall.
	var b: Structure = sm.place("barracks", 48, 60, true)
	b.rally = b.pos
	g.units._on_trained("soldier", b)
	var u: Unit = g.units.list.back()
	SmokeTest._sim(g, 20.0)
	var d := Vector2(u.pos.x - b.pos.x, u.pos.z - b.pos.z).length()
	var c := grid.world_to_cell(u.pos.x, u.pos.z)
	SmokeTest._check("rally-on-barracks soldier settles outside", u.state == "idle" and d > 3.0
		and not g.surface.occupied.call(c.x, c.y), "(state=%s dist=%.1f)" % [u.state, d])
	for u2 in g.units.list.duplicate():
		g.units.kill(u2)
	sm.remove(b)


static func _unstick(g, sm: StructureManager, grid: Grid) -> void:
	# Unit boxed inside an occupied cell (e.g. construction finished on top of it):
	# one re-path out instead of idling inside forever.
	var b: Structure = sm.place("barracks", 52, 60, true)
	g.units._on_trained("soldier", b)
	var u: Unit = g.units.list.back()
	u.pos = b.pos  # force inside the footprint
	u.post = Vector2(b.pos.x, b.pos.z + 12.0)
	u.path = []
	u.state = "move"
	SmokeTest._sim(g, 8.0)
	var c := grid.world_to_cell(u.pos.x, u.pos.z)
	SmokeTest._check("boxed unit re-paths out", not g.surface.occupied.call(c.x, c.y),
		"(state=%s pos=%s)" % [u.state, str(u.pos)])
	for u2 in g.units.list.duplicate():
		g.units.kill(u2)
	sm.remove(b)
