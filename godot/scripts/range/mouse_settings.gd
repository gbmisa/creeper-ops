class_name MouseSettings
## Mouse sensitivity multiplier on TacticalPlayer.SENS (1.0 = the original feel). Saved to user://settings.cfg
## (not keybinds.cfg); tests run with Keybinds.persist = false and never save.

const PATH := "user://settings.cfg"
const MIN := 0.2
const MAX := 3.0

static var _mult := -1.0


static func mult() -> float:
	if _mult < 0.0:
		_mult = 1.0
		var cfg := ConfigFile.new()
		if Keybinds.persist and cfg.load(PATH) == OK:
			_mult = clampf(float(cfg.get_value("mouse", "sensitivity", 1.0)), MIN, MAX)
	return _mult


static func set_mult(v: float) -> void:
	_mult = clampf(v, MIN, MAX)
	if not Keybinds.persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("mouse", "sensitivity", _mult)
	cfg.save(PATH)
