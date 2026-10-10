class_name PauseMenu
extends RefCounted
## Pause menu for both modes, opened with Esc (GameFlow.on_key). Never during landing,
## the briefing, or game over. Resume restores the pause state it found.

var g  # Game
var open := false
var _was_paused := false
var _keys_prev_close := Callable()


func _init(game) -> void:
	g = game


func show() -> void:
	if g.over or g.landing or open:
		return
	open = true
	if g.mode == "command":
		_was_paused = g.paused
		g.paused = true
		Bus.metric.emit("pause", { "paused": true })
	else:
		g.fps_paused = true
	_main()


func _main() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var buttons: Array = [
		{ "label": "Resume", "on_click": resume },
		{ "label": "Restart mission", "on_click": _confirm_restart },
	]
	if g.mode != "command":
		var cd: float = g.deploy.preview_recall()
		var recall := "Recall to Node" if cd <= 0.0 else "Recall to Node (teleporter %ds)" % ceili(cd)
		buttons.append({ "label": recall, "on_click": _recall })
	buttons.append({ "label": "Level select", "on_click": _levels })
	buttons.append({ "label": "Controls", "on_click": _open_keys })
	buttons.append({ "label": "Mute sound: ON" if Sfx.muted else "Mute sound: OFF", "on_click": _toggle_mute })
	buttons.append({ "label": "Quit to desktop", "on_click": func(): g.get_tree().quit() })
	g.hud.show_overlay("[font_size=26][b]Paused[/b][/font_size]\n%s" % g.level.name, buttons)


func resume() -> void:
	if not open:
		return
	open = false
	g.hud.hide_overlay()
	if g.mode == "command":
		g.paused = _was_paused
		Bus.metric.emit("pause", { "paused": g.paused })
	else:
		g.fps_paused = false
		if not g.ignore_capture:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _recall() -> void:
	g.deploy.commit_recall()
	if g.mode == "command":
		open = false  # to_command already hid the overlay and unpaused


func _confirm_restart() -> void:
	g.hud.show_overlay("[font_size=26][b]Restart mission[/b][/font_size]\nStart [b]%s[/b] over from the beginning? All progress in this mission will be lost." % g.level.name, [
		{ "label": "Yes, restart it", "on_click": func(): g.get_tree().reload_current_scene() },
		{ "label": "Cancel", "on_click": _main },
	])


func _levels() -> void:
	var buttons: Array = g.flow.level_buttons()
	buttons.append({ "label": "Back", "on_click": _main })
	g.hud.show_overlay("[font_size=26][b]Level select[/b][/font_size]\nPick a mission (restarts the scene).", buttons)


func _open_keys() -> void:
	_keys_prev_close = g.hud.keys.on_close
	g.hud.keys.on_close = _keys_closed
	g.hud.keys.open()


func _keys_closed() -> void:
	g.hud.keys.on_close = _keys_prev_close
	if _keys_prev_close.is_valid():
		_keys_prev_close.call()
	_main()


func _toggle_mute() -> void:
	Bus.say("Sound muted." if Sfx.toggle_mute() else "Sound on.", "info")
	_main()
