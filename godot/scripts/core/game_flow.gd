class_name GameFlow
extends RefCounted
## Mode flow: briefing -> Command Node landing -> command <-> Operative (surface / cave),
## global hotkeys, alerts and the end screen. Deployment lives in OperativeDeploy.

var g  # Game
var node_alert_cd := 0.0


func _init(game) -> void:
	g = game
	Bus.enter_cave.connect(func():
		g.fps.enter(g.cave, g.cave_data.pad, -PI / 2.0, g.cave_hazards.mites)
		set_mode("cave")
		Bus.say("Ops: You're in. Three Shield Pylons protect the Core: shoot the glowing crystals. Watch the flood.", "radio"))
	Bus.exit_cave.connect(func():
		g.fps.enter(g.surface, Vector2i(g.level.rift.x + 2, g.level.rift.z), -PI / 2.0)
		set_mode("surface"))
	Bus.core_destroyed.connect(func():
		g.hazards.on_core_destroyed()
		g.hud.alert("DEEP CORE DESTROYED", "good"))
	Bus.node_hit.connect(func():
		if node_alert_cd <= 0.0:
			node_alert_cd = 8.0
			Sfx.play("alarm")
			g.hud.alert("COMMAND NODE UNDER ATTACK", "bad", 2.5))
	Bus.node_destroyed.connect(func(): end_game(false))
	Bus.victory.connect(func(): end_game(true))
	g.command.on_land = land
	Upgrades.reset()
	OperativeUpgrades.reset()
	Bus.objective_done.connect(func(id):
		if Upgrades.REWARDS.has(id):
			Upgrades.gain(Upgrades.REWARDS[id], "objective"))
	Bus.nest_destroyed.connect(func(_n): Upgrades.gain(Upgrades.REWARDS.nest, "Spore Nest"))


func update(dt: float) -> void:
	node_alert_cd -= dt


## Global keys (fired from InputState._input, before the frame update).
func on_key(k: int) -> void:
	if ArmouryMenu.is_open():
		if k == KEY_ESCAPE or Keybinds.matches("use", k):
			if Keybinds.matches("use", k):
				ArmouryMenu.suppress_use = true
			ArmouryMenu.close_menu()
		return
	if pause_open:
		if g.hud.keys.visible:
			return  # the Controls panel handles its own keys
		if Keybinds.matches("pause", k) or k == KEY_ESCAPE:
			resume_from_pause()
		return
	if g.over or g.hud.keys.visible or g.hud.overlay_open():
		return
	if Keybinds.matches("mute", k):
		Bus.say("Sound muted." if Sfx.toggle_mute() else "Sound on.", "info")
	if g.mode != "command":
		if Keybinds.matches("test_recall", k) and not g.deploy.down:
			g.teleport_cooldown = 0.0
			to_command("Test recall: back aboard, teleporter ready.")
		elif k == KEY_ESCAPE:
			open_pause_menu()
		return
	if Keybinds.matches("keybinds", k):
		g.hud.keys.open()
	elif Keybinds.matches("pause", k) and not g.landing:
		open_pause_menu()
	elif Keybinds.matches("speed_up", k):
		g.cycle_speed(1)
		Bus.metric.emit("speed", { "speed": g.speed })
	elif Keybinds.matches("speed_down", k):
		g.cycle_speed(-1)
		Bus.metric.emit("speed", { "speed": g.speed })
	elif Keybinds.matches("teleport", k):
		g.deploy.deploy_totem()
	elif not g.landing:
		g.hud.build.handle_key(k)


## Build menu pick: structure types become tools, "@" items are actions.
func pick(item: String) -> void:
	if g.landing:
		Bus.say("Land the Command Node first.", "warn")
	elif item == "@operative":
		g.deploy.deploy_totem()
	else:
		g.command.set_tool("" if g.command.tool == item else item)


func land(cell: Vector2i) -> void:
	g.structures.place("node", cell.x, cell.y, true)
	g.landing = false
	g.paused = false
	g.command.tool = ""
	g.command.set_tool("")
	g.command.cam.focus(g.structures.command_node().pos)
	Sfx.play("teleport")
	g.hud.alert("COMMAND NODE LANDED", "good", 2.0)
	var lines: Array = g.level.intro
	for i in range(1, lines.size()):
		g.get_tree().create_timer(i * 3.0).timeout.connect(func(): Bus.say(lines[i][0], lines[i][1]))


## Unified pause menu (both modes). The pause keybind opens it in command mode,
## Esc in Operative mode. Never during landing, the briefing, or game over.
var pause_open := false
var _keys_prev_close := Callable()


func open_pause_menu() -> void:
	if g.over or g.landing or pause_open:
		return
	pause_open = true
	if g.mode == "command":
		g.paused = true
		Bus.metric.emit("pause", { "paused": true })
	else:
		g.fps_paused = true
	_show_pause_main()


func _show_pause_main() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var buttons: Array = [
		{ "label": "Resume", "on_click": resume_from_pause },
		{ "label": "Restart mission", "on_click": _confirm_restart },
	]
	if g.mode != "command":
		var cd: float = g.deploy.preview_recall()
		var recall := "Recall to Node" if cd <= 0.0 else "Recall to Node (teleporter %ds)" % ceili(cd)
		buttons.append({ "label": recall, "on_click": _recall_from_pause })
	buttons.append({ "label": "Level select", "on_click": _show_level_select })
	buttons.append({ "label": "Controls", "on_click": _open_keys_from_pause })
	buttons.append({ "label": "Mute sound: ON" if Sfx.muted else "Mute sound: OFF", "on_click": _toggle_mute_from_pause })
	buttons.append({ "label": "Quit to desktop", "on_click": func(): g.get_tree().quit() })
	g.hud.show_overlay("[font_size=26][b]Paused[/b][/font_size]\n%s" % g.level.name, buttons)


