class_name SmokeDragbuild
## Drag-build: chain spacing, cannon rows, commit, cliff backoff and cancel.
## Ghosts and the Operative drag are in SmokeDragView. Called from SmokeTest.run.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func run(g) -> void:
	var sm = g.structures
	var cm: CommandMode = g.command
	SmokeTest._sim(g, 0.25)
	var relay := _span(sm, "relay", int(StructureDefs.DEFS.relay.link))
	var collector := _span(sm, "collector", int(StructureDefs.DEFS.collector.link))
	_chain(cm, "relay", relay, StructureDefs.DEFS.relay.link)
	_chain(cm, "collector", collector, StructureDefs.DEFS.collector.link)
	_row(cm, _span(sm, "cannon", 4))
	if not collector.is_empty():
		_commit(g, cm, "collector", collector[0], collector[1])
	_cliff(g, cm)
	_cancel(g, cm)
	SmokeDragView._preview(cm, collector)
	SmokeDragView._operative(g, collector)
	cm.set_tool("")
	_silence(g)


static func _chain(cm: CommandMode, type: String, span: Array, link: float) -> void:
	if span.is_empty():
		SmokeTest._check("drag %s spacing" % type, false, "no flat run of %s" % link)
		return
	cm.set_tool(type)
	var items := DragBuild.plan(cm, span[0], span[1])
	var fit := items.size() >= 2
	var gaps: Array = []
	for i in range(1, items.size()):
		var d := Vector2(items[i].cell - items[i - 1].cell).length()
		gaps.append(d)
		if d > link or d < link - 1.5:
			fit = false
	SmokeTest._check("drag %s spacing" % type, fit, "%s -> %s %s" % [span[0], span[1], gaps])
	var n := 0
	var cost := 0
	for it in items:
		if it.ok:
			n += 1
			cost += int(it.cost)
	var want := "Release to place %d: %d energy total" % [n, cost]
	if n != items.size():
		want += " (%d blocked)" % (items.size() - n)
	SmokeTest._check("drag %s cost" % type, DragBuild.summary(items) == want, DragBuild.summary(items))


static func _row(cm: CommandMode, span: Array) -> void:
	if span.is_empty():
		SmokeTest._check("drag cannon row", false, "no flat cannon run")
		return
	cm.set_tool("cannon")
	var items := DragBuild.plan(cm, span[0], span[1])
	var w := StructureDefs.footprint("cannon") * 2 + 1
	var seen := {}
	var overlap := false
	var touch := items.size() >= 2
	for it in items:
		for f in Placement.footprint_cells("cannon", it.cell.x, it.cell.y):
			var k := f.x + f.y * 10000
			overlap = overlap or seen.has(k)
			seen[k] = true
	for i in range(1, items.size()):
		var a: Vector2i = items[i - 1].cell
		var b: Vector2i = items[i].cell
		touch = touch and maxi(absi(a.x - b.x), absi(a.y - b.y)) == w
	SmokeTest._check("drag cannon row", not overlap and touch, "%s -> %s (%d)" % [span[0], span[1], items.size()])


static func _commit(g, cm: CommandMode, type: String, a: Vector2i, b: Vector2i) -> void:
	var sm = g.structures
	cm.set_tool(type)
	var items := DragBuild.plan(cm, a, b)
	var had := _had(sm)
	var n := DragBuild.commit(cm, items)
	SmokeTest._sim(g, 0.1)
	var placed := _new(sm, had)
	var want: int = items.filter(func(it): return it.ok).size()
	var net := placed.size() == want and n == want
	for s in placed:
		var on_plan := false
		for it in items:
			if it.ok and it.cell == Vector2i(s.x, s.z):
				on_plan = true
		if not on_plan or not (s.connected or sm.network.in_range(sm.list, s.x, s.z, s.def.link, s)):
			net = false
	SmokeTest._check("drag commit places ok pieces on the network", net, "placed %d want %d" % [placed.size(), want])
	for s in placed:
		sm.remove(s)


