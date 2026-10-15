class_name RangeTestUtil
## UTIL track checks for `--range-test`: item defs, utility slots, grapple reel onto a roof,
## frag damage in radius, smoke blocking bot sight, flash staggering bots in view.

static var t: RangeTest
static var session: RangeSession
static var player: TacticalPlayer
static var weapons: PlayerWeapons
static var utils: UtilSystem
static var bot_list: Array = []


static func run(test: RangeTest) -> void:
	t = test
	session = RangeSession.new(90210)
	session.noise.reset()
	t._wall(Vector3(0, -0.5, 0), Vector3(40, 1, 40), "concrete", 1.0)  # floor
	t._wall(Vector3(0, 2, -8), Vector3(4, 4, 4), "concrete", 1.0)  # tower: roof at y=4
	player = TacticalPlayer.new()
	player.input = InputState.new()
	player.session = session
	session.add_player(1, true).node = player
	player.global_position = Vector3(0, 1.2, 2)
	t.add_child(player)
	weapons = PlayerWeapons.new()
	weapons.player = player
	weapons.inv = Inventory.new()
	weapons.inv.ids = session.ids
	weapons.session = session
	weapons.process_mode = Node.PROCESS_MODE_DISABLED  # no rack in the harness: skip the per-frame rack.pick
	t.add_child(weapons)
	utils = UtilSystem.new()
	t.add_child(utils)
	utils.setup(player, weapons, session, t.bal, func(): return bot_list)
	for i in 8:  # let the player settle onto the floor
		await t.get_tree().physics_frame
	_defs()
	_slots()
	await _grapple()
	_grenade_items()
	_frag()
	_smoke()
	_flash()


static func _bot_at(pos: Vector3, yaw_deg := 0.0, name := "UtilTest") -> ScavBot:
	var b := ScavBot.new()
	b.setup(session, t.bal, KillHouse.new(), name, 0, "rifleman", [Vector3(0, 0.6, 0)])
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = pos
	b.rotation_degrees.y = yaw_deg
	bot_list.append(b)
	return b


static func _defs() -> void:
	var g := ItemDefs.def_of({"id": "util_grapple"})
	t.check("grapple def is utility 2x2", g["kind"] == "utility" and g["w"] == 2 and g["h"] == 2)
	t.check("frag def is utility 1x1", ItemDefs.def_of({"id": "util_frag"})["kind"] == "utility")
	t.check("smoke def is utility 1x1", ItemDefs.def_of({"id": "util_smoke"})["kind"] == "utility")
	t.check("flash def is utility 1x1", ItemDefs.def_of({"id": "util_flash"})["kind"] == "utility")
	var bino := ItemDefs.def_of({"id": "util_binoculars"})
	t.check("binoculars def is utility 2x1", bino["kind"] == "utility" and bino["w"] == 2 and bino["h"] == 1)
	t.check("stim skipped (MED owns it)", not ItemDefs.ROWS.has("util_stim") and not ItemDefs.ROWS.has("med_stim"))


static func _slots() -> void:
	t.check("utility slots exist", "utility1" in Inventory.SLOTS and "utility2" in Inventory.SLOTS)
	var r1 = weapons.inv.request_place(weapons.inv.make("util_grapple", {}), "utility1")
	var r2 = weapons.inv.request_place(weapons.inv.make("util_frag", {}), "utility2")
	t.check("grapple equips to utility1", r1["ok"], str(r1))
	t.check("frag equips to utility2", r2["ok"], str(r2))
	var r3 = weapons.inv.request_place(weapons.inv.make("util_smoke", {}), "primary")
	t.check("utility item rejected from gun slot", not r3["ok"])
	t.check("t_util_1 is KEY_4", Keybinds.DEFAULTS["t_util_1"][2] == [KEY_4])
	t.check("t_util_2 is KEY_5", Keybinds.DEFAULTS["t_util_2"][2] == [KEY_5])


