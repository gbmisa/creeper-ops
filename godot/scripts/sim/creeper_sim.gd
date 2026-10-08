class_name CreeperSim
extends RefCounted
## Heightfield fluid automaton (Creeper World style). Each cell holds a creeper depth.
## Every tick creeper flows toward neighbours whose (terrain + creeper) "head" is lower,
## so it pools in basins and spills over ridges. Rules follow docs/CREEPER_SPEC.md (CW3).
## This class is the CPU sim and the shared interface. CreeperGpu (creeper_gpu.gd) runs the
## same rule as a compute shader and keeps `depth` as a CPU copy for gameplay. Always create
## sims with CreeperSim.create(): headless (no rendering device) or --cpu-sim gets the CPU one.
## Gameplay must change creeper only through add/remove/set_depth, never by writing `depth`.

var grid: Grid
var depth := PackedFloat32Array()
var _delta := PackedFloat32Array()
var sources: Array[Dictionary] = []
var _acc := 0.0
var ticks := 0


static func create(g: Grid) -> CreeperSim:
	if RenderingServer.get_rendering_device() != null and not OS.get_cmdline_user_args().has("--cpu-sim"):
		return CreeperGpu.new(g)
	return CreeperSim.new(g)


func _init(g: Grid) -> void:
	grid = g
	depth.resize(g.w * g.h)
	_delta.resize(g.w * g.h)


## src: { x, z, amount, interval, start?, cap? }. CW3 emitter: every `interval` s from `start` s
## (0 fires on the first tick) it raises its cell UP TO `amount` depth, adding only the gap, so a
## pooled emitter slows down. Returns the live dict (set "active" false to stop).
func add_source(src: Dictionary) -> Dictionary:
	var s := src.duplicate()
	s["timer"] = float(s.interval) - float(s.get("start", 0.0))
	s["active"] = true
	sources.append(s)
	return s


func update(dt: float) -> void:
	_acc += dt
	while _acc >= Config.CREEPER_TICK:
		_acc -= Config.CREEPER_TICK
		_emit(Config.CREEPER_TICK)
		_flow()
		ticks += 1


func _emit(dt: float) -> void:
	for s in sources:
		if not s.active:
			continue
		if s.has("cap") and depth_at(s.x, s.z) >= s.cap:
			continue  # pressure-limited source
		s.timer += dt
		if s.timer >= s.interval:
			s.timer -= s.interval
			raise(s.x, s.z, s.amount)


## CW3 flow: each east and south edge is handled once from a snapshot. The move is
## FLOW_RATE x head difference, clamped so neither side gives more than FLOW_RATE of its own
## depth; the same amount leaves one cell and enters the other, so volume is conserved.
func _flow() -> void:
	var w := grid.w
	var hh := grid.h
	var height := grid.height
	_delta.fill(0.0)
	var mu := Config.FLOW_RATE
	for z in hh:
		var row := z * w
		for x in w:
			var i := row + x
			var d := depth[i]
			var head := height[i] + d
			if x + 1 < w:
				var de := depth[i + 1]
				if d > 0.0 or de > 0.0:
					var f := clampf(mu * (head - height[i + 1] - de), -mu * de, mu * d)
					_delta[i] -= f
					_delta[i + 1] += f
			if z + 1 < hh:
				var ds := depth[i + w]
				if d > 0.0 or ds > 0.0:
					var f := clampf(mu * (head - height[i + w] - ds), -mu * ds, mu * d)
					_delta[i] -= f
					_delta[i + w] += f
	var dry := Config.CREEPER_DRY
	for i in depth.size():
		var v := depth[i] + _delta[i]
		depth[i] = 0.0 if v < dry else minf(v, Config.MAX_DEPTH)


func is_gpu() -> bool:
	return false


## Terrain heights changed under these cells (TerrainEdit). The CPU sim reads grid.height live.
func terrain_changed(_cells: Array) -> void:
	pass


func set_depth(x: int, z: int, v: float) -> void:
	if grid.in_bounds(x, z):
		depth[z * grid.w + x] = clampf(v, 0.0, Config.MAX_DEPTH)


func depth_at(x: int, z: int) -> float:
	return depth[z * grid.w + x] if grid.in_bounds(x, z) else 0.0


## Depth under a world point.
func depth_world(p: Vector3) -> float:
	var c := grid.world_to_cell(p.x, p.z)
	return depth_at(c.x, c.y)


func add(x: int, z: int, amount: float) -> void:
	if grid.in_bounds(x, z):
		var i := z * grid.w + x
		depth[i] = minf(depth[i] + amount, Config.MAX_DEPTH)


## Raise a cell to at least `v` (CW3 emitter burst). Adds only the gap.
func raise(x: int, z: int, v: float) -> void:
	if grid.in_bounds(x, z):
		var i := z * grid.w + x
		depth[i] = maxf(depth[i], minf(v, Config.MAX_DEPTH))


func remove(x: int, z: int, amount: float) -> float:
	if not grid.in_bounds(x, z):
		return 0.0
	var i := z * grid.w + x
	var r := minf(depth[i], amount)
	depth[i] -= r
	return r


## Remove creeper in a radius with linear falloff.
func remove_radius(cx: int, cz: int, r: float, amount: float) -> float:
	var removed := 0.0
	for c in grid.cells_in_radius(cx, cz, r):
		var dist := Vector2(c.x - cx, c.y - cz).length()
		removed += remove(c.x, c.y, amount * (1.0 - dist / (r + 1.0)))
	return removed


## Nearest wet cell within range, or null. "Wet" is the same threshold the renderer uses,
## so anything you can see, weapons will shoot.
func nearest_wet(cx: int, cz: int, r: float) -> Variant:
	var best: Variant = null
	var bd := INF
	for c in grid.cells_in_radius(cx, cz, r):
		if depth[c.y * grid.w + c.x] > Config.MIN_DEPTH:
			var d := Vector2(c.x - cx, c.y - cz).length_squared()
			if d < bd:
				bd = d
				best = c
	return best


## Deepest cell within range (artillery prefers big pools). CW4: lobbing from high ground
## reaches further, +per_level cells for each level the target sits below `from_h`.
## `min_cheb`: skip the square of that half-size around the gun (CW3 Bertha: 5).
func deepest_wet(cx: int, cz: int, r: float, from_h := -1.0, per_level := 0.0, min_cheb := 0) -> Variant:
	var best: Variant = null
	var bd := Config.MIN_DEPTH
	var reach := r + maxf(0.0, from_h) * per_level
	for c in grid.cells_in_radius(cx, cz, reach):
		var d := depth[c.y * grid.w + c.x]
		if d > bd and (min_cheb <= 0 or maxi(absi(c.x - cx), absi(c.y - cz)) > min_cheb):
			if per_level > 0.0:
				var drop := maxf(0.0, from_h - grid.height_at(c.x, c.y))
				if Vector2(c.x - cx, c.y - cz).length() > r + drop * per_level:
					continue
			bd = d
			best = c
	return best


func coverage() -> float:
	var wet := 0
	for d in depth:
		if d > Config.MIN_DEPTH:
			wet += 1
	return float(wet) / depth.size()
