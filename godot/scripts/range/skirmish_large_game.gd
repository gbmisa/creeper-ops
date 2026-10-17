class_name SkirmishLargeGame
extends Node3D
## Skirmish rules: spawns the roster, objective HUD, extract timer (stand in the zone EXTRACT_TIME), loot crates, EXTRACTED / KIA.
## `tick_extract` and `loot` are plain functions so the range test can drive them.

const REACH := 2.2

var layout: SkirmishLargeLayout
var bots: Array[ScavBot] = []
var cheats: RangeCheats  # set by the scene; null in tests
var player: TacticalPlayer
var weapons: PlayerWeapons
var bal: Ballistics
var log: RangeHitLog
var session: RangeSession
var time_s := 0.0
var kills := 0
var boss_dead := false
var extracts: Array = []   # {pos, cond, name, progress, call_progress}
var over := false
var won := false
var end_screen: SkirmishEnd
var _label: Label


func build_world() -> void:
	RangeLayout._environment(self)
	layout = SkirmishLargeLayout.new()
	add_child(layout)
	layout.build()


func start(p: TacticalPlayer, w: PlayerWeapons, b: Ballistics, l: RangeHitLog, hud_parent: Node, s: RangeSession) -> void:
	player = p
	weapons = w
	bal = b
	log = l
	session = s
	session.noise.reset()
	process_priority = 50  # F88: after PlayerWeapons, which clears weapons.prompt every frame (the loot prompt never showed)
	layout.bake()
	for e in SkirmishLargeData.EXTRACTS:
		extracts.append({"pos": e["pos"], "cond": e["cond"], "name": e["name"], "progress": 0.0, "call_progress": 0.0})
	_label = UiKit.label("", 20, Color(0.8, 1.0, 0.8))
	_label.position = Vector2(520, 14)
	var cl := CanvasLayer.new()
	cl.layer = 6
	cl.add_child(_label)
	hud_parent.add_child(cl)
	player.died.connect(on_player_died)
	spawn_enemies()
	log.add("Skirmish: reach EXTRACT and hold it %d s" % int(SkirmishLargeData.EXTRACT_TIME))


## All roster rows: the compound table plus one list per district (brief: roster rows unchanged).
func _rows() -> Array:
	var rows: Array = []
	rows.append_array(SkirmishLargeData.ENEMIES)
	rows.append_array(SkirmishLargeDistrictNorth.enemies())
	rows.append_array(SkirmishLargeDistrictEast.enemies())
	rows.append_array(SkirmishLargeDistrictSouth.enemies())
	rows.append_array(SkirmishLargeDistrictWest.enemies())
	return rows


func spawn_enemies() -> void:
	var rows := _rows()
	var row_bot: Array[int] = []   # row index -> bots[] index (boss followers shift the array)
	var idx := 0
	for row in rows:
		var route: Array[Vector3] = []
		for q in row["route"]:
			route.append(Vector3(q[0], 0, q[1]))
		var kind: String = row["kind"]
		var pos := Vector3(row["at"][0], float(row.get("y", 0.1)), row["at"][1])
		if kind == "marksman":
			if row.has("spot"):
				var sp: Vector3 = SkirmishLargeData.SPOTS[int(row["spot"])]
				route.append(sp)
				pos = sp + Vector3(0, 0.1, 0)
			else:
				for s in SkirmishLargeData.SPOTS.slice(0, 2):
					route.append(s)
				pos = SkirmishLargeData.SPOTS[0] + Vector3(0, 0.1, 0)
		var b := _spawn(kind, pos, route, idx)
		row_bot.append(bots.size() - 1)
		idx += 1
		if kind == "boss":
			for i in BotDefs.of("boss")["followers"]:
				var f := _spawn("rifleman", b.global_position + Vector3(1.5 * (i * 2 - 1), 0, 1.5), route, idx)
				idx += 1
				f.leader = b
				f.ally = b
				f.label_name = "Guard %d" % (i + 1)
				if i == 0:
					b.ally = f
	for i in rows.size():
		var a: int = rows[i]["ally"]
		var bi: int = row_bot[i]
		if a >= 0 and bots[bi].ally == null:
			var ba: int = row_bot[a]
			bots[bi].ally = bots[ba]
			if bots[ba].ally == null:
				bots[ba].ally = bots[bi]
	session.bots = bots.duplicate()


func _spawn(kind: String, pos: Vector3, route: Array[Vector3], idx: int) -> ScavBot:
	var bot := ScavBot.new()
	bot.setup(session, bal, layout, "%s %d" % [BotDefs.of(kind)["name"], idx + 1], idx, kind, route)
	add_child(bot)
	bot.global_position = pos
	bot.state_changed.connect(func(b, _f, to):
		if HudSettings.on("bot_log"):   # Esc menu > HUD
			log.add("%s: %s" % [b.label_name, to]))
	bot.died.connect(_on_bot_died)
	bots.append(bot)
	return bot


