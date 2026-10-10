class_name BaseAlerts
extends RefCounted
## Base-under-attack feedback in every mode: centre alert + alarm (rate limited), running
## "structures lost" count, and the FPS HUD's edge pulse and recent-losses chip.

var g  # Game
var _cd := 0.0
var _losses: Array[float] = []  # mission-clock seconds of recent losses
var _clock := 0.0


func connect_bus(game) -> void:
	g = game
	Bus.base_attacked.connect(func(_t): _alert("BASE UNDER ATTACK"))
	Bus.base_lost.connect(func(_t):
		_losses.append(_clock)
		_alert("BASE: %d structure%s lost" % [_losses.size(), "" if _losses.size() == 1 else "s"], true))


func recent() -> int:
	return _losses.size()


func update(dt: float) -> void:
	_clock += dt
	_cd -= dt
	while not _losses.is_empty() and _clock - _losses[0] > Config.BASE_LOST_WINDOW:
		_losses.pop_front()
	if g != null and g.hud != null:
		g.hud.fps.set_losses(_losses.size())


func _alert(text: String, force := false) -> void:
	if _cd > 0.0 and not force:
		return
	if _cd > 0.0 and force and _cd > Config.BASE_ALERT_COOLDOWN - 0.5:
		return  # don't stack on an alert that just fired this instant
	_cd = Config.BASE_ALERT_COOLDOWN
	Sfx.play("alarm")
	g.hud.alert(text, "bad", 2.5)
	g.hud.fps.pulse()
