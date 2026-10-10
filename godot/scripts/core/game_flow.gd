class_name GameFlow
extends RefCounted
## Mode flow: briefing -> Command Node landing -> command <-> Operative (surface / cave),
## global hotkeys, alerts and the end screen. Deployment lives in OperativeDeploy.

var g  # Game
var node_alert_cd := 0.0
var pause: PauseMenu
var pause_open: bool:
	get: return pause.open
var base_alerts := BaseAlerts.new()


func _init(game) -> void:
	g = game
	pause = PauseMenu.new(game)
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
	base_alerts.connect_bus(g)
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
	base_alerts.update(dt)


## Global keys (fired from InputState._input, before the frame update).
func on_key(k: int) -> void:
	if ArmouryMenu.is_open():
		if k == KEY_ESCAPE or Keybinds.matches("use", k):
			if Keybinds.matches("use", k):
				ArmouryMenu.suppress_use = true
			ArmouryMenu.close_menu()
		return
	if pause.open:
		if k == KEY_ESCAPE and not g.hud.keys.visible:  # the Controls panel handles its own keys
			pause.resume()
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
			if g.fps.builder != null and g.fps.builder.wheel_open():
				return  # the build wheel closes itself this frame; don't pause
			pause.show()
		return
	if Keybinds.matches("keybinds", k):
		g.hud.keys.open()
	elif k == KEY_ESCAPE and not _command_busy():
		pause.show()
	elif Keybinds.matches("pause", k) and not g.landing:
		g.paused = not g.paused
		Bus.metric.emit("pause", { "paused": g.paused })
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


## Esc first cancels a tool or selection (CommandInput); only a bare Esc opens the menu.
func _command_busy() -> bool:
	var cm: CommandMode = g.command
	return cm.tool != "" or cm.selected != null or not cm.units.selected.is_empty()


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
	CastleReadability.set_command_view(cmd)  # P4: fade the castle roof slabs
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
	g.hud.show_overlay("""[color=#e3b21c][font_size=14]MISSION BRIEFING  //  OPERATION ORDER[/font_size][/color]
[font_size=30][b]%s[/b][/font_size]

Hold the line Creeper World 3 style, and drop an [b]Operative[/b] to finish what turrets can't.

• [b]Land first.[/b] Pick where your Command Node touches down: dry, high ground far from emitters.
• [b]Energy is packets.[/b] The Node fires a packet whenever a structure asks and the bank has energy. Watch the green (production) and red (demand) numbers.
• [b]Five build screens[/b] (F1-F5): Structures, Weapons, Titans, Orbital, Castle. Weapons and titans can fly to new spots: select, then right-click.
• [b]Creeper destroys anything it touches,[/b] built or not. Only the Node has armour. Purple [b]Blight[/b] can't be built on.
• [b]Spore Nests grow.[/b] They raid your base and breed tougher raiders the longer the mission runs. [b]Castles[/b] feed the Forge: the Operative climbs the spire, kills the crown nest and holds the top; raiders come to take them back. Barracks units can enter it, but they run dry and must walk home to restock.
• Only the [b]Operative[/b] can plant charges or enter the Rift.""" % g.level.name,
		[{ "label": "Begin: choose landing site", "on_click": begin }, { "label": "Controls", "on_click": g.hud.keys.open }]
		+ level_buttons())


## One button per level: picks it and restarts the scene.
func level_buttons() -> Array:
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
	var msg := "[color=#8ee05a][font_size=14]MISSION COMPLETE[/font_size][/color]\n[font_size=30][b]%s secured[/b][/font_size]\nAll threats neutralised in %s." % [g.level.name, t] if won \
		else "[color=#ff5a3c][font_size=14]MISSION FAILED[/font_size][/color]\n[font_size=30][b]Command Node lost[/b][/font_size]\nThe creeper overran the Node after %s." % t
	msg += g.metrics.end_text()
	g.hud.show_overlay(msg, [{ "label": "Play again", "on_click": func(): g.get_tree().reload_current_scene() }])
