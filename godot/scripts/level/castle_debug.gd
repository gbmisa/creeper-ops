class_name CastleDebug
## Stage 21 command-line hooks (Debug.apply hands every arg here):
##   --castle2=I[,spot]  drop the Operative at concentric castle I (index in castles.list):
##                       gate (outside the outer gate, default), gatehall, bailey, tower (inside a
##                       corner tower stair), wall (outer wall walk), hall (keep hall), roof (keep roof)
##   --stage=I,N         castle I hostile with its first N rings taken (0 gate, 1 bailey, 2 keep)
##   --held=I            castle I held (perks on), e.g. with --look to see the ward drain
##   --engines=I         a cannon in reach of castle I's trebuchets, which fire at once (ring shots)


static func apply(g, args: Dictionary) -> void:
	if args.has("stage"):
		var p: PackedStringArray = args.stage.split(",")
		var c: Dictionary = g.castles.list[int(p[0])]
		CastleStages.set_stage(g.castles, c, int(p[1]) if p.size() > 1 else 1)
	if args.has("held"):
		var hc: Dictionary = g.castles.list[int(args.held)]
		StrongholdRules.to_held(g.surface, hc, g.castles.lays[hc.id])
		StrongholdMeshes.refresh(g.castles.views[hc.id], hc)
	if args.has("engines"):
		var ec: Dictionary = g.castles.list[int(args.engines)]
		var e0: Dictionary = ec.engines[0]
		var out: Vector2i = (e0.post - g.castles.lays[ec.id].rect.get_center()).sign()
		var at: Vector2i = e0.post + out * 16
		g.structures.place("cannon", at.x, at.y, true)
		for e in ec.engines:
			e.cd = 0.2
	if args.has("castle2"):
		_drop(g, args.castle2.split(","))


static func _drop(g, p: PackedStringArray) -> void:
	var c: Dictionary = g.castles.list[int(p[0])]
	var lay: Dictionary = g.castles.lays[c.id]
	var spot: String = p[1] if p.size() > 1 else "gate"
	var grid: Grid = g.level.grid
	var r: Rect2i = lay.rect
	var centre: Vector2i = r.position + r.size / 2
	var g0: Dictionary = lay.gates[0]
	var at: Vector2i = centre
	var look: Vector2i = centre
	var y := -1.0
	match spot:
		"gate":
			at = g0.outer.back() + (g0.outer.back() - g0.cells[0]).sign() * 5
			look = g0.cells[0]
		"gatehall":
			at = lay.zones.gate.cells[7]
			look = lay.zones.gate.cells[1]
		"bailey":
			at = lay.zones.bailey.cells[4] + (lay.zones.bailey.cells[4] - centre).sign() * 2
			look = centre
		"tower":
			var t: Dictionary = lay.towers[0]
			at = t.centre + CastleStairs.RING[(CastleStairs.RING.find(t.hatch - t.centre) + 4) % 8]
			look = t.hatch
		"wall":
			var seg: Dictionary = lay.segments[1]
			at = seg.cells[1]
			look = centre
		"hall":
			at = lay.zones.keep.cells[lay.zones.keep.cells.size() - 1]
			look = lay.crown_at.cell
		"roof":
			at = lay.keep.door[0] + (centre - lay.keep.door[0]).sign()
			look = lay.gates[0].cells[0]
			y = float(grid.roof[grid.idx(at.x, at.y)]) * Config.LEVEL_H
	DebugHooks._drop(g, g.level.landing_hint.x, g.level.landing_hint.y - 4, 0.0)
	g.fps.controller.spawn(grid, at.x, at.y, atan2(-(look.x - at.x), -(look.y - at.y)))
	if y > 0.0:
		g.fps.controller.pos.y = y
		g.fps.controller.on_ground = true
	g.fps.controller.pitch = 0.05 if spot != "roof" else -0.25
