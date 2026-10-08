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
	var pad := _pad(g)
	if pad.x < 0:
		SmokeTest._check("terp: found a flat pad", false, "no 7x7")
		return
	_dry = pad
	var avoid := Rect2i(pad.x - 3, pad.y - 3, 7, 7)
	var terps: Array[Structure] = []
	for o in [Vector2i(-3, 0), Vector2i(3, 0), Vector2i(0, -3), Vector2i(3, -3)]:
		var at: Vector2i = pad + o
		terps.append(sm.place("terp", at.x, at.y, true))
		_link(g, at.x, at.y, avoid)
	for _i in 5:
		_tick(g)
	var linked := true
	for s in terps:
		linked = linked and s.connected and not s.dead
	SmokeTest._check("terp: built terps connect", linked, _state(terps))
	if not linked:
		_wipe(grid, paint, terps)
		_dry = Vector2i(-1, -1)
		return
	_step(g, grid, paint, terps, pad + Vector2i(-2, -2), 2)
	_step(g, grid, paint, terps, pad + Vector2i(-1, -2), -1)
	_occupied(g, sm, grid, paint, terps, pad)
	_share(g, grid, paint, terps, pad + Vector2i(1, -2))
	_ring(g, grid, paint, terps, pad)
	_wipe(grid, paint, terps)
	_idle(g, terps)
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


## `by` is the signed level change the paint asks for (+2 checks the halfway level).
static func _step(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], c: Vector2i, by: int) -> void:
	_settle(g, grid, paint, terps)
	var h0 := grid.height_at(c.x, c.y)
	_paint_cell(paint, g.command, c, int(round(h0)) + by)
	var i := grid.idx(c.x, c.y)
	var goal := h0 + float(by)
	var asked := false
	var saw_mid := false
	var t := 0.0
	while t < 30.0 and not (absf(grid.height_at(c.x, c.y) - goal) < 0.01 and grid.terp_target[i] < 0.0):
		if _needs(g, terps):
			asked = true
		if by > 1 and absf(grid.height_at(c.x, c.y) - (h0 + 1.0)) < 0.01 and grid.terp_target[i] >= 0.0:
			saw_mid = true
		_tick(g)
		t += 0.05
	var done := absf(grid.height_at(c.x, c.y) - goal) < 0.01 and grid.terp_target[i] < 0.0 and grid.material[i] == Grid.Mat.EARTH
	if by > 0:
		SmokeTest._check("terp: requests terp packets", asked)
	var name := "terp: raises one level, then finishes" if by > 1 else "terp: lowers and clears paint"
	SmokeTest._check(name, done and (saw_mid or by < 0), "h %.2f paint %.2f" % [grid.height_at(c.x, c.y), grid.terp_target[i]])


static func _occupied(g, sm: StructureManager, grid: Grid, paint: TerpPaint, terps: Array[Structure], pad: Vector2i) -> void:
	_settle(g, grid, paint, terps)
	var near := pad + Vector2i(0, -2)
	var far := pad + Vector2i(2, -2)
	var hn := grid.height_at(near.x, near.y)
	var hf := grid.height_at(far.x, far.y)
	_paint_cell(paint, g.command, near, int(round(hn)) + 1)
	_paint_cell(paint, g.command, far, int(round(hf)) + 1)
	var blocker := sm.place("relay", near.x, near.y, true)
	for s in terps:
		s.job = {}
	var stole := false
	var t := 0.0
	while t < 25.0 and absf(grid.height_at(far.x, far.y) - (hf + 1.0)) > 0.01:
		_tick(g)
		t += 0.05
		for s in terps:
			if int(s.job.get("x", -1)) == near.x and int(s.job.get("z", -1)) == near.y:
				stole = true
	var skipped := not stole and absf(grid.height_at(near.x, near.y) - hn) < 0.01 and absf(grid.height_at(far.x, far.y) - (hf + 1.0)) < 0.01
	SmokeTest._check("terp: skips an occupied cell", skipped, "near %.2f far %.2f %s" % [grid.height_at(near.x, near.y), grid.height_at(far.x, far.y), _state(terps)])
	if blocker:
		sm.remove(blocker, "recycled")