static func _grapple() -> void:
	var target := Vector3(0, 4.05, -7)  # tower roof top face
	var from: Vector3 = player.eye_pos()
	var dir: Vector3 = (target - from).normalized()
	t.check("grapple in range", from.distance_to(target) < UtilSystem.GRAPPLE_RANGE)
	var r := utils.fire_grapple_at(1, from, dir)
	t.check("grapple fires and attaches", r["ok"], str(r))
	var g: UtilState.GrappleHook = session.util.grapple_for(1)
	t.check("grapple entity attached in session state", g != null and g.attached)
	var max_y := player.global_position.y
	for i in 240:  # 4 s at 12 m/s: plenty for the ~8 m reel
		await t.get_tree().physics_frame
		max_y = maxf(max_y, player.global_position.y)
	t.check("grapple reels player upward", max_y > 3.2, "max_y=%f" % max_y)
	var p := player.global_position
	var on_roof := p.y > 3.0 and Vector2(p.x, p.z + 8.0).length() < 2.5
	t.check("grapple moves player onto the roof", on_roof, "pos=%s" % str(p))
	t.check("grapple released on arrival", not (session.util.grapple_for(1) as UtilState.GrappleHook).attached)
	var r2 := utils.fire_grapple(1)
	t.check("grapple cooldown blocks immediate refire", not r2["ok"] and r2["why"] == "recharging", str(r2))


static func _grenade_items() -> void:
	# utility2 still holds the frag from _slots(); swap it out for the throw tests
	var inv := weapons.inv
	var old = inv.equipped("utility2")
	if old != null:
		inv.request_remove(old)
	var rs = inv.request_place(inv.make("util_smoke", {}), "utility2")
	t.check("smoke equips to utility2", rs["ok"], str(rs))
	var r := utils.throw_grenade(1, "util_smoke", 0.05)
	t.check("smoke throw spawns entity", r["ok"] and session.util.grenades.size() == 1, str(r))
	t.check("thrown smoke consumed from slot", inv.equipped("utility2") == null)
	var rf = inv.request_place(inv.make("util_flash", {}), "utility2")
	t.check("flash equips to utility2", rf["ok"], str(rf))
	var r2 := utils.throw_grenade(1, "util_flash", 0.05)
	t.check("flash throw spawns entity", r2["ok"], str(r2))


static func _frag() -> void:
	var near := _bot_at(Vector3(5, 0.6, 2), 0.0, "FragNear")
	var far := _bot_at(Vector3(20, 0.6, 2), 0.0, "FragFar")
	# live frag makes nearby bots flee (checked before any blast: all bots alive)
	var g := UtilState.ThrownUtil.new()
	g.kind = "frag"
	g.pos = Vector3(5, 0.5, 2)
	utils._flee_check(g)
	t.check("bot flees live frag", near._has_target and near._target.x > near.global_position.x + 5.0,
		"target=%s" % str(near._target))
	t.check("bot outside flee radius holds", far._target.x < 10.0,
		"target=%s" % str(far._target))
	var hp0: float = near.body.hp["thorax"]
	var hp_far0: float = far.body.hp["thorax"]
	utils._detonate_frag(Vector3(8, 0.5, 4), 1)  # 3.6 m from near, ~15 m from far
	t.check("frag damages bot in radius", near.body.hp["thorax"] < hp0,
		"%f -> %f" % [hp0, near.body.hp["thorax"]])
	t.check("frag spares bot outside radius", is_equal_approx(far.body.hp["thorax"], hp_far0))


static func _smoke() -> void:
	# wait out the test smoke/flash from _grenade_items, then place a fresh volume
	for i in 8:
		await t.get_tree().physics_frame
	session.util.smokes.clear()
	var s := UtilState.SmokeVolume.new()
	s.id = 1
	s.pos = Vector3(0, 1.0, 0)
	s.radius = 6.0
	s.until = 9999.0
	var space = t.get_world_3d().direct_space_state
	var eye := Vector3(0, 1.6, -10)
	var pt := Vector3(0, 1.6, 10)
	t.check("clear sight line without smoke", BotPerception.los(space, eye, [pt], []))
	t.check("smoke volume blocks sight line", not BotPerception.los(space, eye, [pt], [s]))
	utils._detonate_smoke(Vector3(0, 0.2, 0))
	t.check("smoke detonation registers a volume", session.util.smokes.size() == 1)
	var v: UtilState.SmokeVolume = session.util.smokes[0]
	t.check("smoke volume lasts 25 s", v.until > 20.0, "until=%f" % v.until)


static func _flash() -> void:
	var facing := _bot_at(Vector3(0, 0.6, 5), 0.0, "FlashFacing")  # faces -z, toward the blast
	var away := _bot_at(Vector3(0, 0.6, 5), 180.0, "FlashAway")  # faces +z, blast behind
	utils._detonate_flash(Vector3(0, 1.0, -5))
	t.check("flash staggers bot with blast in view", facing.stagger_t >= 3.9, "stagger_t=%f" % facing.stagger_t)
	t.check("flash spares bot facing away", away.stagger_t <= 0.0, "stagger_t=%f" % away.stagger_t)
