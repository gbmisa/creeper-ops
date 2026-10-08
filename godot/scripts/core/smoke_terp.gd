class_name SmokeTerp
## Stage 11a: unlock, paint, packet steps, one cell at a time, and a sealed pool.

const PHRASE := "Not available on this level"
static var _dry := Vector2i(-1, -1)
const REASONS := {
	"spire": "Spire: indestructible, the Terp can't paint it",
	"stone": "Castle stone: the Terp can't reshape it",
	"blight": "Blight zone: the Terp can't paint here",
	"gate": "Gate: the Terp can't reshape a gate",
}


static func run(g) -> void:
	_locks(g)
	_refuse(g)
	_paint(g)
	_work(g)
	g.command.set_tool("")


static func _locks(g) -> void:
	var sm: StructureManager = g.structures
	var why := StructureDefs.lock_reason(g.level, "terp")
	SmokeTest._check("terp: locked without unlock", why == PHRASE and StructureDefs.lock_reason(g.level, "@terp") == PHRASE, why)
	g.hud.build.show_tab(2)
	g.hud.build.level = g.level
	g.hud.build.refresh(g.economy.energy)
	var btn := g.hud.build._buttons["terp"] as Button
	var paint_btn := g.hud.build._buttons["@terp"] as Button
	SmokeTest._check("terp: menu greys the locked Terp", btn.disabled and btn.text.contains(PHRASE) and paint_btn.disabled and paint_btn.text.contains(PHRASE))
	var denied := Placement.can_place(sm, "terp", sm.command_node().x, sm.command_node().z)
	SmokeTest._check("terp: placement says the level phrase", denied.reason == PHRASE, denied.reason)
	StructureDefs.grant_unlock(g.level, "terp")
	g.hud.build.refresh(g.economy.energy)
	var spot := _free_near(g)
	var placed := Placement.can_place(sm, "terp", spot.x, spot.y) if spot.x >= 0 else {"ok": false, "reason": "no free cell"}
	SmokeTest._check("terp: unlock clears the lock", StructureDefs.lock_reason(g.level, "terp") == "" and not btn.disabled and not btn.text.contains(PHRASE) and placed.ok, placed.reason)
	var keys := {"terp_up": KEY_PAGEUP, "terp_down": KEY_PAGEDOWN, "terp_erase": KEY_C}
	for id in keys:
		var row: Array = Keybinds.DEFAULTS[id]
		SmokeTest._check("terp: keybind %s" % id, row[0] == "Command" and row[2][0] == keys[id])


static func _refuse(g) -> void:
	var grid: Grid = g.surface.grid
	var paint: TerpPaint = g.surface.get_meta("terp_tint")
	var found := _special(grid)
	for tag in REASONS:
		var c: Vector2i = found[tag]
		var said := ""
		var kept := true
		if c.x >= 0:
			var i := grid.idx(c.x, c.y)
			var before := grid.terp_target[i]
			paint.level = 4
			paint.pinned = true
			paint.anchor = c
			said = paint.commit(g.command, c, false)
			kept = grid.terp_target[i] == before
		SmokeTest._check("terp: %s refuses paint" % tag, c.x >= 0 and said == REASONS[tag] and kept, said if c.x >= 0 else "no cell")


static func _paint(g) -> void:
	var grid: Grid = g.surface.grid
	var paint: TerpPaint = g.surface.get_meta("terp_tint")
	var c := _legal(g)
	if c.x < 0:
		SmokeTest._check("terp: found a paintable cell", false)
		return
	var base := clampi(int(round(grid.height_at(c.x, c.y))), 0, Config.MAX_LEVEL)
	var level := base + 1 if base < Config.MAX_LEVEL else base - 1
	g.command.set_tool("@terp")
	g.command.hover = {"cell": c, "point": grid.cell_ground(c.x, c.y)}
	paint.pinned = false
	paint.dragging = false
	paint.nudge(g.command, 1 if base < Config.MAX_LEVEL else -1)
	var hover := paint.hover_text(g.command)
	SmokeTest._check("terp: nudge sets the target", paint.pinned and paint.level == level and hover.contains("level %d" % level), hover)
	paint.commit(g.command, c, false)
	var i := grid.idx(c.x, c.y)
	var raised := float(level) > grid.height_at(c.x, c.y)
	var mark := paint._bytes[i * 2] if raised else paint._bytes[i * 2 + 1]
	SmokeTest._check("terp: paint sets the cell", absf(grid.terp_target[i] - float(level)) < 0.01 and grid.terp_mat[i] == Grid.Mat.EARTH and mark == 255 and g.command.tool == "@terp")
	paint.anchor = c
	paint.commit(g.command, c, true)
	SmokeTest._check("terp: erase clears paint", grid.terp_target[i] < 0.0 and grid.terp_mat[i] == 0 and paint._bytes[i * 2] == 0 and paint._bytes[i * 2 + 1] == 0)
	CommandInput.right_click(g.command)
	SmokeTest._check("terp: right-click puts the tool away", g.command.tool == "")


