class_name RangeHud
extends CanvasLayer
## Range HUD: no crosshair (optional hip-fire dot), weapon / mode / ammo / zero / mag-check on the right,
## stamina bars, prompt, messages, help panel (t_help). Hit log comes in phase 3.

var weapons: PlayerWeapons
var player: TacticalPlayer
var scope := ScopeOverlay.new()
var _gun_lbl: Label
var _ammo_lbl: Label
var _mag_lbl: Label
var _msg_lbl: Label
var _prompt_lbl: Label
var _help: PanelContainer
var _leg: ProgressBar
var _arm: ProgressBar
var _dot: ColorRect
var _msg_t := 0.0
var _show_dot := false
var _status_lbl: Label
var _tunnel := ColorRect.new()


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	layer = 5
	_tunnel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tunnel.color = Color(0, 0, 0, 0)
	_tunnel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tunnel)
	add_child(scope)
	var right := UiKit.panel(Color(0.04, 0.05, 0.07, 0.6))
	right.position = Vector2(1330, 700)
	right.custom_minimum_size = Vector2(250, 0)
	add_child(right)
	var col := VBoxContainer.new()
	right.add_child(col)
	_gun_lbl = UiKit.label("", 20)
	_ammo_lbl = UiKit.label("", 15)
	_mag_lbl = UiKit.label("", 15, Color(1.0, 0.85, 0.45))
	for l in [_gun_lbl, _ammo_lbl, _mag_lbl]:
		col.add_child(l)
	var left := UiKit.panel(Color(0.04, 0.05, 0.07, 0.6))
	left.position = Vector2(20, 790)
	add_child(left)
	var bars := VBoxContainer.new()
	left.add_child(bars)
	bars.add_child(UiKit.caption("LEG STAMINA"))
	_leg = UiKit.bar(180, 10, Color(0.4, 0.8, 0.5))
	bars.add_child(_leg)
	bars.add_child(UiKit.caption("ARM STAMINA"))
	_arm = UiKit.bar(180, 10, Color(0.9, 0.75, 0.3))
	bars.add_child(_arm)
	_prompt_lbl = UiKit.label("", 20, Color(1, 0.95, 0.7))
	_prompt_lbl.position = Vector2(680, 560)
	add_child(_prompt_lbl)
	_msg_lbl = UiKit.label("", 22)
	_msg_lbl.position = Vector2(660, 620)
	add_child(_msg_lbl)
	_help = UiKit.panel(Color(0.04, 0.05, 0.07, 0.35))
	_help.position = Vector2(8, 8)
	var h := UiKit.label(_help_text(), 11, Color(1, 1, 1, 0.75))
	_help.add_child(h)
	add_child(_help)
	_dot = ColorRect.new()
	_dot.size = Vector2(4, 4)
	_dot.color = Color(1, 1, 1, 0.8)
	_dot.position = Vector2(798, 448)
	_dot.visible = false
	add_child(_dot)
	_status_lbl = UiKit.label("", 13, Color(1.0, 0.62, 0.4))
	_status_lbl.position = Vector2(20, 690)
	add_child(_status_lbl)
	w.message.connect(say)
	p.message.connect(say)


func say(text: String) -> void:
	_msg_lbl.text = text
	_msg_t = 2.5


func _help_text() -> String:
	var k := func(ids: Array) -> String:
		var out := []
		for i in ids:
			out.append(Keybinds.short(i))
		return "".join(out) if ids.size() == 4 else "/".join(out)
	var rows := [[k.call(["t_forward", "t_left", "t_back", "t_right"]), "Move"], [k.call(["t_sprint"]), "Sprint / hold breath"],
		[k.call(["t_crouch"]), "Crouch"], [k.call(["t_lean_left", "t_lean_right"]), "Lean"], [k.call(["t_jump"]), "Jump"],
		[k.call(["t_use"]), "Use (rack, benches, items)"], ["1-3", "Primary / secondary / holster"],
		[k.call(["inventory"]), "Inventory"], [k.call(["drop"]), "Drop gun"], [k.call(["t_reload"]), "Reload (x2 fast)"],
		[k.call(["t_fire_mode"]), "Fire mode"], [k.call(["t_mag_check"]), "Check mag"], [k.call(["t_inspect"]), "Inspect / fix"],
		[k.call(["t_zero_up", "t_zero_down"]), "Zero up/down"], [k.call(["t_crosshair"]), "Hip dot"],
		[k.call(["med_quick_1", "med_quick_2", "med_quick_3", "med_quick_4"]), "Quick-use meds"], [k.call(["t_help"]), "Help"]]
	var out := "LMB Fire   RMB Aim   Esc Menu\n"
	for r in rows:
		out += "%s  %s\n" % [r[0], r[1]]
	return out.strip_edges()


