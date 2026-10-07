class_name SimBench
## GPU creeper sim checks (need a real display, not --headless):
##   --gpu-parity     CPU and GPU sims run the same level for PARITY_TICKS; prints PASS/FAIL
##   --perf-sim=N     time per tick for both sims on an N x N test grid
## Parity raises a ring wall mid-run; add --skip-upload to prove the check catches a GPU that
## never got the new heights (it must FAIL then).
## Both quit when done.

const PARITY_TICKS := 300


static func run(g, args: Dictionary) -> void:
	if RenderingServer.get_rendering_device() == null:
		print("[bench] no rendering device (headless?): GPU checks need a display")
	elif args.has("gpu-parity"):
		_parity(g)
	else:
		_perf(int(args.get("perf-sim", "256")))
	g.get_tree().quit()


static func _parity(g) -> void:
	var grid: Grid = g.level.grid
	var cpu := CreeperSim.new(grid)
	var gpu := CreeperGpu.new(grid)
	for e in g.level.emitters + g.level.vents:
		var src := { "x": e.x, "z": e.z, "amount": e.amount, "interval": e.interval }
		cpu.add_source(src)
		gpu.add_source(src)
	for c in grid.cells_in_radius(40, 40, 4.0):  # a pool on open ground, plus a removal
		cpu.set_depth(c.x, c.y, 3.0)
		gpu.set_depth(c.x, c.y, 3.0)
	for i in PARITY_TICKS:
		cpu.update(Config.CREEPER_TICK)
		gpu.update(Config.CREEPER_TICK)
		if i == 100:  # a wall across the pool's spill path: both sims must see the new heights
			for c in _ring(grid):
				grid.set_height(c.x, c.y, grid.height_at(c.x, c.y) + 4.0)
			if not OS.get_cmdline_user_args().has("--skip-upload"):
				gpu.terrain_changed([])
		if i == 150:
			cpu.remove_radius(40, 40, 3.0, 2.0)
			gpu.remove_radius(40, 40, 3.0, 2.0)
	gpu.sync()
	for c in _ring(grid):  # undo the wall (shared grid)
		grid.set_height(c.x, c.y, grid.height_at(c.x, c.y) - 4.0)
	var vol_c := 0.0
	var vol_g := 0.0
	var max_diff := 0.0
	var wet_c := 0
	var wet_g := 0
	var wet_mismatch := 0
	for i in cpu.depth.size():
		var a := cpu.depth[i]
		var b := gpu.depth[i]
		vol_c += a
		vol_g += b
		max_diff = maxf(max_diff, absf(a - b))
		var wa := a > Config.MIN_DEPTH
		var wb := b > Config.MIN_DEPTH
		wet_c += int(wa)
		wet_g += int(wb)
		wet_mismatch += int(wa != wb)
	var vol_err := absf(vol_c - vol_g) / maxf(vol_c, 0.001)
	var wet_err := float(wet_mismatch) / maxf(wet_c, 1)
	var ok := vol_err < 0.01 and max_diff < 0.05 and wet_err < 0.02
	print("[bench] parity %s ticks=%d volume cpu=%.2f gpu=%.2f (err %.4f) max_cell_diff=%.5f wet cpu=%d gpu=%d mismatch=%.4f" % [
		"PASS" if ok else "FAIL", PARITY_TICKS, vol_c, vol_g, vol_err, max_diff, wet_c, wet_g, wet_err])


static func _perf(n: int) -> void:
	var grid := Grid.new(n, n)
	var noise := Noise2D.new(3)
	for z in n:
		for x in n:
			grid.set_height(x, z, roundf(noise.fbm(x / 20.0, z / 20.0, 3) * 8.0))
	var cpu := CreeperSim.new(grid)
	var gpu := CreeperGpu.new(grid)
	for k in 8:  # emitters spread over the map so most cells end up wet
		var src := { "x": n * (k % 4 + 0.5) / 4, "z": n * (k / 4 + 0.5) / 2, "amount": 20.0, "interval": 0.2 }
		cpu.add_source(src)
		gpu.add_source(src)
	var cpu_ticks := 20
	var t0 := Time.get_ticks_usec()
	for i in cpu_ticks:
		cpu.update(Config.CREEPER_TICK)
	var cpu_ms := (Time.get_ticks_usec() - t0) / 1000.0 / cpu_ticks
	var gpu_ticks := 600
	t0 = Time.get_ticks_usec()
	for i in gpu_ticks:
		gpu.update(Config.CREEPER_TICK)
	gpu.sync()
	var gpu_ms := (Time.get_ticks_usec() - t0) / 1000.0 / gpu_ticks
	print("[bench] perf %dx%d cpu=%.2f ms/tick gpu=%.3f ms/tick (incl. readbacks every %d ticks) speedup=%.0fx" % [
		n, n, cpu_ms, gpu_ms, CreeperGpu.READBACK_TICKS, cpu_ms / maxf(gpu_ms, 0.0001)])


## Cells 5-6 from the pool centre: a ring wall that walls the pool in (parity terrain edit).
static func _ring(grid: Grid) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in grid.cells_in_radius(40, 40, 6.0):
		if Vector2(c.x - 40, c.y - 40).length() > 5.0:
			out.append(c)
	return out
