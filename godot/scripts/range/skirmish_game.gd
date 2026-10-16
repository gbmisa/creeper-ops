class_name SkirmishGame
extends Node3D
## Skirmish rules: spawns the roster, objective HUD, extract timer (stand in the zone EXTRACT_TIME), loot crates, EXTRACTED / KIA.
## `tick_extract` and `loot` are plain functions so the range test can drive them.

const REACH := 2.2

var layout: SkirmishLayout
var bots: Array[ScavBot] = []
var player: TacticalPlayer
var weapons: PlayerWeapons
var bal: Ballistics
var log: RangeHitLog
var session: RangeSession
var time_s := 0.0
var kills := 0
var progress := 0.0
var over := false
var won := false
var end_screen: SkirmishEnd
var _label: Label


func build_world() -> void:
	RangeLayout._environment(self)
	layout = SkirmishLayout.new()
	add_child(layout)
	layout.build()


func start(p: TacticalPlayer, w: PlayerWeapons, b: Ballistics, l: RangeHitLog, hud_parent: Node, s: RangeSession) -> void:
	player = p
	weapons = w
	bal = b
	log = l
	session = s
	session.noise.reset()
	layout.bake()
	_label = UiKit.label("", 20, Color(0.8, 1.0, 0.8))
	_label.position = Vector2(520, 14)
	var cl := CanvasLayer.new()
	cl.layer = 6
	cl.add_child(_label)
	hud_parent.add_child(cl)
	player.died.connect(on_player_died)
	spawn_enemies()
	log.add("Skirmish: reach EXTRACT and hold it %d s" % int(SkirmishData.EXTRACT_TIME))


func spawn_enemies() -> void:
	var idx := 0
	for row in SkirmishData.ENEMIES:
		var route: Array[Vector3] = []
		for q in row["route"]:
			route.append(Vector3(q[0], 0, q[1]))
		var kind: String = row["kind"]
		if kind == "marksman":
			for s in SkirmishData.SPOTS:
				route.append(s)
		var b := _spawn(kind, Vector3(row["at"][0], 0.1, row["at"][1]) if kind != "marksman" else SkirmishData.SPOTS[0] + Vector3(0, 0.1, 0), route, idx)
		idx += 1
		if kind == "boss":
			for i in BotDefs.of("boss")["followers"]:
				var f := _spawn("rifleman", b.global_position + Vector3(1.5 * (i * 2 - 1), 0, 1.5), route, idx + i)
				f.leader = b
				f.ally = b
				f.label_name = "Guard %d" % (i + 1)
				if i == 0:
					b.ally = f
	for i in SkirmishData.ENEMIES.size():
		var a: int = SkirmishData.ENEMIES[i]["ally"]
		if a >= 0 and bots[i].ally == null:
			bots[i].ally = bots[a]
			if bots[a].ally == null:
				bots[a].ally = bots[i]


func _spawn(kind: String, pos: Vector3, route: Array[Vector3], idx: int) -> ScavBot:
	var bot := ScavBot.new()
	bot.setup(session, bal, layout, "%s %d" % [BotDefs.of(kind)["name"], idx + 1], idx, kind, route)
	add_child(bot)
	bot.global_position = pos
	bot.state_changed.connect(func(b, _f, to): log.add("%s: %s" % [b.label_name, to]))
	bot.died.connect(_on_bot_died)
	bots.append(bot)
	return bot


func _on_bot_died(b: ScavBot) -> void:
	kills += 1
	log.add("%s: KILLED" % b.label_name)


func alive_count() -> int:
	var n := 0
	for b in bots:
		if is_instance_valid(b) and not b.body.dead:
			n += 1
	return n


## Extract zone timer. Returns true once the player has stood in the zone for EXTRACT_TIME.
func tick_extract(dt: float, pos: Vector3) -> bool:
	var d := Vector2(pos.x - SkirmishData.EXTRACT.x, pos.z - SkirmishData.EXTRACT.z).length()
	if d <= SkirmishData.EXTRACT_R:
		progress = minf(progress + dt, SkirmishData.EXTRACT_TIME)
	else:
		progress = 0.0
	return progress >= SkirmishData.EXTRACT_TIME


func _process(dt: float) -> void:
	if player == null or over:
		return
	time_s += dt
	if not player.body.dead and tick_extract(dt, player.global_position):
		finish(true)
		return
	var d := Vector2(player.global_position.x - SkirmishData.EXTRACT.x, player.global_position.z - SkirmishData.EXTRACT.z).length()
	var txt := "OBJECTIVE: reach EXTRACT (%d m) and hold it %d s    Hostiles left: %d" % [int(d), int(SkirmishData.EXTRACT_TIME), alive_count()]
	if progress > 0.0:
		txt = "EXTRACTING  %.1f / %d s  (stay in the zone)" % [progress, int(SkirmishData.EXTRACT_TIME)]
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


## Hands out a crate's loot list. Items: "ammo" tops up spare magazines, "meds" heals (hook for the inventory branch).
func loot(c: Dictionary) -> void:
	c["taken"] = true
	for item in c["loot"]:
		if item == "ammo":
			for g in weapons.guns.values():
				_restock(g)
		elif item == "meds":
			player.body.heal(0.6)
	log.add("Looted: %s" % ", ".join(c["loot"]))


func _restock(g: Gun) -> void:
	for m in g.spares:
		if m.count() < m.cap:
			m.fill(g.ammo_pick)
	while g.def["action"] != "tube" and g.spares.size() < int(g.def["spares"]):
		var m := Magazine.new(g.def["mag"])
		m.fill(g.ammo_pick)
		g.spares.append(m)


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
	end_screen = SkirmishEnd.new(win, time_s, kills, bots.size(), session)
	add_child(end_screen)
