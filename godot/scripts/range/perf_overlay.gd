class_name PerfOverlay
extends CanvasLayer
## Performance metrics (F3, action t_perf): fps, average + worst frame over the last second, engine process /
## physics time, render counters, node / physics / bot counts and PerfProbe per-system CPU time. While shown,
## it prints a "[perf]" line to the log every LOG_EVERY s and a "[perf] SPIKE" line for any frame over SPIKE_MS,
## so a playtest log (Esc > Report a bug) carries the numbers.

const LOG_EVERY := 5.0
const SPIKE_MS := 33.0
const WINDOW := 1.0   # s per on-screen sample

var input: InputState
var get_bots: Callable
var _lbl: Label
var _panel: PanelContainer
var _t := 0.0
var _log_t := 0.0
var _frames := 0
var _sum_ms := 0.0
var _worst_ms := 0.0
var _probe := {}   # accumulated PerfProbe totals for this window


func setup(inp: InputState, bots_fn: Callable) -> void:
	input = inp
	get_bots = bots_fn


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = UiKit.panel(Color(0.02, 0.03, 0.04, 0.8))
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -360.0
	_panel.offset_top = 120.0
	_panel.custom_minimum_size = Vector2(340, 0)
	_lbl = UiKit.label("", 12, Color(0.85, 1.0, 0.85))
	_panel.add_child(_lbl)
	add_child(_panel)
	_panel.visible = false


func show_now() -> void:
	_panel.visible = true


func _process(dt: float) -> void:
	if input != null and input.act("t_perf"):
		_panel.visible = not _panel.visible
		PerfProbe.take()
	var ms := dt * 1000.0
	_frames += 1
	_sum_ms += ms
	_worst_ms = maxf(_worst_ms, ms)
	var p := PerfProbe.take()
	for k in p:
		var a: Array = _probe.get(k, [0, 0])
		_probe[k] = [a[0] + p[k][0], a[1] + p[k][1]]
	if not _panel.visible:
		_reset()
		return
	if ms > SPIKE_MS:
		var top := p.keys()
		top.sort_custom(func(a, b): return p[a][0] > p[b][0])
		var parts := []
		for k in top.slice(0, 4):
			parts.append("%s %.1f" % [k, float(p[k][0]) / 1000.0])
		print("[perf] SPIKE %.1f ms  physics %.1f ms  draws %d  nodes %d  bots %d  top: %s" % [ms,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, _mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			_mon(Performance.OBJECT_NODE_COUNT), _bot_count(), ", ".join(parts)])
	_t += dt
	if _t < WINDOW:
		return
	var text := _text()
	_lbl.text = text
	_log_t += _t
	if _log_t >= LOG_EVERY:
		_log_t = 0.0
		print("[perf] ", text.replace("\n", " | "))
	_reset()


func _reset() -> void:
	_t = 0.0
	_frames = 0
	_sum_ms = 0.0
	_worst_ms = 0.0
	_probe.clear()


func _mon(m: Performance.Monitor) -> int:
	return int(Performance.get_monitor(m))


func _bot_count() -> int:
	if not get_bots.is_valid():
		return 0
	return (get_bots.call() as Array).filter(func(b): return is_instance_valid(b) and not b.body.dead).size()


func _text() -> String:
	var avg := _sum_ms / maxf(1.0, float(_frames))
	var lines := [
		"FPS %d   frame avg %.1f ms   worst %.1f ms" % [_frames / _t, avg, _worst_ms],
		"process %.1f ms   physics %.1f ms" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0],
		"draw calls %d   objects %d   primitives %dk" % [_mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			_mon(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), _mon(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000],
		"nodes %d   physics bodies %d   bots alive %d" % [_mon(Performance.OBJECT_NODE_COUNT),
			_mon(Performance.PHYSICS_3D_ACTIVE_OBJECTS), _bot_count()],
		"video mem %d MB   static mem %d MB" % [_mon(Performance.RENDER_VIDEO_MEM_USED) / 1048576,
			_mon(Performance.MEMORY_STATIC) / 1048576],
		"CPU per frame (ms):"]
	var keys := _probe.keys()
	keys.sort_custom(func(a, b): return _probe[a][0] > _probe[b][0])
	for k in keys:
		lines.append("  %-16s %.2f  (%d calls)" % [k, float(_probe[k][0]) / 1000.0 / maxf(1.0, float(_frames)),
			int(_probe[k][1] / maxi(1, _frames))])
	return "\n".join(lines)
