class_name PlayerWeapons
extends Node
## Weapon handling for the range player: rack pickup, slots, fire / ADS, reload (double-tap R = fast),
## fire mode, mag check, zeroing, inspect / fix, hold breath. Emits signals the viewmodel / HUD follow.

signal shot(res: Dictionary, gun: Gun)
signal action(kind: String, secs: float)  # "reload", "fix", "cycle"
signal switched(gun: Gun)
signal message(text: String)
signal item_dropped(item: Dictionary)  # left the inventory with nowhere to go; the world spawns it

const DOUBLE_TAP := 0.35
const DRAW_TIME := 0.45
const SCOPE_AT := 0.8
const LASER_SPOT := 1.5  # bots notice a lasered player from 1.5x their sight range

var player: TacticalPlayer
var input: InputState
var bal: Ballistics
var rack: RangeRack
var session: RangeSession
const HAND_SLOTS := ["primary", "secondary", "holster"]  # keys 1 / 2 / 3

var inv := Inventory.new()
var reloader := InvReload.new(inv)
var gun: Gun
var gun_item := {}
var ads_amt := 0.0
var arm_stamina := 1.0
var holding_breath := false
var recoil := RecoilModel.new()
var rng := RandomNumberGenerator.new()
var draw_t := 0.0
var mag_text := ""
var mag_text_t := 0.0
var prompt := ""
var trigger_ads := false  # debug overrides (--ads, --fire)
var trigger_down := false
var ui_open := false  # inventory screen up: no firing, no aiming
var _check_t := 0.0
var _reload_t := 99.0
var _reload_fast := false
var _t := 0.0
var _was_left := false
var _clicked := false


func setup(p: TacticalPlayer, i: InputState, b: Ballistics, r: RangeRack, s: RangeSession) -> void:
	player = p
	input = i
	bal = b
	rack = r
	session = s
	reloader.infinite = session != null and session.maps.selected in RangeMaps.INFINITE_AMMO
	rng.seed = s.next_seed()
	if s.saved_kit.is_empty():
		StarterLoadout.fill(inv)
	else:
		inv.load_dict(s.saved_kit)
	inv.ids = s.ids
	recoil.tarkov = s.local.recoil_mode if s.local != null else false
	player.carried_kg = inv.total_kg()
	select_slot("primary")


func give(id: String) -> void:
	HandGear.give(self, id)


func sync() -> void:
	HandGear.sync(self)


func refill_mags() -> void:
	HandGear.refill_mags(self)


func select_slot(slot: String) -> void:
	var it = inv.equipped(slot)
	if it == null or (not gun_item.is_empty() and gun_item["uid"] == it["uid"]):
		return
	gun_item = it
	gun = it["gun"]
	draw_t = DRAW_TIME
	_check_t = 0.0
	mag_text = ""
	switched.emit(gun)


func reload_cancel() -> void:
	if not gun_item.is_empty():
		reloader.cancel(gun_item)


## Drops the gun in hand out of the inventory; item_dropped hands it to the world.
func drop_current() -> void:
	if gun_item.is_empty():
		return
	var it := gun_item
	reloader.cancel(it)
	inv.remove(it)
	RangeAudio.event({"kind": "inventory", "item": "gun", "ev": "drop", "local": true})
	sync()
	item_dropped.emit(it)


func _process(delta: float) -> void:
	_t += delta
	if session != null and session.local != null:
		recoil.tarkov = session.local.recoil_mode
	player.spot_mult = LASER_SPOT if gun != null and gun.fit.get("under", "") == "laser" else 1.0
	_pickup_and_slots()
	sync()
	if gun == null or not player.enabled:
		_idle(delta)
		return
	var before := gun.busy_kind
	gun.update(delta)
	draw_t = maxf(0.0, draw_t - delta)
	_reload_t += delta
	_ads(delta)
	_trigger()
	_commands()
	if before != "" and gun.busy_kind == "" and before == "reload":
		_gun_snd("mag_in")
		var left := reloader.finish(gun_item)
		if not left.is_empty():
			item_dropped.emit(left)
	recoil.update(delta, gun.def["ergo"], gun.def)
	_apply_view(delta)
	mag_text_t = maxf(0.0, mag_text_t - delta)
	if _check_t > 0.0:
		_check_t -= delta
		if _check_t <= 0.0:
			mag_text = gun.mag.estimate() + (" + chamber" if gun.chamber != "" and gun.def["action"] == "detachable" else "")
			mag_text_t = 5.0


func _idle(delta: float) -> void:
	ads_amt = move_toward(ads_amt, 0.0, delta * 4.0)
	player.ads_amt = ads_amt


func _pickup_and_slots() -> void:
	prompt = ""
	var id := rack.pick(player.eye_pos(), -player.cam.global_basis.z)
	if id != "":
		prompt = "%s: take %s" % [Keybinds.short("t_use"), WeaponDefs.of(id)["name"]]
		if player.enabled and input.frame.act("t_use"):
			give(id)
			RangeAudio.event({"kind": "inventory", "item": "gun", "ev": "pick", "local": true})
	for n in HAND_SLOTS.size():
		if player.enabled and input.frame.act("t_slot_%d" % (n + 1)):
			select_slot(HAND_SLOTS[n])


