class_name DebugEngines
## Debug hooks for Salvage Engines. --engine=I[,mode[,socket]]
##   (no mode)  the Operative stands beside engine I, facing socket `socket` (default 1, else 0)
##   hold       same, with a relay chain built and the use key held (mid-hook screenshot)
##   hooked     relay chain built and every socket hooked (command-view screenshots)
##   top        the Operative stands on top of the engine (the stair climbed)


static func apply(g, spec: String) -> void:
	var p := spec.split(",")
	var e: Dictionary = g.engines.list[int(p[0])]
	var mode := p[1] if p.size() > 1 else ""
	var s_i := int(p[2]) if p.size() > 2 else (1 if e.sockets.size() > 1 else 0)
	var s: Dictionary = e.sockets[s_i]
	if mode == "hold" or mode == "hooked":
		chain(g, s.cell)
	if mode == "hooked":
		for sock in e.sockets:
			g.engines.hook(e, sock)
		return
	var cell: Vector2i = s.cell
	if mode == "top":
		cell = Vector2i(int(e.row.x), int(e.row.z))
	var look: Vector3 = s.pos
	g.fps.enter(g.surface, cell, 0.0)
	var wx := (cell.x + 0.5) * Config.CELL
	var wz := (cell.y + 0.5) * Config.CELL
	if mode == "" or mode == "hold":  # a metre and a half out from the socket, on its outward side
		var out := Vector2(look.x - (int(e.row.x) + 0.5) * Config.CELL, look.z - (int(e.row.z) + 0.5) * Config.CELL).normalized()
		var d := 2.2 if mode == "" else 1.3
		wx = look.x + out.x * d
		wz = look.z + out.y * d
	var at := Vector3(wx, g.level.grid.stand_y(wx, wz, Grid.Faction.PLAYER), wz)
	g.fps.controller.pos = at
	g.fps.body.position = at
	g.fps.controller.yaw = atan2(-(look.x - at.x), -(look.z - at.z))
	g.fps.controller.pitch = clampf(atan2(look.y - (at.y + Config.EYE), Vector2(look.x - at.x, look.z - at.z).length()), -1.2, 1.2)
	g.flow.set_mode("surface")
	if mode == "hold":
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)


## Relays from the Command Node to within 4 cells of `cell` (instant, for scenes).
static func chain(g, cell: Vector2i) -> void:
	var n: Structure = g.structures.command_node()
	var from := Vector2(n.x, n.z)
	var to := Vector2(cell.x, cell.y)
	var steps := int(ceil(from.distance_to(to) / 11.0))
	for i in range(1, steps + 1):
		var at := from.lerp(to, float(i) / float(steps))
		if i == steps:
			at = to.move_toward(from, 4.0)
		g.structures.place("relay", roundi(at.x), roundi(at.y), true)
	g.structures.network.rebuild(g.structures.list)
