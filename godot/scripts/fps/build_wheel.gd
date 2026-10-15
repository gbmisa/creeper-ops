class_name BuildWheel
extends RefCounted
## Two-level radial build selection for first person. Hold B (op_build) longer than
## HOLD_SECS to open the category wheel; click a category to open its item wheel;
## click an item to arm it and enter build mode. A quick tap of B keeps the old
## toggle behavior (handled on release). Pure logic, no drawing, so smoke tests can
## drive it headless; rendering lives in ui/BuildWheelView, which mirrors
## center/radius back here so hit-testing matches what is drawn.

const HOLD_SECS := 0.2
const RADIUS := 190.0    # outer edge of the pie segments
const INNER := 56.0      # dead zone in the middle (clicks here do nothing)
const CLICK_PAD := 46.0  # extra click margin past the pie for the labels

var center := Vector2(640, 360)
var radius := RADIUS
var open := false        # category wheel up
var items_open := false  # item wheel up (second level; open stays true)
var tab := 0             # category index shown in the item wheel
var hover := -1          # segment index under the cursor, -1 = none
var host = null          # Game, for ignore_capture
var _arming := false     # B pressed, tap-vs-hold not yet decided
var _hold_t := 0.0


func is_open() -> bool:
	return open


## 0..1 progress while B is being held toward the open threshold, -1 otherwise.
func hold_frac() -> float:
	return _hold_t / HOLD_SECS if _arming else -1.0


## Category names in the same order/labels as the command-mode build menu.
func categories() -> Array:
	return StructureDefs.TABS


## Buildable structures of the current item-wheel tab ("@" actions are command-only).
func item_list() -> Array:
	var out: Array = []
	for t in StructureDefs.MENU[StructureDefs.TABS[tab]]:
		if not String(t).begins_with("@"):
			out.append(t)
	return out


func item_label(id: String) -> String:
	return String(StructureDefs.DEFS[id].label)


func item_cost(id: String) -> String:
	return "%d" % int(StructureDefs.DEFS[id].get("cost", 0))


func segment_count() -> int:
	return categories().size() if not items_open else item_list().size()


## Which pie segment (0-based, clockwise from the top) is under the mouse, or -1.
func segment_at(mouse: Vector2) -> int:
	var d := mouse - center
	var r := d.length()
	if r < INNER or r > radius + CLICK_PAD:
		return -1
	var n := segment_count()
	if n <= 0:
		return -1
	var deg := rad_to_deg(atan2(d.y, d.x)) + 90.0  # 0 deg = straight up
	deg = fposmod(deg, 360.0)
	return int(deg / 360.0 * n) % n


## Per-frame driver. Returns true while the wheel owns the frame (game input
## suspended: the caller skips weapons and FPS look). The sim keeps running.
func update(input: InputState, build, dt: float) -> bool:
	if open:
		_track(input.mouse)
		if input.act("op_build"):
			close()
			Sfx.play("click")
			return false
		if input.right_clicked or input.was_pressed(KEY_ESCAPE):
			close()
			Sfx.play("click")
			return false
		if input.left_released:
			_click(build)
		return true
	if input.act("op_build"):
		_arming = true
		_hold_t = 0.0
		return false
	if _arming:
		if input.held("op_build"):
			_hold_t += dt
			if _hold_t >= HOLD_SECS:
				_arming = false
				_open(build)
		else:
			# Released before the hold time: the old tap-toggle behavior.
			_arming = false
			build.toggle(not build.active)
			Sfx.play("click")
	return open


func _open(build) -> void:
	open = true
	items_open = false
	tab = build.tab
	hover = -1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("click")


func close() -> void:
	open = false
	items_open = false
	hover = -1
	_arming = false
	var ic := false
	if host != null and "ignore_capture" in host:
		ic = bool(host.ignore_capture)
	if not ic:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _track(mouse: Vector2) -> void:
	hover = segment_at(mouse)


func _click(build) -> void:
	var seg := hover
	if seg < 0:
		return
	if not items_open:
		tab = seg
		items_open = true
		hover = -1
		Sfx.play("click")
		return
	var list := item_list()
	if seg < list.size():
		build.tab = tab
		build.tool = String(list[seg])
		build.toggle(true)
		close()
		Sfx.play("good")