func _ads(delta: float) -> void:
	var want: bool = trigger_ads or input.frame.right
	want = want and not ui_open and not player.sprinting and draw_t < DRAW_TIME * 0.5 and gun.busy_kind != "reload"
	var rate := 1.0 / (RecoilModel.ads_time(gun.def["ergo"]) * gun.stat("ads_mult"))
	ads_amt = move_toward(ads_amt, 1.0 if want else 0.0, rate * delta)
	player.ads_amt = ads_amt
	holding_breath = ads_amt > 0.9 and input.frame.held("t_sprint") and arm_stamina > 0.0
	var drain := 0.0
	if ads_amt > 0.9:
		drain = TacticalConfig.ARM_STAMINA_DRAIN_ADS * gun.def["kg"] / 4.0
		if holding_breath:
			drain += TacticalConfig.ARM_STAMINA_DRAIN_HOLD
	if drain > 0.0:
		arm_stamina = maxf(0.0, arm_stamina - drain * delta)
	else:
		arm_stamina = minf(1.0, arm_stamina + TacticalConfig.ARM_STAMINA_REGEN * delta)


func _trigger() -> void:
	var down: bool = (input.frame.left or trigger_down) and not ui_open and not player.sprinting and draw_t <= 0.0
	var pressed := down and not _was_left
	_was_left = down
	if not down:
		_clicked = false
		var was := gun.busy_kind
		gun.release()
		if was == "" and gun.busy_kind == "cycle":
			action.emit("cycle", gun.busy_t)
			_gun_snd("action")
		return
	if not pressed and gun.mode != "auto":
		return
	var res := gun.fire(rng)
	if res["fired"]:
		_shoot(res)
	elif res["reason"] in ["click", "empty"] and pressed:
		_gun_snd("dry")
		shot.emit(res, gun)


func _shoot(res: Dictionary) -> void:
	var basis := player.cam.global_basis
	var origin := player.eye_pos() + basis.z * -0.3
	for d in gun.shot_dirs(recoil.aim_basis(basis), res["ammo"], ads_amt > 0.8, rng):
		bal.spawn(origin, d, res["ammo"], [], gun.stat("vel"))
	recoil.shoot(gun.eff_def(), rng)
	if session != null:
		session.noise.emit(player.global_position, BotNoise.SHOT_R * gun.stat("noise"), "shot", player)
		session.events.shot_fired.emit(res, gun)
	RangeAudio.event({"kind": "shot", "item": gun.id, "local": true, "cal": gun.def["cal"], "cls": gun.def["class"],
		"suppressed": gun.stat("noise") < 0.9})
	if res["ping"]:
		RangeAudio.event({"kind": "sample", "item": "garand_ping", "local": true, "db": -4.0})
	shot.emit(res, gun)


func _gun_snd(ev: String) -> void:
	RangeAudio.event({"kind": "gun", "item": gun.id, "ev": ev, "local": true, "cal": gun.def["cal"], "cls": gun.def["class"]})


func _commands() -> void:
	if input.frame.act("drop"):
		drop_current()
		return
	if input.frame.act("t_reload"):
		if _reload_t < DOUBLE_TAP and gun.busy_kind == "reload" and not _reload_fast:
			gun.busy_t = 0.0
			gun.busy_kind = ""
			start_reload(true)
		else:
			start_reload(false)
	if input.frame.act("t_zoom"):
		gun.toggle_zoom()
		Sfx.play("click")
	if input.frame.act("t_fire_mode"):
		gun.cycle_mode()
		_gun_snd("mode")
	if input.frame.act("t_zero_up"):
		gun.zero_step(1)
	if input.frame.act("t_zero_down"):
		gun.zero_step(-1)
	if input.frame.act("t_mag_check") and not gun.busy():
		_check_t = TacticalConfig.MAG_CHECK_TIME
		mag_text = ""
		action.emit("check", TacticalConfig.MAG_CHECK_TIME)
	if input.frame.act("t_inspect"):
		var r := gun.inspect()
		match r:
			"ok":
				message.emit("Weapon looks fine")
			"busy":
				pass
			"fixing":
				message.emit("Clearing it...")
				action.emit("fix", gun.busy_t)
			_:
				message.emit({"misfire": "Misfire: dud round", "feed": "Failure to feed", "jam": "Jammed"}[r])


func start_reload(fast: bool) -> void:
	var r := reloader.begin(gun_item, fast)
	if r == "none":
		message.emit("No magazine" if gun.def["action"] != "tube" else "No %s rounds" % gun.def["cal"])
	if r == "ok":
		_reload_t = 0.0
		_reload_fast = fast
		_check_t = 0.0
		action.emit("reload", gun.busy_t)
		_gun_snd("mag_out")


func _apply_view(_delta: float) -> void:
	player.recoil_off = recoil.offset
	var tired := arm_stamina < 0.12
	var sw := RecoilModel.sway(_t, gun.def, holding_breath, tired)
	player.sway_off = sw * ads_amt
	player.cam.fov = fov_for(ads_amt, gun.stat("scope"))


static func fov_for(ads: float, scope: float) -> float:
	var irons := lerpf(TacticalPlayer.BASE_FOV, TacticalPlayer.BASE_FOV - 8.0, minf(1.0, ads / SCOPE_AT))
	if scope <= 1.0 or ads <= SCOPE_AT:
		return irons
	var narrow := rad_to_deg(2.0 * atan(tan(deg_to_rad(TacticalPlayer.BASE_FOV) * 0.5) / scope))
	return lerpf(irons, narrow, (ads - SCOPE_AT) / (1.0 - SCOPE_AT))


func scoped() -> bool:
	return gun != null and gun.stat("scope") > 1.0 and ads_amt > SCOPE_AT
