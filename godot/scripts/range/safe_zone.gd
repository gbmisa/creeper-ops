class_name SafeZone
extends Control
## HUD safe zone: a full-screen frame shrunk to `width` x `height` percent of the window, centred. HUD pieces pinned
## inside it (RangeHud._pin) snap to its edges, so on an ultra-wide the HUD can sit in the middle instead of the far
## edges. Percentages are typed in the Esc menu and saved in user://settings.cfg (100 = whole screen, the default).

const MIN := 40.0
const MAX := 100.0

static var _pct := Vector2(-1, -1)


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	var view := get_viewport_rect().size
	var inset := (view * (Vector2.ONE - pct() / 100.0) * 0.5).round()
	if not is_equal_approx(offset_left, inset.x) or not is_equal_approx(offset_top, inset.y):
		offset_left = inset.x
		offset_right = -inset.x
		offset_top = inset.y
		offset_bottom = -inset.y


## (width %, height %).
static func pct() -> Vector2:
	if _pct.x < 0.0:
		_pct = Vector2(MAX, MAX)
		var cfg := ConfigFile.new()
		if not MouseSettings._testing() and cfg.load(MouseSettings.PATH) == OK:
			_pct = Vector2(clampf(float(cfg.get_value("hud", "width", MAX)), MIN, MAX),
				clampf(float(cfg.get_value("hud", "height", MAX)), MIN, MAX))
	return _pct


static func set_pct(axis: int, v: float) -> void:
	pct()
	_pct[axis] = clampf(v, MIN, MAX)
	if MouseSettings._testing():
		return
	var cfg := ConfigFile.new()
	cfg.load(MouseSettings.PATH)
	cfg.set_value("hud", "width" if axis == 0 else "height", _pct[axis])
	cfg.save(MouseSettings.PATH)
