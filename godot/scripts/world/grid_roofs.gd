class_name GridRoofs
## Castle interiors on a heightfield (Stage 21, docs/CASTLES2_DESIGN.md §2). `Grid.roof[i]` is a
## walkable slab `roof` levels up over the cell's floor (`height`). Only the Operative sees it:
## the creeper sim, raiders, units and structures keep using the floor, so creeper flows in
## through doors and under roofs by the usual cell rule.
##  - Upper layer: feet within a step of the roof (feet >= roof - CLIMB) -> the roof is ground.
##  - Lower layer: the roof is a ceiling ROOF_THICK thick; the head stops under it.
## Roofs only go where floor-to-roof headroom is >= 2 levels, so the layers never mix.
## Grid.raycast treats the slab as solid (shots, sight lines, command-view picks).

const ROOF_THICK := 0.5     # metres of slab under the roof level
const RAY_BAND := 0.6       # metres of slab that stops rays (must be >= the raycast step, 0.5)
const HEAD := 1.85          # metres from the Operative's feet to the top of the head
const CLIFF := 1.5          # levels: a castle neighbour further away than this is a wall, not a slope


static func roof_at(g: Grid, x: int, z: int) -> float:
	return g.roof[z * g.w + x] if g.in_bounds(x, z) else 0.0


## True when a walker with feet at `feet_y` (metres) treats the roof over cell i as ground.
static func upper(g: Grid, i: int, feet_y: float) -> bool:
	var r := g.roof[i]
	return r > 0.0 and feet_y / Config.LEVEL_H >= r - Config.CLIMB - 0.05


## Height in levels the Operative meets on cell (x, z) from feet at `feet_y`: the roof when
## on top of it; under it, the floor (gates and decks as for any player walker), or a wall
## when the ceiling is too low for the body to fit from this height.
static func op_height(g: Grid, x: int, z: int, feet_y: float) -> float:
	if not g.in_bounds(x, z):
		return 99.0
	var i := z * g.w + x
	var r := g.roof[i]
	if r <= 0.0:
		return g.walk_height(x, z, Grid.Faction.PLAYER)
	if upper(g, i, feet_y):
		return r
	if maxf(feet_y, g.height[i] * Config.LEVEL_H) + HEAD > r * Config.LEVEL_H - ROOF_THICK + 0.01:
		return 99.0
	return g.walk_height(x, z, Grid.Faction.PLAYER)


## Where the Operative stands: Grid.stand_y, with roofs the feet are on counted as ground.
## Castle stone (walls, stairs, interiors) stands flat: a neighbour more than CLIFF levels
## away doesn't bend the floor, so 1-wide stairs and passages don't lift you up their walls
## (TERRACE_BAND ramps a level change over 2/3 of a cell). Steps of one level stay smooth.
static func stand_y(g: Grid, wx: float, wz: float, feet_y: float) -> float:
	var me := g.world_to_cell(wx, wz)
	if not g.in_bounds(me.x, me.y):
		return g.stand_y(wx, wz, Grid.Faction.PLAYER)
	var mi := me.y * g.w + me.x
	var fx := wx / Config.CELL - 0.5
	var fz := wz / Config.CELL - 0.5
	var x0 := floori(fx)
	var z0 := floori(fz)
	var idx: Array[int] = []
	var any := false
	for c in [Vector2i(x0, z0), Vector2i(x0 + 1, z0), Vector2i(x0, z0 + 1), Vector2i(x0 + 1, z0 + 1)]:
		var i := clampi(c.y, 0, g.h - 1) * g.w + clampi(c.x, 0, g.w - 1)
		idx.append(i)
		any = any or g.roof[i] > 0.0
	var castle := any or g.material[mi] == Grid.Mat.STONE or g.material[mi] == Grid.Mat.SPIRE
	if not castle:
		return g.stand_y(wx, wz, Grid.Faction.PLAYER)
	var own := _layer(g, mi, feet_y)
	var hs: Array[float] = []
	for i in idx:
		var hh := _layer(g, i, feet_y)
		hs.append(hh if absf(hh - own) <= CLIFF else own)
	var tx := Grid.terrace(fx - x0)
	var tz := Grid.terrace(fz - z0)
	return lerpf(lerpf(hs[0], hs[1], tx), lerpf(hs[2], hs[3], tx), tz) * Config.LEVEL_H


## Level the Operative's feet meet on cell i: its roof when on top of it, else deck or floor.
static func _layer(g: Grid, i: int, feet_y: float) -> float:
	if upper(g, i, feet_y):
		return g.roof[i]
	return g._hf(i % g.w, i / g.w, Grid.Faction.PLAYER)


## Lowest slab underside (metres) over the body square at (wx, wz) for feet at `feet_y`, or INF.
static func ceiling(g: Grid, wx: float, wz: float, feet_y: float) -> float:
	var out := INF
	var r := Config.OP_RADIUS
	for o in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var c := g.world_to_cell(wx + o.x, wz + o.y)
		if not g.in_bounds(c.x, c.y):
			continue
		var i := c.y * g.w + c.x
		if g.roof[i] > 0.0 and not upper(g, i, feet_y):
			out = minf(out, g.roof[i] * Config.LEVEL_H - ROOF_THICK)
	return out


## Is world point p inside a roof slab? (Grid.raycast: roofs stop rays.)
static func in_slab(g: Grid, p: Vector3) -> bool:
	var x := floori(p.x / Config.CELL)
	var z := floori(p.z / Config.CELL)
	if not g.in_bounds(x, z):
		return false
	var r := g.roof[z * g.w + x]
	if r <= 0.0:
		return false
	var top := r * Config.LEVEL_H
	return p.y <= top and p.y >= top - RAY_BAND


## Is the point under a roof (inside an interior)?
static func covered(g: Grid, p: Vector3) -> bool:
	var c := g.world_to_cell(p.x, p.z)
	var r := roof_at(g, c.x, c.y)
	return r > 0.0 and p.y < r * Config.LEVEL_H - ROOF_THICK


## Every (x, z, level) the Operative can walk to from `from` (standing on its floor), roofs and
## drops included, no jumps: Vector3i(x, z, level) -> true. For smoke checks and level tools.
static func walkable(g: Grid, from: Vector2i, limit := 200000) -> Dictionary:
	var start := Vector3i(from.x, from.y, int(g.walk_height(from.x, from.y, Grid.Faction.PLAYER)))
	var seen := { start: true }
	var queue: Array[Vector3i] = [start]
	var head := 0
	while head < queue.size() and seen.size() < limit:
		var s: Vector3i = queue[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var x: int = s.x + d.x
			var z: int = s.y + d.y
			var lvl := op_height(g, x, z, s.z * Config.LEVEL_H)
			if lvl >= 99.0 or lvl - s.z > Config.CLIMB:
				continue
			var n := Vector3i(x, z, int(roundf(lvl)))
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen


## True when `walkable` reached `cell` at `level` (any level when level < 0).
static func reached(seen: Dictionary, cell: Vector2i, level := -1) -> bool:
	if level >= 0:
		return seen.has(Vector3i(cell.x, cell.y, level))
	for k in seen:
		if k.x == cell.x and k.y == cell.y:
			return true
	return false
