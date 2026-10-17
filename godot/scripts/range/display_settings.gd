class_name DisplaySettings
## Window mode chosen in the Esc menu: windowed, borderless (a borderless window covering the screen) or fullscreen
## (native exclusive fullscreen). Saved in user://settings.cfg next to MouseSettings; applied when a scene starts.

static var _applied := false  # saved mode is applied once per run; later scene loads keep the current window

const MODES := ["Windowed", "Borderless", "Fullscreen"]
const _DS := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


static func current() -> int:
	var cfg := ConfigFile.new()
	if MouseSettings._testing() or cfg.load(MouseSettings.PATH) != OK:
		return 0
	return clampi(int(cfg.get_value("display", "mode", 0)), 0, MODES.size() - 1)


## Applies the saved mode on the first scene of a run (no-op headless or in tests). Restarts and map
## changes keep whatever mode the window is in (OS fullscreen key included).
static func apply() -> void:
	if _applied or DisplayServer.get_name() == "headless" or MouseSettings._testing():
		return
	_applied = true
	_apply_mode(current())


static func choose(i: int) -> void:
	_apply_mode(i)
	if MouseSettings._testing():
		return
	var cfg := ConfigFile.new()
	cfg.load(MouseSettings.PATH)
	cfg.set_value("display", "mode", i)
	cfg.save(MouseSettings.PATH)


static func _apply_mode(i: int) -> void:
	if DisplayServer.window_get_mode() != _DS[i]:
		DisplayServer.window_set_mode(_DS[i])
