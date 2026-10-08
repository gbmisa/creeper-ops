class_name SmokeHud
## HUD declutter: the log stays at HUD_LOG_LINES and a line is gone after its life,
## and the objectives toggle does not share a default key. Called from SmokeTest.run.


static func run(g) -> void:
	Keybinds.persist = false
	var hud: Hud = g.hud
	for i in 8:
		hud.add_log("smoke-hud-%d" % i, "info")
	SmokeTest._check("log caps at 5", hud.log_count() == Config.HUD_LOG_LINES
		and hud.log_has("smoke-hud-7") and not hud.log_has("smoke-hud-0"), "(%d lines)" % hud.log_count())
	hud.add_log("smoke-hud-warn", "warn")
	hud.add_log("smoke-hud-fade", "info")
	_age(hud, Config.HUD_LOG_LIFE + 0.05)
	SmokeTest._check("log line gone after its life", not hud.log_has("smoke-hud-fade"))
	SmokeTest._check("warn lasts twice as long", hud.log_has("smoke-hud-warn"))
	_age(hud, Config.HUD_LOG_LIFE)
	SmokeTest._check("warn gone after double life", not hud.log_has("smoke-hud-warn"))
	var n := hud.log_count()
	hud.add_log("smoke-hud-repeat", "info")
	hud.add_log("smoke-hud-repeat", "info")
	SmokeTest._check("log repeats collapse", hud.log_count() == n + 1
		and hud.log_line("smoke-hud-repeat") == "smoke-hud-repeat  x2")
	SmokeTest._check("objectives toggle is free", _toggle_free())
	Keybinds.persist = true


static func _age(hud: Hud, seconds: float) -> void:
	hud._tick_log(seconds)


static func _toggle_free() -> bool:
	if not Keybinds.DEFAULTS.has("objectives_toggle"):
		return false
	var mine: Array = Keybinds.DEFAULTS["objectives_toggle"][2]
	if mine.is_empty() or int(mine[0]) != KEY_J:
		return false
	for id in Keybinds.DEFAULTS:
		if id == "objectives_toggle":
			continue
		for k in Keybinds.DEFAULTS[id][2]:
			if mine.has(k):
				return false
	return true
