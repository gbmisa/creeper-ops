class_name HudSettings
## On/off switches for HUD pieces, set in the Esc menu (HUD section) and saved in user://settings.cfg next to
## MouseSettings. Everything defaults to on (the HUD as it was). Never read or saved while the range suite runs.

const PARTS := {"help": "Controls help", "hit_log": "Hit log", "bot_log": "Bot status lines", "stamina": "Stamina bars"}

static var _on := {}


static func on(part: String) -> bool:
	if _on.is_empty():
		_load()
	return bool(_on.get(part, true))


static func set_on(part: String, v: bool) -> void:
	if _on.is_empty():
		_load()
	_on[part] = v
	if MouseSettings._testing():
		return
	var cfg := ConfigFile.new()
	cfg.load(MouseSettings.PATH)
	cfg.set_value("hud", part, v)
	cfg.save(MouseSettings.PATH)


static func _load() -> void:
	var cfg := ConfigFile.new()
	var ok := not MouseSettings._testing() and cfg.load(MouseSettings.PATH) == OK
	for k in PARTS:
		_on[k] = bool(cfg.get_value("hud", k, true)) if ok else true
