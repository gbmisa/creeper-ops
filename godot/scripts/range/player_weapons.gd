class_name PlayerWeapons
extends Node
## Weapon handling for the range player: rack pickup, slots, fire / ADS, reload (double-tap R = fast),
## fire mode, mag check, zeroing, inspect / fix, hold breath. Emits signals the viewmodel / HUD follow.

signal shot(res: Dictionary, gun: Gun)
signal action(kind: String, secs: float)  # "reload", "fix", "cycle"
signal switched(gun: Gun)
signal message(text: String)

const DOUBLE_TAP := 0.35
const DRAW_TIME := 0.45
const SCOPE_AT := 0.8

var player: TacticalPlayer
var input: InputState
var bal: Ballistics
var rack: RangeRack
var inv: Inventory
var gun_objs := {}  # gun item uid -> Gun
var gun_uid := -1  # item uid of the selected gun
var gun: Gun
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
var _check_t := 0.0
var _reload_t := 99.0
var _reload_fast := false
var _t := 0.0
var _was_left := false
var _clicked := false


func setup(p: TacticalPlayer, i: InputState, b: Ballistics, r: RangeRack) -> void:
	player = p
	input = i
	bal = b
	rack = r
	rng.randomize()
	inv = Inventory.new()
	_starting_kit()
	select_slot("primary")
	_sync_weight()


## Brief loadout: AK in primary, M1911 in holster, rig with 3 AK mags + 2 pistol mags.
func _starting_kit() -> void:
	var rig := inv.make("rig_std")
	inv.place(rig["uid"], "rig")
	var ak := inv.make("ak47")
	inv.place(ak["uid"], "primary")
	var m1911 := inv.make("m1911")
	inv.place(m1911["uid"], "holster")
	_add_mag("ak47", ak["uid"], true)
	for i in 3:
		_add_mag("ak47", -1, false)
	_add_mag("m1911", m1911["uid"], true)
	for i in 2:
		_add_mag("m1911", -1, false)


## Create a full mag item for a weapon; in_gun attaches it to the gun item.
func _add_mag(weapon_id: String, for_gun_uid: int, in_gun: bool) -> void:
	var cal: String = WeaponDefs.of(weapon_id)["cal"]
	var mid: String = ItemDefs.MAG_FOR_CAL[cal]
	var m := inv.make(mid)
	if in_gun:
		inv.to_gun(m["uid"], for_gun_uid)
	else:
		inv.first_fit(m)


func _sync_weight() -> void:
	player.carried_kg = inv.total_kg()


func give(id: String) -> void:
	var item := inv.make(id)
	if not inv.first_fit(item):
		inv.remove(item["uid"])
		message.emit("No room for %s" % ItemDefs.of(id)["name"])
		return
	rack.take(id)
	_sync_weight()
	# select the slot it landed in
	var l: Dictionary = inv.loc[item["uid"]]
	select_slot(str(l["c"]))


## Gun instance for an inventory gun item, seeded from its inserted mag.
func _gun_for(gun_item: Dictionary) -> Gun:
	var uid: int = gun_item["uid"]
	if gun_objs.has(uid):
		return gun_objs[uid]
	var g := Gun.new(str(gun_item["id"]))
	g.spares.clear()
	var mid := inv.mag_in_gun(uid)
	if mid != -1:
		var mi: Dictionary = inv.items[mid]
		g.mag = magazine_from_item(mi)
		if g.def["action"] == "detachable" and g.mag.count() > 0:
			g.chamber = g.mag.pop()
	else:
		g.mag = Magazine.new(g.def["mag"])
	gun_objs[uid] = g
	return g


## Persist the selected gun's remaining rounds back into its mag item.
func _write_mag_back() -> void:
	if gun_uid == -1 or not gun_objs.has(gun_uid):
		return
	var g: Gun = gun_objs[gun_uid]
	var mid := inv.mag_in_gun(gun_uid)
	if mid == -1:
		return
	var mi: Dictionary = inv.items[mid]
	mi["rounds"] = g.mag.count() + (1 if g.chamber != "" else 0)
	if g.mag.count() > 0:
		mi["ammo"] = g.mag.top()
	elif g.chamber != "":
		mi["ammo"] = g.chamber


func select_slot(slot: String) -> void:
	var item := inv.equipped(slot)
	if item.is_empty() or ItemDefs.of(item["id"])["kind"] != "gun":
		return
	_write_mag_back()
	var uid: int = item["uid"]
	if gun_uid == uid and gun != null:
		return
	gun_uid = uid
	gun = _gun_for(item)
	draw_t = DRAW_TIME
	_check_t = 0.0
	mag_text = ""
	switched.emit(gun)


