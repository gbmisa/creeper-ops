class_name CreeperStrike
## CW3 weapon removal patterns (docs/CREEPER_SPEC.md §4). Works on any CreeperSim through
## remove(), so the GPU sim gets the same changes. Disks are open: squared distance < r².


## Pulse cannon: `hits` subtractions of `per_hit`, nearest cells first, only cells at or below
## the impact terrain. The impact cell is tested twice. A cell holding less than a full hit is
## cleared and still uses the hit. Returns the depth removed.
static func hits(sim: CreeperSim, cx: int, cz: int, r: float, count: int, per_hit: float) -> float:
	var g := sim.grid
	var top := g.height_at(cx, cz)
	var removed := 0.0
	var left := count
	for c in _rings(g, cx, cz, r):
		if left <= 0:
			break
		if g.height_at(c.x, c.y) > top:
			continue
		var tries := 2 if c.x == cx and c.y == cz else 1
		for k in tries:
			if left <= 0 or sim.depth_at(c.x, c.y) <= 0.0:
				break
			removed += sim.remove(c.x, c.y, per_hit)
			left -= 1
	return removed


## Mortar / Bertha: every wet cell in the disk loses `per_cell`; terrain is ignored. The impact
## cell takes a second hit if creeper is left after the first.
static func disk(sim: CreeperSim, cx: int, cz: int, r: float, per_cell: float) -> float:
	var g := sim.grid
	var removed := 0.0
	var ri := ceili(r)
	for dz in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			if dx * dx + dz * dz >= r * r:
				continue
			var x := cx + dx
			var z := cz + dz
			if g.in_bounds(x, z) and sim.depth_at(x, z) > 0.0:
				removed += sim.remove(x, z, per_cell)
	if sim.depth_at(cx, cz) > 0.0:
		removed += sim.remove(cx, cz, per_cell)
	return removed


static var _offsets := {}  # r -> Array[Vector2i] sorted nearest first


## Cells of the open disk sorted nearest first (ties in a fixed order).
static func _rings(g: Grid, cx: int, cz: int, r: float) -> Array:
	if not _offsets.has(r):
		var out := []
		var ri := ceili(r)
		for dz in range(-ri, ri + 1):
			for dx in range(-ri, ri + 1):
				if dx * dx + dz * dz < r * r:
					out.append(Vector2i(dx, dz))
		out.sort_custom(func(a, b):
			var da: int = a.x * a.x + a.y * a.y
			var db: int = b.x * b.x + b.y * b.y
			return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
		_offsets[r] = out
	var cells := []
	for o in _offsets[r]:
		if g.in_bounds(cx + o.x, cz + o.y):
			cells.append(Vector2i(cx + o.x, cz + o.y))
	return cells