func _process(delta: float) -> void:
	if weapons == null:
		return
	var inp := player.input
	if inp.act("t_help"):
		_help.visible = not _help.visible
	if inp.act("t_crosshair"):
		_show_dot = not _show_dot
	_dot.visible = _show_dot and weapons.ads_amt < 0.5
	scope.visible = weapons.scoped()
	if weapons.gun != null:
		scope.style = weapons.gun.reticle()
	var g := weapons.gun
	if g == null:
		_gun_lbl.text = "No weapon"
		_ammo_lbl.text = "Take one from the rack"
		_mag_lbl.text = ""
	else:
		_gun_lbl.text = "%s  [%s]" % [g.def["name"], g.mode.to_upper()]
		_ammo_lbl.text = "%s   Zero %d m" % [TacAmmoDefs.of(g.loaded_ammo() if g.loaded_ammo() != "" else g.ammo_pick)["name"], int(g.zero_dist())]
		var s := ""
		if g.malf != "" and g.malf_known:
			s = "MALFUNCTION"
		elif g.busy():
			s = g.busy_kind.capitalize() + "..."
		elif weapons.mag_text != "":
			s = "Mag: " + weapons.mag_text
		elif g.needs_cycle:
			s = "Release trigger to cycle"
		_mag_lbl.text = s
	_prompt_lbl.text = weapons.prompt
	_msg_t = maxf(0.0, _msg_t - delta)
	_msg_lbl.visible = _msg_t > 0.0
	_leg.value = player.leg_stamina * 100.0
	_arm.value = weapons.arm_stamina * 100.0
	_status_lbl.text = _status_text()
	var tun := 0.0
	if player.body.total_frac() < 0.35 or float(player.status.m["dehydration"]) > 0.8:
		tun = 0.45
	_tunnel.color = Color(0, 0, 0, tun)


## Status icons with timers + build-up bars, only when something is active.
static func _bar(full: int, total: int) -> String:
	var s := ""
	for i in total:
		s += "▓" if i < full else "░"
	return s


func _status_text() -> String:
	var b := player.body
	var s := player.status
	var parts := []
	if not b.bleeds.is_empty():
		parts.append("BLEED x%d" % b.bleeds.size())
	if not b.fractured.is_empty():
		parts.append("FRACTURE")
	var names := {"pain": "PAIN", "radiation": "RAD", "toxication": "TOX", "dehydration": "DEHYDR",
		"energy": "ENERGY", "fatigue": "FATIGUE", "contusion": "CONCUSS"}
	for k in StatusEffects.METERS:
		var v: float = s.m[k]
		if v >= 0.5:
			var bar := int(5.0 * v)
			parts.append("%s %s" % [names[k], _bar(bar, 5)])
	if s.pain_off_t > 0.0:
		parts.append("ANALGESIA %d:%02d" % [int(s.pain_off_t) / 60, int(s.pain_off_t) % 60])
	if s.regen_t > 0.0:
		parts.append("REGEN %d:%02d" % [int(s.regen_t) / 60, int(s.regen_t) % 60])
	if s.stam_buff_t > 0.0:
		parts.append("STIM %ds" % int(s.stam_buff_t))
	if not player.med_use.is_empty():
		parts.append("USING %.1fs" % float(player.med_use.get("t", 0.0)))
	return "   ".join(parts)