static func _work(g) -> void:
	var sm: StructureManager = g.structures
	var grid: Grid = g.surface.grid
	var paint: TerpPaint = g.surface.get_meta("terp_tint")
	g.economy.energy = 1000000.0
	var pad := SmokeTerpJobs._pad(g)
	if pad.x < 0:
		SmokeTest._check("terp: found a flat pad", false, "no 7x7")
		return
	_dry = pad
	var avoid := Rect2i(pad.x - 3, pad.y - 3, 7, 7)
	var terps: Array[Structure] = []
	for o in [Vector2i(-3, 0), Vector2i(3, 0), Vector2i(0, -3), Vector2i(3, -3)]:
		var at: Vector2i = pad + o
		terps.append(sm.place("terp", at.x, at.y, true))
		SmokeTerpJobs._link(g, at.x, at.y, avoid)
	for _i in 5:
		_tick(g)
	var linked := true
	for s in terps:
		linked = linked and s.connected and not s.dead
	SmokeTest._check("terp: built terps connect", linked, SmokeTerpJobs._state(terps))
	if not linked:
		SmokeTerpJobs._wipe(grid, paint, terps)
		_dry = Vector2i(-1, -1)
		return
	SmokeTerpJobs._step(g, grid, paint, terps, pad + Vector2i(-2, -2), 2)
	SmokeTerpJobs._step(g, grid, paint, terps, pad + Vector2i(-1, -2), -1)
	SmokeTerpJobs._occupied(g, sm, grid, paint, terps, pad)
	SmokeTerpJobs._share(g, grid, paint, terps, pad + Vector2i(1, -2))
	SmokeTerpRing._ring(g, grid, paint, terps, pad)
	SmokeTerpJobs._wipe(grid, paint, terps)
	SmokeTerpJobs._idle(g, terps)
	_dry = Vector2i(-1, -1)


## Top the bank up (income can't feed every requester) and keep the pad dry so a Terp
## is not lost to creeper while the steps run.
static func _tick(g) -> void:
	if _dry.x >= 0:
		var sim: CreeperSim = g.surface.creeper
		for dz in range(-5, 6):
			for dx in range(-5, 6):
				sim.set_depth(_dry.x + dx, _dry.y + dz, 0.0)
	g.economy.max_energy = 1000000.0
	g.economy.energy = 1000000.0
	g.update(0.05)


static func _special(grid: Grid) -> Dictionary:
	var found := {"spire": Vector2i(-1, -1), "stone": Vector2i(-1, -1), "blight": Vector2i(-1, -1), "gate": Vector2i(-1, -1)}
	for z in grid.h:
		for x in grid.w:
			var i := grid.idx(x, z)
			var tag := ""
			if grid.gate[i] != Grid.Faction.NONE:
				tag = "gate"
			elif grid.material[i] == Grid.Mat.SPIRE:
				tag = "spire"
			elif grid.material[i] == Grid.Mat.STONE or grid.material[i] == Grid.Mat.PLATED:
				tag = "stone"
			elif grid.zone[i] == Grid.Zone.BLIGHT:
				tag = "blight"
			if tag != "" and (found[tag] as Vector2i).x < 0:
				found[tag] = Vector2i(x, z)
	return found


static func _legal(g) -> Vector2i:
	var grid: Grid = g.surface.grid
	for z in range(2, grid.h - 2):
		for x in range(2, grid.w - 2):
			if TerpPaint.cell_reason(grid, Vector2i(x, z)) == "" and g.structures.structure_at(x, z) == null:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _free_near(g) -> Vector2i:
	var sm: StructureManager = g.structures
	var node := sm.command_node()
	for r in range(2, 16):
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				if Placement.can_place(sm, "terp", node.x + dx, node.z + dz).ok:
					return Vector2i(node.x + dx, node.z + dz)
	return Vector2i(-1, -1)