static func _share(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], c: Vector2i) -> void:
	_settle(g, grid, paint, terps)
	var h0 := grid.height_at(c.x, c.y)
	_paint_cell(paint, g.command, c, int(round(h0)) + 1)
	var dup := false
	var saw := false
	var t := 0.0
	var i := grid.idx(c.x, c.y)
	while t < 25.0 and grid.terp_target[i] >= 0.0:
		_tick(g)
		t += 0.05
		var seen := {}
		for s in terps:
			var x := int(s.job.get("x", -1))
			var z := int(s.job.get("z", -1))
			if s.job.is_empty() or x < 0:
				continue
			var key := grid.idx(x, z)
			if seen.has(key):
				dup = true
			seen[key] = true
			if float(s.job.get("timer", 0.0)) > 0.0:
				saw = true
	SmokeTest._check("terp: two terps never share a cell", not dup and saw, _state(terps))


static func _ring(g, grid: Grid, paint: TerpPaint, terps: Array[Structure], pad: Vector2i) -> void:
	_settle(g, grid, paint, terps)
	var h0 := grid.height_at(pad.x, pad.y)
	var field: RaiderField = g.hazards.nests.raiders.field
	var probe := pad + Vector2i(0, 2)
	field.rebuild([pad])
	SmokeTest._check("terp: open pool is reachable", field.dist[grid.idx(probe.x, probe.y)] >= 0, str(field.dist[grid.idx(probe.x, probe.y)]))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dz != 0:
				_paint_cell(paint, g.command, pad + Vector2i(dx, dz), int(round(h0)) + 2)
	var t := 0.0
	while t < 55.0 and not _ring_done(grid, pad, h0):
		_tick(g)
		t += 0.05
	SmokeTest._check("terp: ring reaches its target", _ring_done(grid, pad, h0), _ring_detail(grid, pad, terps))
	var wall := pad + Vector2i(0, 1)
	SmokeTest._check("terp: raiders cannot step onto the wall", not field.step_ok(probe.x, probe.y, wall.x, wall.y))
	field.rebuild([pad])
	var after := field.dist[grid.idx(probe.x, probe.y)]
	SmokeTest._check("terp: sealed pool has no raider route", after < 0, str(after))
	var sim := CreeperSim.new(grid)
	sim.set_depth(pad.x, pad.y, 1.0)
	for _n in 40:
		sim.update(Config.CREEPER_TICK)
	var held := sim.depth_at(wall.x, wall.y) < Config.MIN_DEPTH and sim.depth_at(probe.x, probe.y) < Config.MIN_DEPTH and sim.depth_at(pad.x, pad.y) > Config.MIN_DEPTH
	SmokeTest._check("terp: ring holds creeper", held, "pool %.3f wall %.3f" % [sim.depth_at(pad.x, pad.y), sim.depth_at(wall.x, wall.y)])
	field.invalidate()


static func _ring_done(grid: Grid, pad: Vector2i, h0: float) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var c := pad + Vector2i(dx, dz)
			if absf(grid.height_at(c.x, c.y) - (h0 + 2.0)) > 0.01 or grid.terp_target[grid.idx(c.x, c.y)] >= 0.0:
				return false
	return true


static func _ring_detail(grid: Grid, pad: Vector2i, terps: Array[Structure]) -> String:
	var bits := []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var c := pad + Vector2i(dx, dz)
			bits.append("%.0f/%.0f" % [grid.height_at(c.x, c.y), grid.terp_target[grid.idx(c.x, c.y)]])
	return " ".join(bits) + " " + _state(terps)


static func _needs(g, terps: Array[Structure]) -> bool:
	for s in terps:
		if PacketRequests.need(g.structures.network, s) == "terp":
			return true
	return false


static func _paint_cell(paint: TerpPaint, cm: CommandMode, c: Vector2i, level: int) -> void:
	paint.level = clampi(level, 0, Config.MAX_LEVEL)
	paint.pinned = true
	paint.anchor = c
	paint.commit(cm, c, false)


