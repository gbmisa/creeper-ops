class_name CreeperGpu
extends CreeperSim
## The creeper sim on the GPU: creeper_flow.glsl on the main rendering device, so the creeper
## mesh samples the result directly (Texture2DRD, no upload). Same rule and tick as the CPU sim.
## `depth` stays a CPU copy for gameplay queries, refreshed every READBACK_TICKS with an async
## readback (at most ~0.3 s old). add/remove/set_depth change the copy at once and queue the
## same change for the GPU, so a weapon sees its own hit in the same frame. Changes made while
## a readback is in flight are re-applied when it lands. Several readbacks due inside one frame
## means a fast-forward (--sim): those block instead, so gameplay never runs on a stale copy.
## Uses the default (non-separate) render thread model, so RD calls run on this thread.

const READBACK_TICKS := 4
const MAX_DELTAS := 8192

var rd: RenderingDevice
var depth_tex := Texture2DRD.new()
var surf_tex := Texture2DRD.new()
var _shader: RID
var _pipeline: RID
var _rids: Array[RID] = []
var _height: RID
var _depth: RID
var _deltas: RID
var _uset: RID
var _queue := {}  # cell index -> [mode, amount]; flushed to the GPU each tick
var _log := {}    # changes since the in-flight readback was requested
var _rb_busy := false
var _rb_tick := -999
var _rb_frame := -1
var _gen := 0


func _init(g: Grid) -> void:
	super(g)
	rd = RenderingServer.get_rendering_device()
	var file: RDShaderFile = load("res://shaders/creeper_flow.glsl")
	_shader = rd.shader_create_from_spirv(file.get_spirv())
	_pipeline = rd.compute_pipeline_create(_shader)
	var n := g.w * g.h
	_height = _tex(RenderingDevice.DATA_FORMAT_R32_SFLOAT, g.height.to_byte_array(), true)
	_depth = _tex(RenderingDevice.DATA_FORMAT_R32_SFLOAT, depth.to_byte_array(), true)
	var zeros := PackedByteArray()
	zeros.resize(n * 16)
	var out := _tex(RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT, zeros, false)
	var hidden := PackedFloat32Array()
	hidden.resize(n)
	hidden.fill(-CreeperMesh.HIDDEN)
	var surf := _tex(RenderingDevice.DATA_FORMAT_R32_SFLOAT, hidden.to_byte_array(), true)
	_deltas = rd.storage_buffer_create(MAX_DELTAS * 16)
	_rids.append(_deltas)
	var us: Array[RDUniform] = []
	for pair in [[0, _height], [1, _depth], [2, out], [3, surf]]:
		us.append(_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, pair[0], pair[1]))
	us.append(_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4, _deltas))
	_uset = rd.uniform_set_create(us, _shader, 0)
	depth_tex.texture_rd_rid = _depth
	surf_tex.texture_rd_rid = surf


func _tex(fmt: int, data: PackedByteArray, sampled: bool) -> RID:
	var f := RDTextureFormat.new()
	f.width = grid.w
	f.height = grid.h
	f.format = fmt
	f.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	if sampled:
		f.usage_bits |= RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	var rid := rd.texture_create(f, RDTextureView.new(), [data])
	_rids.append(rid)
	return rid


static func _uniform(type: int, binding: int, rid: RID) -> RDUniform:
	var u := RDUniform.new()
	u.uniform_type = type
	u.binding = binding
	u.add_id(rid)
	return u


func is_gpu() -> bool:
	return true


func update(dt: float) -> void:
	_acc += dt
	var ran := false
	while _acc >= Config.CREEPER_TICK:
		_acc -= Config.CREEPER_TICK
		_emit(Config.CREEPER_TICK)
		_tick()
		ticks += 1
		ran = true
	if not ran:
		return
	_run([3])
	if ticks - _rb_tick >= READBACK_TICKS:
		_readback()


## One sim tick: queued changes, then the edge exchange and apply.
func _tick() -> void:
	var keys := _queue.keys()
	var start := 0
	while start < keys.size():  # chunks of MAX_DELTAS; cells are unique so order is free
		var count := mini(MAX_DELTAS, keys.size() - start)
		var buf := PackedByteArray()
		buf.resize(count * 16)
		for k in count:
			var i: int = keys[start + k]
			var e: Array = _queue[i]
			buf.encode_s32(k * 16, i)
			buf.encode_float(k * 16 + 4, e[1])
			buf.encode_s32(k * 16 + 8, e[0])
		rd.buffer_update(_deltas, 0, buf.size(), buf)
		_run([0], count)
		start += count
	_queue.clear()
	_run([1, 2])