func _on_bot_died(b: ScavBot) -> void:
	kills += 1
	log.add("%s: KILLED" % b.label_name)
	if b.kind == "boss" and not boss_dead:
		boss_dead = true
		log.add("WARLORD DOWN: DEPOT extract is open")
		# turn the amber DEPOT marker green
		for i in extracts.size():
			if extracts[i]["cond"] == "boss" and i < layout.extract_markers.size():
				var mk: Dictionary = layout.extract_markers[i]
				var green := Color(0.2, 1.0, 0.4)
				mk["mat"].albedo_color = Color(green.r, green.g, green.b, 0.45)
				mk["label"].text = "EXTRACT DEPOT\nOPEN"
				mk["label"].modulate = green.lightened(0.3)


func alive_count() -> int:
	var n := 0
	for b in bots:
		if is_instance_valid(b) and not b.body.dead:
			n += 1
	return n


## Extract zone timers. Returns the index of the extract that just completed, or -1.
## "boss" extracts stay locked until the Warlord dies; "call" extracts need CALL_TIME in the
## zone to call the extract in before the normal hold starts. Leaving a zone resets it.
func tick_extract(dt: float, pos: Vector3) -> int:
	for i in extracts.size():
		var e: Dictionary = extracts[i]
		var ep: Vector3 = e["pos"]
		var d := Vector2(pos.x - ep.x, pos.z - ep.z).length()
		if d > SkirmishLargeData.EXTRACT_R:
			e["progress"] = 0.0
			e["call_progress"] = 0.0
			continue
		if e["cond"] == "boss" and not boss_dead:
			continue
		if e["cond"] == "call" and float(e["call_progress"]) < SkirmishLargeData.CALL_TIME:
			e["call_progress"] = minf(float(e["call_progress"]) + dt, SkirmishLargeData.CALL_TIME)
			continue
		e["progress"] = minf(float(e["progress"]) + dt, SkirmishLargeData.EXTRACT_TIME)
		if float(e["progress"]) >= SkirmishLargeData.EXTRACT_TIME:
			return i
	return -1


func extract_status(i: int) -> String:
	var e: Dictionary = extracts[i]
	if e["cond"] == "boss" and not boss_dead:
		return "LOCKED"
	if e["cond"] == "call" and float(e["call_progress"]) < SkirmishLargeData.CALL_TIME:
		return "CALL"
	return "OPEN"


func _process(dt: float) -> void:
	if player == null or over:
		return
	time_s += dt
	if not player.body.dead and tick_extract(dt, player.global_position) >= 0:
		finish(true)
		return
	var parts: Array[String] = []
	for i in extracts.size():
		var e: Dictionary = extracts[i]
		var ep: Vector3 = e["pos"]
		var d := Vector2(player.global_position.x - ep.x, player.global_position.z - ep.z).length()
		var st := extract_status(i)
		if st == "OPEN" and float(e["progress"]) > 0.0:
			st = "EXTRACTING %.1f/%d" % [float(e["progress"]), int(SkirmishLargeData.EXTRACT_TIME)]
		elif st == "CALL":
			st = "CALLING %.0f/%d" % [float(e["call_progress"]), int(SkirmishLargeData.CALL_TIME)]
		parts.append("%s %s %dm" % [e["name"], st, int(d)])
	var txt := "EXTRACT: " + " | ".join(parts) + "    Hostiles left: %d" % alive_count()
	_label.text = txt
	_loot_prompt()


func _loot_prompt() -> void:
	for c in layout.loot_crates:
		if c["taken"]:
			continue
		var to: Vector3 = c["pos"] - player.global_position
		to.y = 0.0
		if to.length() < REACH:
			weapons.prompt = "%s: take supplies (%s)" % [Keybinds.short("t_use"), ", ".join(c["loot"])]
			if player.enabled and player.input.act("t_use"):
				loot(c)
			return


## Hands out a crate's loot list. "ammo": every carried gun loaded and every carried mag full (F88: reloads draw
## from the inventory, so the old top-up of Gun.spares did nothing). "meds": ItemDefs.CRATE_MEDS go into the
## inventory (used from the quick-use bar); what doesn't fit drops at your feet.
func loot(c: Dictionary) -> void:
	c["taken"] = true
	for item in c["loot"]:
		if item == "ammo":
			SkirmishKit.top_up(weapons.inv)
		elif item == "meds":
			for id in ItemDefs.CRATE_MEDS:
				var it := weapons.inv.make(id)
				if not weapons.inv.add(it):
					weapons.item_dropped.emit(it)
	log.add("Looted: %s" % ", ".join(c["loot"]))
	weapons.message.emit("Looted: %s" % ", ".join(c["loot"]))


func on_player_died() -> void:
	player.dead_t = 1.0e9   # no respawn: KIA
	finish(false)


func finish(win: bool) -> void:
	if over:
		return
	over = true
	won = win
	if win:
		session.save_kit(weapons.inv)   # extract keeps what you carried out, loot included (no map change here; the end screen offers it)
	else:
		session.clear_kit()   # KIA loses the kit
	player.enabled = false
	for b in bots:
		if is_instance_valid(b):
			b.set_physics_process(false)
	end_screen = SkirmishEnd.new(win, time_s, kills, bots.size(), session, cheats != null and cheats.cheats_used)
	add_child(end_screen)