func resume_from_pause() -> void:
	if not pause_open:
		return
	pause_open = false
	g.hud.hide_overlay()
	if g.mode == "command":
		g.paused = false
		Bus.metric.emit("pause", { "paused": false })
	else:
		g.fps_paused = false
		if not g.ignore_capture:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _recall_from_pause() -> void:
	g.deploy.commit_recall()
	if g.mode == "command":
		pause_open = false  # to_command already hid the overlay and unpaused


func _confirm_restart() -> void:
	g.hud.show_overlay("[font_size=26][b]Restart mission[/b][/font_size]\nStart [b]%s[/b] over from the beginning? All progress in this mission will be lost." % g.level.name, [
		{ "label": "Yes, restart it", "on_click": func(): g.get_tree().reload_current_scene() },
		{ "label": "Cancel", "on_click": _show_pause_main },
	])


func _show_level_select() -> void:
	var buttons := _level_buttons()
	buttons.append({ "label": "Back", "on_click": _show_pause_main })
	g.hud.show_overlay("[font_size=26][b]Level select[/b][/font_size]\nPick a mission (restarts the scene).", buttons)


func _open_keys_from_pause() -> void:
	_keys_prev_close = g.hud.keys.on_close
	g.hud.keys.on_close = _on_keys_closed_from_pause
	g.hud.keys.open()


func _on_keys_closed_from_pause() -> void:
	g.hud.keys.on_close = _keys_prev_close
	if _keys_prev_close.is_valid():
		_keys_prev_close.call()
	_show_pause_main()


func _toggle_mute_from_pause() -> void:
	Bus.say("Sound muted." if Sfx.toggle_mute() else "Sound on.", "info")
	_show_pause_main()


func to_command(message: String, kind := "info") -> void:
	g.fps.leave()
	g.fps_paused = false
	g.hud.hide_overlay()
	set_mode("command")
	if message != "":
		Bus.say(message, kind)


func set_mode(m: String) -> void:
	g.mode = m
	Bus.metric.emit("mode", { "mode": m })
	g.hud.set_mode(m)
	var cmd := m == "command"
	g.surface.set_active(m != "cave")
	g.cave.set_active(m == "cave")
	g.command.overlay.set_overlay_visible(cmd)
	WorldLook.set_command_view(g.surface.env, cmd)
	if cmd:
		g.command.cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		g.fps.camera.current = true
		g.units.select([])
		g.command.select_structure(null)
		if not g.ignore_capture:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func show_briefing() -> void:
	g.hud.show_overlay("""[font_size=26][b]%s[/b][/font_size]

Hold the line Creeper World 3 style, and drop an [b]Operative[/b] to finish what turrets can't.

• [b]Land first.[/b] Pick where your Command Node touches down: dry, high ground far from emitters.
• [b]Energy is packets.[/b] The Node fires a packet whenever a structure asks and the bank has energy. Watch the green (production) and red (demand) numbers.
• [b]Four build screens[/b] (F1-F4): Structures, Weapons, Titans, Orbital. Weapons and titans can fly to new spots: select, then right-click.
• [b]Creeper destroys anything it touches,[/b] built or not. Only the Node has armour. Purple [b]Blight[/b] can't be built on.
• [b]Spore Nests grow.[/b] They raid your base and breed tougher raiders the longer the mission runs. [b]Castles[/b] feed the Forge: the Operative climbs the spire, kills the crown nest and holds the top; raiders come to take them back. Barracks units can enter it, but they run dry and must walk home to restock.
• Only the [b]Operative[/b] can plant charges or enter the Rift.""" % g.level.name,
		[{ "label": "Begin: choose landing site", "on_click": begin }, { "label": "Controls", "on_click": g.hud.keys.open }]
		+ _level_buttons())


## One button per level: picks it and restarts the scene.
func _level_buttons() -> Array:
	var out := []
	for i in Levels.NAMES.size():
		out.append({ "label": "Level %d: %s" % [i + 1, Levels.NAMES[i]], "on_click": func():
			Levels.selected = i + 1
			g.get_tree().reload_current_scene() })
	return out


func begin() -> void:
	g.hud.hide_overlay()
	g.command.set_tool("@land")
	Bus.say(g.level.intro[0][0], g.level.intro[0][1])


func end_game(won: bool) -> void:
	if g.over:
		return
	g.over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("good" if won else "lost")
	g.metrics.finish("victory" if won else "node_destroyed")
	var t := "%dm %ds" % [floori(g.time / 60.0), floori(fmod(g.time, 60.0))]
	var msg := "[font_size=26][b]%s secured[/b][/font_size]\nAll threats neutralised in %s." % [g.level.name, t] if won \
		else "[font_size=26][b]Command Node lost[/b][/font_size]\nThe creeper overran the Node after %s." % t
	msg += g.metrics.end_text()
	g.hud.show_overlay(msg, [{ "label": "Play again", "on_click": func(): g.get_tree().reload_current_scene() }])