func _process(delta: float) -> void:
	_t += delta
	_pickup_and_slots()
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
		Sfx.play("crossbow_clack")
	recoil.update(delta, gun.def["ergo"])
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
		if player.enabled and input.act("t_use"):
			give(id)
	for pair in [["t_slot_1", "primary"], ["t_slot_2", "secondary"], ["t_slot_3", "holster"]]:
		if player.enabled and input.act(pair[0]):
			select_slot(pair[1])


func _ads(delta: float) -> void:
	var want: bool = trigger_ads or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	want = want and not player.sprinting and draw_t < DRAW_TIME * 0.5 and gun.busy_kind != "reload"
	var rate := 1.0 / RecoilModel.ads_time(gun.def["ergo"])
	ads_amt = move_toward(ads_amt, 1.0 if want else 0.0, rate * delta)
	player.ads_amt = ads_amt
	holding_breath = ads_amt > 0.9 and input.held("t_sprint") and arm_stamina > 0.0
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
	var down: bool = (input.left or trigger_down) and not player.sprinting and draw_t <= 0.0
	var pressed := down and not _was_left
	_was_left = down
	if not down:
		_clicked = false
		var was := gun.busy_kind
		gun.release()
		if was == "" and gun.busy_kind == "cycle":
			action.emit("cycle", gun.busy_t)
			Sfx.play("crossbow_clack")
		return
	if not pressed and gun.mode != "auto":
		return
	var res := gun.fire(rng)
	if res["fired"]:
		_shoot(res)
	elif res["reason"] in ["click", "empty"] and pressed:
		Sfx.play("tick")
		shot.emit(res, gun)


func _shoot(res: Dictionary) -> void:
	var basis := player.cam.global_basis
	var origin := player.eye_pos() + basis.z * -0.3
	for d in gun.shot_dirs(basis, res["ammo"], ads_amt > 0.8, rng):
		bal.spawn(origin, d, res["ammo"])
	recoil.shoot(gun.def, rng)
	BotNoise.emit(player.global_position, BotNoise.SHOT_R, "shot", player)
	RangeSfx.shot(gun.def["class"])
	if res["ping"]:
		Sfx.play("tick")
	shot.emit(res, gun)


func _commands() -> void:
	if input.act("t_reload"):
		if _reload_t < DOUBLE_TAP and gun.busy_kind == "reload" and not _reload_fast:
			gun.busy_t = 0.0
			gun.busy_kind = ""
			start_reload(true)
		else:
			start_reload(false)
	if input.act("t_fire_mode"):
		gun.cycle_mode()
		Sfx.play("click")
	if input.act("t_zero_up"):
		gun.zero_step(1)
	if input.act("t_zero_down"):
		gun.zero_step(-1)
	if input.act("t_mag_check") and not gun.busy():
		_check_t = TacticalConfig.MAG_CHECK_TIME
		mag_text = ""
		action.emit("check", TacticalConfig.MAG_CHECK_TIME)
	if input.act("t_inspect"):
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
	if gun == null or gun_uid == -1:
		return
	var res: Dictionary
	if gun.def["action"] == "tube":
		res = feed_shell(inv, gun, fast)
	else:
		if gun.def["action"] == "enbloc" and gun.mag.count() > 0:
			return  # matches Gun: en-bloc only reloads empty
		res = swap_mag(inv, gun, gun_uid, fast)
	if not bool(res.get("ok", false)):
		message.emit(str(res.get("msg", "Can't reload")))
		return
	gun.external_mag = true  # mags already swapped via the inventory; Gun only runs the timer
	if gun.reload(fast):
		_reload_t = 0.0
		_reload_fast = fast
		_check_t = 0.0
		action.emit("reload", gun.busy_t)
		Sfx.play("crossbow_clack")
	else:
		gun.external_mag = false
	_sync_weight()


## Build a Magazine from an inventory mag item.
static func magazine_from_item(mi: Dictionary) -> Magazine:
	var d := ItemDefs.of(mi["id"])
	var m := Magazine.new(d["cap"])
	var ammo: String = mi.get("ammo", TacAmmoDefs.grades(d["cal"])[0])
	for i in int(mi.get("rounds", 0)):
		if not m.push(ammo):
			break
	return m


