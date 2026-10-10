class_name SmokePauseMenu
## Pause menu checks (--smoke=pausemenu): Esc opens the menu in both modes
## (the pause keybind stays a quick pause), freezes the sim, and offers Resume /
## Restart (two-step) / Recall (operative) / Level select / Controls / Mute / Quit.
## Called from SmokeTest._run_only.


static func run(g) -> void:
	Keybinds.persist = false
	var flow: GameFlow = g.flow
	var pk := KEY_ESCAPE
	g.command.set_tool("")
	g.command.select_structure(null)
	g.units.select([])
	var space: int = int(Keybinds.keys("pause")[0])
	var before: bool = g.paused
	flow.on_key(space)
	SmokeTest._check("pause key toggles a quick pause, no menu", g.paused != before and not flow.pause_open)
	flow.on_key(space)

	# Command mode: pause key opens the menu and freezes the sim.
	flow.on_key(pk)
	SmokeTest._check("pause key opens the menu", flow.pause_open and g.paused and g.hud.overlay_open())
	SmokeTest._check("sim frozen while menu open", not _would_update(g),
		"(paused=%s fps_paused=%s)" % [str(g.paused), str(g.fps_paused)])
	SmokeTest._check("menu titled Paused", _overlay_text(g).contains("Paused"))
	SmokeTest._check("no recall in command mode", not _has_button(g, "Recall to Node"))
	SmokeTest._check("quit offered", _has_button(g, "Quit to desktop"))

	# Resume closes and unfreezes.
	_click_button(g, "Resume")
	SmokeTest._check("resume closes menu", not flow.pause_open and not g.paused and not g.hud.overlay_open())
	SmokeTest._check("sim resumes", _would_update(g))

	# Pause key toggles back off while the menu is open.
	flow.on_key(pk)
	flow.on_key(pk)
	SmokeTest._check("pause key resumes from menu", not flow.pause_open and not g.paused)

	# Restart is a two-step confirm; cancel returns to the menu.
	flow.on_key(pk)
	_click_button(g, "Restart mission")
	SmokeTest._check("restart asks first", _has_button(g, "Yes, restart it") and _has_button(g, "Cancel"))
	SmokeTest._check("confirm warns about loss", _overlay_text(g).contains("will be lost"))
	_click_button(g, "Cancel")
	SmokeTest._check("cancel returns to pause menu", flow.pause_open and _has_button(g, "Resume"))
	_click_button(g, "Resume")

	# Level select sub-list returns to the pause menu.
	flow.on_key(pk)
	_click_button(g, "Level select")
	SmokeTest._check("level select lists levels", _has_button(g, "Level 1:"))
	_click_button(g, "Back")
	SmokeTest._check("level back returns to menu", flow.pause_open and _has_button(g, "Resume"))
	_click_button(g, "Resume")

	# Controls sub-panel returns to the pause menu.
	flow.on_key(pk)
	_click_button(g, "Controls")
	SmokeTest._check("controls open", g.hud.keys.visible)
	g.hud.keys.close()
	SmokeTest._check("controls close returns to menu", flow.pause_open and _has_button(g, "Resume"))

	# Mute toggle shows live state and refreshes its label.
	var was_muted: bool = Sfx.muted
	_click_button(g, "Mute sound: ON" if was_muted else "Mute sound: OFF")
	SmokeTest._check("mute toggles", Sfx.muted != was_muted)
	SmokeTest._check("mute label refreshes", _has_button(g, "Mute sound: ON" if not was_muted else "Mute sound: OFF"))
	if Sfx.muted != was_muted:
		Sfx.toggle_mute()  # restore
	_click_button(g, "Resume")

	# The menu never opens during landing/briefing or on game over.
	g.landing = true
	flow.on_key(pk)
	SmokeTest._check("no menu during landing", not flow.pause_open)
	g.landing = false
	g.over = true
	flow.on_key(pk)
	SmokeTest._check("no menu on game over", not flow.pause_open)
	g.over = false

	# Operative mode: Esc opens the same menu, with Recall offered.
	g.flow.set_mode("surface")
	flow.on_key(KEY_ESCAPE)
	SmokeTest._check("operative esc opens menu", flow.pause_open and g.fps_paused and g.hud.overlay_open())
	SmokeTest._check("sim frozen in operative pause", not _would_update(g))
	SmokeTest._check("recall offered in operative mode", _has_button(g, "Recall to Node"))
	flow.on_key(KEY_ESCAPE)
	SmokeTest._check("esc resumes operative", not flow.pause_open and not g.fps_paused)
	g.flow.set_mode("command")
	Keybinds.persist = true


## Mirrors Game._process's freeze gate: would the sim advance this frame?
static func _would_update(g) -> bool:
	var menu: bool = g.hud.keys.visible
	var frozen: bool = menu or (g.mode != "command" and g.fps_paused)
	return not g.paused and not g.over and not frozen and not g.landing


static func _live_buttons(g) -> Array:
	var out: Array = []
	for c in g.hud._overlay._box.get_children():
		if c is HFlowContainer and not c.is_queued_for_deletion():
			for b in c.get_children():
				if b is Button and not b.is_queued_for_deletion():
					out.append(b)
	return out


static func _has_button(g, text: String) -> bool:
	for b in _live_buttons(g):
		if (b as Button).text.begins_with(text):
			return true
	return false


static func _click_button(g, text: String) -> bool:
	for b in _live_buttons(g):
		if (b as Button).text.begins_with(text):
			(b as Button).pressed.emit()
			return true
	SmokeTest._check("button '%s' exists" % text, false)
	return false


static func _overlay_text(g) -> String:
	for c in g.hud._overlay._box.get_children():
		if c is RichTextLabel and not c.is_queued_for_deletion():
			return (c as RichTextLabel).text
	return ""