static func _settle(g, grid: Grid, paint: TerpPaint, terps: Array[Structure]) -> void:
	_wipe(grid, paint, terps)
	_idle(g, terps)


static func _wipe(grid: Grid, paint: TerpPaint, terps: Array[Structure]) -> void:
	for i in grid.terp_target.size():
		grid.terp_target[i] = -1.0
		grid.terp_mat[i] = 0
	for s in terps:
		s.job = {}
	paint.sync()


static func _idle(g, terps: Array[Structure]) -> void:
	var t := 0.0
	while t < 15.0:
		var fly := false
		for s in terps:
			s.job = {}
			if s.in_flight > 0:
				fly = true
		if not fly:
			return
		_tick(g)
		t += 0.05


static func _state(terps: Array[Structure]) -> String:
	var bits := []
	for s in terps:
		bits.append("%d,%d c%d d%d f%d %s" % [s.x, s.z, 1 if s.connected else 0, 1 if s.dead else 0, s.in_flight, str(s.job)])
	return " ".join(bits)


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


static func _pad(g) -> Vector2i:
	var grid: Grid = g.surface.grid
	var node: Structure = g.structures.command_node()
	var max_r := maxi(maxi(node.x, node.z), maxi(grid.w - node.x, grid.h - node.z))
	for r in max_r + 1:
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var x: int = node.x + dx
				var z: int = node.z + dz
				if x >= 3 and z >= 3 and x < grid.w - 3 and z < grid.h - 3 and _flat(g, x, z):
					return Vector2i(x, z)
	return Vector2i(-1, -1)


static func _flat(g, x: int, z: int) -> bool:
	var grid: Grid = g.surface.grid
	var h := grid.height_at(x, z)
	if h < 1.0 or h > float(Config.MAX_LEVEL) - 2.0:
		return false
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var i := grid.idx(x + dx, z + dz)
			if absf(grid.height[i] - h) > 0.01 or grid.blocked[i] or grid.zone[i] != Grid.Zone.NONE:
				return false
			if grid.gate[i] != Grid.Faction.NONE or grid.material[i] >= Grid.Mat.STONE or grid.deck_owner[i] != Grid.Faction.NONE:
				return false
			if g.structures.structure_at(x + dx, z + dz) != null or g.surface.creeper.depth_at(x + dx, z + dz) > Config.MIN_DEPTH:
				return false
	return true


static func _link(g, x: int, z: int, avoid: Rect2i) -> void:
	var sm: StructureManager = g.structures
	var guard := 0
	while not sm.network.in_range(sm.list, x, z, 6.0, null) and guard < 8:
		guard += 1
		var from := _anchor(sm, x, z)
		var dir := Vector2(x - from.x, z - from.y)
		var dist := dir.length()
		if dist < 1.0:
			return
		dir /= dist
		var step := minf(12.0, dist)
		var c := _dry_free(g, int(round(from.x + dir.x * step)), int(round(from.y + dir.y * step)), avoid)
		if c.x < 0:
			return
		sm.place("relay", c.x, c.y, true)
		_tick(g)


static func _anchor(sm: StructureManager, x: int, z: int) -> Vector2i:
	var best := sm.command_node()
	var bd := Vector2(best.x - x, best.z - z).length()
	for s in sm.list:
		if s.connected and s.def.get("relays", false):
			var d := Vector2(s.x - x, s.z - z).length()
			if d < bd:
				bd = d
				best = s
	return Vector2i(best.x, best.z)


static func _dry_free(g, x: int, z: int, avoid: Rect2i) -> Vector2i:
	var grid: Grid = g.surface.grid
	for r in 8:
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var cx := x + dx
				var cz := z + dz
				if not grid.in_bounds(cx, cz) or avoid.has_point(Vector2i(cx, cz)):
					continue
				if g.surface.creeper.depth_at(cx, cz) > Config.MIN_DEPTH or g.structures.structure_at(cx, cz) != null:
					continue
				return Vector2i(cx, cz)
	return Vector2i(-1, -1)