## Swap in the fullest compatible spare mag (rig, pockets, backpack order).
## The old mag goes back where the new one was, or first fit. fast = old mag dropped.
## Returns {ok, msg}. Pure logic: headless-testable.
static func swap_mag(inv: Inventory, gun: Gun, gun_uid: int, fast: bool) -> Dictionary:
	var cal: String = gun.def["cal"]
	var cands := inv.spare_mags(cal).filter(func(it): return int((it as Dictionary)["rounds"]) > 0)
	if cands.is_empty():
		return {"ok": false, "msg": "No %s magazine" % cal}
	var new_item: Dictionary = cands[0]
	var new_uid: int = new_item["uid"]
	var new_loc: Dictionary = (inv.loc.get(new_uid, {}) as Dictionary).duplicate()
	var new_rot: int = new_item["rot"]
	# snapshot the outgoing mag before installing the new one
	var old_uid := inv.mag_in_gun(gun_uid)
	var old_rounds := gun.mag.count() + (1 if gun.chamber != "" else 0)
	var old_ammo := gun.mag.top() if gun.mag.count() > 0 else gun.chamber
	# install the new mag
	gun.mag = magazine_from_item(new_item)
	gun.chamber = ""
	if gun.def["action"] == "detachable" and gun.mag.count() > 0:
		gun.chamber = gun.mag.pop()
	inv.to_gun(new_uid, gun_uid)
	# retire the old mag
	if old_uid != -1:
		if fast:
			inv.remove(old_uid)  # dropped, gone
		else:
			var old_item: Dictionary = inv.items[old_uid]
			old_item["rounds"] = old_rounds
			if old_ammo != "":
				old_item["ammo"] = old_ammo
			inv.from_gun(old_uid)
			var placed := false
			if not new_loc.is_empty() and str(new_loc.get("c", "")) != Inventory.GUN_HOME:
				placed = inv.place(old_uid, str(new_loc["c"]), int(new_loc["x"]), int(new_loc["y"]), new_rot)
			if not placed:
				inv.first_fit(old_item)
	return {"ok": true, "msg": ""}


## Tube guns: take one shell from the first loose-ammo stack into a pouch Gun reloads from.
## Returns {ok, msg}. Pure logic: headless-testable.
static func feed_shell(inv: Inventory, gun: Gun, fast: bool) -> Dictionary:
	var cal: String = gun.def["cal"]
	var stacks := inv.ammo_stacks(cal)
	if stacks.is_empty():
		return {"ok": false, "msg": "No %s shells" % cal}
	var st: Dictionary = stacks[0]
	st["count"] = int(st["count"]) - 1
	if int(st["count"]) <= 0:
		inv.remove(int(st["uid"]))
	gun.spares.clear()
	var pouch := Magazine.new(1)
	pouch.push(TacAmmoDefs.grades(cal)[0])
	gun.spares.append(pouch)
	return {"ok": true, "msg": ""}


## Bench: switch the ammo grade and refill the inserted mag plus every spare mag item.
func cycle_ammo_grade() -> void:
	if gun == null:
		return
	gun.ammo_pick = TacAmmoDefs.next_grade(gun.ammo_pick)
	var grade := gun.ammo_pick
	gun.mag.fill(grade)
	if gun.def["action"] == "detachable":
		gun.chamber = grade
	elif gun.def["action"] == "tube":
		gun.chamber = ""
	for uid in inv.items:
		var it: Dictionary = inv.items[uid]
		var d := ItemDefs.of(it["id"])
		if d["kind"] == "mag" and d["cal"] == gun.def["cal"]:
			it["ammo"] = grade
			it["rounds"] = d["cap"]
	_sync_weight()


func _apply_view(_delta: float) -> void:
	player.recoil_off = recoil.offset
	var tired := arm_stamina < 0.12
	var sw := RecoilModel.sway(_t, gun.def, holding_breath, tired)
	player.sway_off = sw * ads_amt
	player.cam.fov = fov_for(ads_amt, gun.def["scope"])


static func fov_for(ads: float, scope: float) -> float:
	var irons := lerpf(TacticalPlayer.BASE_FOV, TacticalPlayer.BASE_FOV - 8.0, minf(1.0, ads / SCOPE_AT))
	if scope <= 1.0 or ads <= SCOPE_AT:
		return irons
	var narrow := rad_to_deg(2.0 * atan(tan(deg_to_rad(TacticalPlayer.BASE_FOV) * 0.5) / scope))
	return lerpf(irons, narrow, (ads - SCOPE_AT) / (1.0 - SCOPE_AT))


func scoped() -> bool:
	return gun != null and gun.def["scope"] > 1.0 and ads_amt > SCOPE_AT
