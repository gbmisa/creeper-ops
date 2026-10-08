class_name HiveShape
## Hive footprint stamped while the level is built, before snapshot_base (§3.3).
## One Earth berm ring with three gaps. A cell rises only when every neighbour can
## still be climbed (at most +1), so a steep knoll keeps an inner ring instead of a cliff.
## Blight fills the bowl inside the ring that actually rose. r = 6 is the outer claim.


const OUTER_0 := 5.05
const OUTER_1 := 6.15
const INNER_0 := 2.55
const INNER_1 := 3.45
const OFFSETS := {
	"core": Vector2i(0, 0),
	"pit_a": Vector2i(2, 0),
	"pit_b": Vector2i(-2, 0),
	"pit_c": Vector2i(0, 2),
	"spitter_a": Vector2i(2, 1),
	"spitter_b": Vector2i(-1, 2),
	"launcher": Vector2i(1, -2),
	"mortar": Vector2i(-2, -1),
	"roost": Vector2i(-2, 1),
}


static func stamp_all(g: Grid, rows: Array) -> void:
	for row in rows:
		var d: Dictionary = row
		var plan := stamp(g, int(d.x), int(d.z))
		d["blight"] = plan.blight
		d["slots"] = plan.slots
		d["floor"] = plan.floor
		d["raised"] = plan.raised
		d["sample"] = plan.sample


static func cells(g: Grid, x: int, z: int) -> Dictionary:
	var floor_h := roundf(g.height_at(x, z))
	return _pack(g, x, z, floor_h, INNER_1, 0, Vector2i(-1, -1))


static func stamp(g: Grid, x: int, z: int) -> Dictionary:
	var floor_h := roundf(g.height_at(x, z))
	var raised := _ring(g, x, z, OUTER_0, OUTER_1, floor_h)
	var blight_r := OUTER_0
	if raised < 8:
		raised += _ring(g, x, z, INNER_0, INNER_1, floor_h)
		blight_r = INNER_0
	var sample := Vector2i(-1, -1)
	for c in g.cells_in_radius(x, z, OUTER_1):
		if g.material[g.idx(c.x, c.y)] == Grid.Mat.EARTH and absf(g.height_at(c.x, c.y) - (floor_h + 1.0)) < 0.01:
			sample = c
			break
	return _pack(g, x, z, floor_h, blight_r, raised, sample)


static func _pack(g: Grid, x: int, z: int, floor_h: float, blight_r: float, raised: int, sample: Vector2i) -> Dictionary:
	var blight: Array = []
	for c in g.cells_in_radius(x, z, blight_r):
		var i := g.idx(c.x, c.y)
		var mat := g.material[i]
		if mat == Grid.Mat.SPIRE or mat == Grid.Mat.STONE or mat == Grid.Mat.PLATED:
			continue
		g.zone[i] = Grid.Zone.BLIGHT
		blight.append(c)
	var slots := {}
	for id in OFFSETS.keys():
		var o := OFFSETS[id] as Vector2i
		slots[str(id)] = Vector2i(x + o.x, z + o.y)
	return { "floor": floor_h, "blight": blight, "slots": slots, "raised": raised, "sample": sample }


static func _ring(g: Grid, x: int, z: int, r0: float, r1: float, floor_h: float) -> int:
	var raised := 0
	var target := minf(floor_h + 1.0, float(Config.SPIRE_MAX_LEVEL))
	for c in g.cells_in_radius(x, z, r1):
		var dist := Vector2(c.x - x, c.y - z).length()
		if dist < r0 or dist > r1 or _gap(c.x - x, c.y - z):
			continue
		var i := g.idx(c.x, c.y)
		if g.material[i] != Grid.Mat.NATURAL and g.material[i] != Grid.Mat.EARTH:
			continue
		var cap := target
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var nx: int = c.x + d.x
			var nz: int = c.y + d.y
			if g.in_bounds(nx, nz):
				cap = minf(cap, g.height_at(nx, nz) + 1.0)
		cap = roundf(maxf(g.height_at(c.x, c.y), cap))
		if cap <= g.height_at(c.x, c.y) + 0.01:
			continue
		g.set_height(c.x, c.y, cap)
		g.material[i] = Grid.Mat.EARTH
		raised += 1
	return raised


## Three doors, fixed angles, so a ring is never a closed wall.
static func _gap(dx: int, dz: int) -> bool:
	if dx == 0 and dz == 0:
		return false
	var a := atan2(float(dz), float(dx))
	for base in [0.35, 2.45, 4.55]:
		if absf(angle_difference(a, base)) < 0.42:
			return true
	return false
