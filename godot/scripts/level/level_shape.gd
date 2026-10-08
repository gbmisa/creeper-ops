class_name LevelShape
## Terrain shaping helpers shared by level files (Level 2 uses them; level01.gd keeps its own
## copies until it adopts these). All heights are CW3 levels; call `round_levels` last.


static func smoothstep(a: float, b: float, t: float) -> float:
	var k := clampf((t - a) / (b - a), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


static func disc(g: Grid, cx: int, cz: int, r: float, fn: Callable) -> void:
	for c in g.cells_in_radius(cx, cz, r):
		fn.call(c.x, c.y, Vector2(c.x - cx, c.y - cz).length())


static func rect(g: Grid, x0: int, z0: int, x1: int, z1: int, fn: Callable) -> void:
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			if g.in_bounds(x, z):
				fn.call(x, z)


static func set_rect(g: Grid, x0: int, z0: int, x1: int, z1: int, v: float) -> void:
	rect(g, x0, z0, x1, z1, func(x, z): g.set_height(x, z, v))


static func blight(g: Grid, cx: int, cz: int, r: float) -> void:
	disc(g, cx, cz, r, func(x, z, _d): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)


static func blight_rect(g: Grid, x0: int, z0: int, x1: int, z1: int) -> void:
	rect(g, x0, z0, x1, z1, func(x, z): g.zone[g.idx(x, z)] = Grid.Zone.BLIGHT)


## A hollow: heights ease down to `floor_h` inside r0, and back to the terrain at r1.
static func bowl(g: Grid, cx: int, cz: int, r0: float, r1: float, floor_h: float) -> void:
	disc(g, cx, cz, r1, func(x, z, d):
		g.set_height(x, z, floor_h + (g.height_at(x, z) - floor_h) * smoothstep(r0, r1, d)))


## A raised disc: `top` inside r0, easing back to the terrain at r1.
static func mesa(g: Grid, cx: int, cz: int, r0: float, r1: float, top: float) -> void:
	disc(g, cx, cz, r1, func(x, z, d):
		var hh := g.height_at(x, z)
		g.set_height(x, z, maxf(hh, top - (top - hh) * smoothstep(r0, r1, d))))


## Flat pad at `level` over `r`, blended into the terrain: a cell d cells outside the pad
## may differ from `level` by at most d, so a walker can always climb on or off.
static func pad(g: Grid, r: Rect2i, margin: int, level: float) -> void:
	var a := r.grow(margin)
	for z in range(a.position.y, a.end.y):
		for x in range(a.position.x, a.end.x):
			if not g.in_bounds(x, z):
				continue
			var d := maxi(maxi(r.position.x - x, x - (r.end.x - 1)), maxi(r.position.y - z, z - (r.end.y - 1)))
			if d <= 0:
				g.set_height(x, z, level)
			else:
				g.set_height(x, z, clampf(g.height_at(x, z), level - d, level + d))


## Makes the whole heightfield 1-Lipschitz (no step over one level between 8-neighbours) by
## lowering peaks: a two-pass chamfer, exact and O(cells).
static func limit_slope(g: Grid) -> void:
	for pass_i in 2:
		var zs := range(g.h) if pass_i == 0 else range(g.h - 1, -1, -1)
		var xs := range(g.w) if pass_i == 0 else range(g.w - 1, -1, -1)
		var back: int = -1 if pass_i == 0 else 1
		for z in zs:
			for x in xs:
				var m := g.height_at(x, z)
				for d in [Vector2i(back, 0), Vector2i(back, back), Vector2i(0, back), Vector2i(-back, back)]:
					if g.in_bounds(x + d.x, z + d.y):
						m = minf(m, g.height_at(x + d.x, z + d.y) + 1.0)
				g.set_height(x, z, m)


## Stair ramp from `a` (level h0) towards `b`, `width` cells wide, `per_level` cells per level,
## stopping where it meets the ground. Returns the end cell.
static func ramp(g: Grid, a: Vector2i, b: Vector2i, width: int, h0: float, per_level: float, rising := false) -> Vector2i:
	var dir := Vector2(b - a)
	var len := dir.length()
	dir /= len
	var side := Vector2(-dir.y, dir.x)
	var end := a
	for i in int(len):
		var hz := h0 + (i / per_level) * (1.0 if rising else -1.0)
		var mid := Vector2i((Vector2(a) + dir * i).round())
		if g.in_bounds(mid.x, mid.y) and ((not rising and hz <= g.height_at(mid.x, mid.y)) or (rising and hz >= g.height_at(mid.x, mid.y))):
			break
		for w in range(-(width / 2), width / 2 + 1):
			var c := Vector2i((Vector2(a) + dir * i + side * w).round())
			if g.in_bounds(c.x, c.y):
				g.set_height(c.x, c.y, floorf(hz))
		end = mid
	return end


static func round_levels(g: Grid) -> void:
	for i in g.height.size():
		g.height[i] = clampf(roundf(g.height[i]), 0.0, Config.MAX_LEVEL)


## Whole-level dry-land flood fill with the Operative's climb limit (drops are free).
## Returns { cell: true } for every cell reachable from `start`.
static func walkable_from(g: Grid, start: Vector2i, faction := Grid.Faction.PLAYER) -> Dictionary:
	var seen := { start: true }
	var open := [start]
	while not open.is_empty():
		var a: Vector2i = open.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var b: Vector2i = a + d
			if not seen.has(b) and g.step_ok(a.x, a.y, b.x, b.y, Config.CLIMB, 99.0, faction):
				seen[b] = true
				open.append(b)
	return seen