func _run(passes: Array, count := 0) -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, _pipeline)
	rd.compute_list_bind_uniform_set(cl, _uset, 0)
	for k in passes.size():
		if k > 0:
			rd.compute_list_add_barrier(cl)
		var pc := PackedInt32Array([grid.w, grid.h, passes[k], count]).to_byte_array()
		pc.append_array(PackedFloat32Array([Config.FLOW_RATE, Config.MAX_DEPTH, Config.MIN_DEPTH, Config.CREEPER_DRY,
			CreeperMesh.MIN_VIS, CreeperMesh.SHORE_DIP, CreeperMesh.HIDDEN, 0.0]).to_byte_array())
		rd.compute_list_set_push_constant(cl, pc, pc.size())
		if passes[k] == 0:
			rd.compute_list_dispatch(cl, ceili(count / 64.0), 1, 1)
		else:
			rd.compute_list_dispatch(cl, ceili(grid.w / 8.0), ceili(grid.h / 8.0), 1)
	rd.compute_list_end()


func _readback() -> void:
	_rb_tick = ticks
	var frame := Engine.get_process_frames()
	if frame == _rb_frame:  # second readback this frame: fast-forward, so block
		_gen += 1           # anything still in flight is older than this
		_rb_busy = false
		_take(rd.texture_get_data(_depth, 0), {})
		return
	_rb_frame = frame
	if _rb_busy:
		return
	_rb_busy = true
	_log = {}
	var gen := _gen
	rd.texture_get_data_async(_depth, 0, func(data: PackedByteArray): _landed(data, gen))


## Blocking readback: the CPU copy matches the GPU exactly afterwards (tests, benchmarks).
func sync() -> void:
	_gen += 1
	_rb_busy = false
	_rb_tick = ticks
	_take(rd.texture_get_data(_depth, 0), {})


func _landed(data: PackedByteArray, gen: int) -> void:
	if gen != _gen:
		return
	_rb_busy = false
	_take(data, _log)


func _take(data: PackedByteArray, changes: Dictionary) -> void:
	depth = data.to_float32_array()
	for i in changes:
		var e: Array = changes[i]
		depth[i] = clampf(_apply(e, depth[i]), 0.0, Config.MAX_DEPTH)


static func _apply(e: Array, v: float) -> float:
	match e[0]:
		1: return e[1]
		2: return maxf(v, e[1])
	return v + e[1]


func _change(i: int, mode: int, amount: float) -> void:
	_merge(_queue, i, mode, amount, depth[i])
	if _rb_busy:
		_merge(_log, i, mode, amount, depth[i])


## Queued change per cell (mode 0 add, 1 set, 2 raise to). `now` is the CPU copy after this
## change, used when a raise lands on a queued add: that pair becomes a set.
static func _merge(d: Dictionary, i: int, mode: int, amount: float, now := 0.0) -> void:
	var e = d.get(i)
	if e == null or mode == 1:
		d[i] = [mode, amount]
	elif mode == 2:
		if e[0] == 0:
			d[i] = [1, now]
		else:
			e[1] = maxf(e[1], amount)
	elif e[0] == 2:
		d[i] = [1, maxf(now, 0.0)]  # an add after a raise: fold into a set
	else:
		e[1] += amount  # adding onto a queued add or set


func add(x: int, z: int, amount: float) -> void:
	super(x, z, amount)
	if grid.in_bounds(x, z):
		_change(z * grid.w + x, 0, amount)


func raise(x: int, z: int, v: float) -> void:
	super(x, z, v)
	if grid.in_bounds(x, z):
		_change(z * grid.w + x, 2, minf(v, Config.MAX_DEPTH))


## Returns what the CPU copy held (an estimate); the GPU removes up to the full amount.
func remove(x: int, z: int, amount: float) -> float:
	var r := super(x, z, amount)
	if grid.in_bounds(x, z):
		_change(z * grid.w + x, 0, -amount)
	return r


func set_depth(x: int, z: int, v: float) -> void:
	super(x, z, v)
	if grid.in_bounds(x, z):
		_change(z * grid.w + x, 1, clampf(v, 0.0, Config.MAX_DEPTH))


func terrain_changed(_cells: Array) -> void:
	var data := grid.height.to_byte_array()
	rd.texture_update(_height, 0, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and rd != null:
		depth_tex.texture_rd_rid = RID()
		surf_tex.texture_rd_rid = RID()
		for rid in _rids:
			if rid.is_valid():
				rd.free_rid(rid)
		rd.free_rid(_shader)  # frees the pipeline and uniform set that depend on it
