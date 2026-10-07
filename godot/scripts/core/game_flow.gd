class_name GameFlow
extends RefCounted
## Mode flow: briefing -> Command Node landing -> command <-> Operative (surface / cave),
## teleports, recalls, global hotkeys, alerts and the end screen. Split from game.gd so that
## file stays wiring only.

var g  # Game
var node_alert_cd := 0.0


func _init(game) -> void:
	g = game
	Bus.recall.connect(func(cost):
		if cost > 0.0:
			g.economy.drain(cost)
		to_command("Emergency recall (-%d energy)." % cost if cost > 0.0 else "Operative back aboard."))
	Bus.operative_down.connect(func():
		g.economy.drain(Config.KO_PENALTY)
		g.teleport_cooldown = Config.TELEPORT_COOLDOWN
		g.hud.alert("SUIT FAILURE: OPERATIVE RECALLED")
		to_command("Suit failure! Auto-recalled (-%d energy, teleporter offline %ds)." % [Config.KO_PENALTY, Config.TELEPORT_COOLDOWN], "bad"))
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
	Bus.objective_done.connect(func(id):
		if Upgrades.REWARDS.has(id):
			Upgrades.gain(Upgrades.REWARDS[id], "objective"))
	Bus.nest_destroyed.connect(func(_n): Upgrades.gain(Upgrades.REWARDS.nest, "Spore Nest"))


func update(dt: float) -> void:
	node_alert_cd -= dt


## Global keys (fired from InputState._input, before the frame update).
func on_key(k: int) -> void:
	if g.over or g.hud.keys.visible or g.hud.overlay_open() and not g.fps_paused:
		return
	if Keybinds.matches("mute", k):
		Bus.say("Sound muted." if Sfx.toggle_mute() else "Sound on.", "info")
	if g.mode != "command":
		if k == KEY_ESCAPE:
			pause_operative()
		return
	if Keybinds.matches("keybinds", k):
		g.hud.keys.open()
	elif Keybinds.matches("pause", k) and not g.landing:
		g.paused = not g.paused
	elif Keybinds.matches("speed_up", k):
		g.cycle_speed(1)
	elif Keybinds.matches("speed_down", k):
		g.cycle_speed(-1)
	elif Keybinds.matches("teleport", k):
		try_teleport()
	elif not g.landing:
		g.hud.build.handle_key(k)


## Build menu pick: structure types become tools, "@" items are actions.
func pick(item: String) -> void:
	if g.landing:
		Bus.say("Land the Command Node first.", "warn")
	elif item == "@operative":
		try_teleport()
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


func try_teleport() -> void:
	if g.landing or g.paused or g.over:
		return
	if g.teleport_cooldown > 0.0:
		Bus.say("Teleporter recharging: %ds" % ceili(g.teleport_cooldown), "warn")
		Sfx.play("deny")
		return
	var beacons: Array[Structure] = g.structures.beacons()
	var sb: Structure = g.structures.selected_beacon
	var b: Structure = sb if beacons.has(sb) else (beacons.back() if not beacons.is_empty() else null)
	if b == null:
		Bus.say("No finished Beacon. Drop one (Orbital tab, F4) outside Blight, then press T.", "warn")
		Sfx.play("deny")
		return
	g.fps.reset_suit()
	g.fps.enter(g.surface, Vector2i(b.x, b.z - 1), 0.0)
	g.command.set_tool("")
	set_mode("surface")
	Bus.say("Operative deployed. The creeper won't wait for you.", "radio")


func pause_operative() -> void:
	g.fps_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	g.hud.show_overlay("[b]Operative paused[/b]\nThe battle is frozen.", [
		{ "label": "Resume", "on_click": resume_operative },
		{ "label": "Recall to Node (-%d)" % Config.RECALL_COST, "on_click": func(): Bus.recall.emit(Config.RECALL_COST) },
		{ "label": "Controls", "on_click": g.hud.keys.open },
	])


func resume_operative() -> void:
	g.fps_paused = false
	g.hud.hide_overlay()
	if not g.ignore_capture:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func to_command(message: String, kind := "info") -> void:
	g.fps.leave()
	g.fps_paused = false
	g.hud.hide_overlay()
	set_mode("command")
	if message != "":
		Bus.say(message, kind)


func set_mode(m: String) -> void:
	g.mode = m
	g.hud.set_mode(m)
	var cmd := m == "command"
	g.surface.set_active(m != "cave")
	g.cave.set_active(m == "cave")
	g.command.overlay.set_overlay_visible(cmd)
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
• [b]Spore Nests grow.[/b] They raid your base and breed tougher raiders the longer the mission runs. [b]Aether Towers[/b] feed the Forge: the Operative captures them, creeper takes them back. Barracks units can enter it, but they run dry and must walk home to restock.
• Only the [b]Operative[/b] can plant charges or enter the Rift.""" % g.level.name,
		[{ "label": "Begin: choose landing site", "on_click": begin }, { "label": "Controls", "on_click": g.hud.keys.open }])


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
	var t := "%dm %ds" % [floori(g.time / 60.0), floori(fmod(g.time, 60.0))]
	var msg := "[font_size=26][b]%s secured[/b][/font_size]\nAll threats neutralised in %s." % [g.level.name, t] if won \
		else "[font_size=26][b]Command Node lost[/b][/font_size]\nThe creeper overran the Node after %s." % t
	g.hud.show_overlay(msg, [{ "label": "Play again", "on_click": func(): g.get_tree().reload_current_scene() }])