static func _cliff(g, cm: CommandMode) -> void:
	var sm = g.structures
	var pair := _wall(g)
	if pair.is_empty():
		SmokeTest._check("drag cliff backs off the wall", false, "no wall crossing found")
		return
	cm.set_tool("relay")
	var items := DragBuild.plan(cm, pair.a, pair.b)
	var link: float = StructureDefs.DEFS.relay.link
	var bad := false
	var backed := false
	for i in items.size():
		var it: Dictionary = items[i]
		bad = bad or (it.ok and Placement.ground_reason(sm, "relay", it.cell.x, it.cell.y) != "")
		backed = backed or not it.ok
		if i > 0 and Vector2(it.cell - items[i - 1].cell).length() < link - 1.5:
			backed = true
	var had := _had(sm)
	DragBuild.commit(cm, items)
	for s in _new(sm, had):
		bad = bad or Placement.ground_reason(sm, "relay", s.x, s.z) != ""
		sm.remove(s)
	SmokeTest._check("drag cliff backs off the wall", not bad and backed,
		"%s -> %s wall %s" % [pair.a, pair.b, pair.wall])


static func _cancel(g, cm: CommandMode) -> void:
	var sm = g.structures
	var n: int = sm.list.size()
	cm.set_tool("collector")
	cm.hover = {}
	cm.drag_plan = DragBuild.plan(cm, Vector2i(40, 74), Vector2i(46, 74))
	g.input.mouse = g.input.down_pos
	g.input._pressed[KEY_ESCAPE] = true
	g.input.left_released = true
	CommandInput.hotkeys(cm, g.input)
	CommandInput.left_mouse(cm, g.input)
	SmokeTest._check("esc during a drag places nothing", sm.list.size() == n and cm.drag_plan.is_empty())
	_silence(g)
	cm.set_tool("collector")
	cm.hover = {}
	cm.drag_plan = DragBuild.plan(cm, Vector2i(40, 74), Vector2i(46, 74))
	g.input.right_clicked = true
	g.input.left_released = true
	g.input.mouse = g.input.down_pos
	CommandInput.right_click(cm)
	CommandInput.left_mouse(cm, g.input)
	SmokeTest._check("right-click during a drag places nothing", sm.list.size() == n and cm.tool == "" and cm.drag_plan.is_empty())
	_silence(g)


static func _span(sm, type: String, span: int) -> Array:
	var grid: Grid = sm.world.grid
	var node: Structure = sm.command_node()
	var h0 := grid.height_at(node.x, node.z)
	var reach: float = maxf(node.def.link, StructureDefs.DEFS[type].link)
	for z in grid.h:
		for x in grid.w:
			var a := Vector2i(x, z)
			if Vector2(x - node.x, z - node.z).length() > reach or not _flat(sm, type, a, h0):
				continue
			for dir in DIRS:
				var ok := true
				for step in span:
					ok = ok and _flat(sm, type, a + dir * (step + 1), h0)
				if ok:
					return [a, a + dir * span]
	return []


static func _flat(sm, type: String, c: Vector2i, h0: float) -> bool:
	var grid: Grid = sm.world.grid
	return grid.in_bounds(c.x, c.y) and grid.height_at(c.x, c.y) == h0 and Placement.ground_reason(sm, type, c.x, c.y) == ""


static func _wall(g) -> Dictionary:
	var sm = g.structures
	var grid: Grid = sm.world.grid
	var link := int(StructureDefs.DEFS.relay.link)
	for id in g.castles.lays:
		for seg in g.castles.lays[id].segments:
			for wall in seg.cells:
				for dir in DIRS:
					var open := Vector2i(-1, -1)
					for i in range(1, 8):
						var c: Vector2i = wall + dir * i
						if grid.in_bounds(c.x, c.y) and Placement.ground_reason(sm, "relay", c.x, c.y) == "":
							open = c
							break
					if open.x < 0:
						continue
					var far := open
					var steps := 0
					while steps < link:
						var nxt: Vector2i = far + dir
						if not grid.in_bounds(nxt.x, nxt.y) or Placement.ground_reason(sm, "relay", nxt.x, nxt.y) != "":
							break
						far = nxt
						steps += 1
					if steps >= 3:
						var past: Vector2i = wall - dir if grid.in_bounds((wall - dir).x, (wall - dir).y) else wall
						return { "a": far, "b": past, "wall": wall }
	return {}


static func _had(sm) -> Dictionary:
	var had := {}
	for s in sm.list:
		had[s] = true
	return had


static func _new(sm, had: Dictionary) -> Array:
	var out: Array = []
	for s in sm.list:
		if not had.has(s):
			out.append(s)
	return out


static func _silence(g) -> void:
	g.input.left = false
	g.input.left_pressed = false
	g.input.left_released = false
	g.input.right_clicked = false
	g.input._pressed.clear()
