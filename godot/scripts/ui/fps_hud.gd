class_name FpsHud
extends Control
## Operative HUD: crosshair, suit and sprayer-tank bars, weapon name, interaction prompt,
## creeper warning, recall progress, damage flash and in-creeper tint.

var _cross: Crosshair
var _suit_lbl: Label
var _suit: ProgressBar
var _shield_lbl: Label
var _shield: ProgressBar
var _tank: ProgressBar
var _weapon: Label
var _salvage: Label
var _charge: ProgressBar
var _need: Label
var _prompt: Label
var _warn: Label
var _spotted: Label
var _recall: ProgressBar
var _recall_note: Label
var _flash: ColorRect
var _tint: ColorRect
var _hit: HitOverlay
var hold_bar: HoldBar
var _edge: Panel
var _edge_t := 0.0
var _lost_chip: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint = _rect(Color(0.1, 0.3, 1.0, 0.0))
	_flash = _rect(Color(1.0, 0.1, 0.05, 0.0))
	_hit = HitOverlay.new()
	add_child(_hit)
	_cross = Crosshair.new()
	add_child(_cross)
	var panel := UiKit.panel(Color(UiKit.BG_SOLID, 0.6))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.position = Vector2(-146, -206)  # bottom centre: the event log owns bottom-left
	add_child(panel)
	UiKit.brackets(panel)
	var box := UiKit.vbox(3)
	panel.add_child(box)
	_weapon = UiKit.label("", 18, UiKit.ACCENT)
	_weapon.add_theme_font_override("font", UiTheme.header_font())
	box.add_child(_weapon)
	var sr := UiKit.hbox(6)
	sr.add_child(UiKit.caption("Suit"))
	_suit_lbl = UiKit.mono("", 13)
	_suit_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_suit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sr.add_child(_suit_lbl)
	box.add_child(sr)
	_suit = UiKit.bar(260, 14, UiKit.GOOD)
	box.add_child(_suit)
	_shield_lbl = UiKit.caption("Shield")
	box.add_child(_shield_lbl)
	_shield = UiKit.bar(260, 10, UiKit.ENERGY)
	box.add_child(_shield)
	box.add_child(UiKit.caption("Sprayer tank"))
	_tank = UiKit.bar(260, 10, Color("9ff6ff"))
	box.add_child(_tank)
	_salvage = UiKit.label("", 14, UiKit.WARN)
	box.add_child(_salvage)
	_charge = UiKit.bar(260, 8, Color("e8fbff"))
	box.add_child(_charge)
	_need = _centered(UiKit.label("", 18, UiKit.WARN), 78)
	_prompt = _centered(UiKit.label("", 20, UiKit.WARN), 60)
	_warn = _centered(UiKit.label("", 22, UiKit.BAD), -140)
	_spotted = _centered(UiKit.label("", 28, UiKit.BAD), -156)
	_spotted.custom_minimum_size.x = 280
	_spotted.position.x = -140
	_recall = UiKit.bar(260, 10, UiKit.ENERGY)
	_recall.set_anchors_preset(Control.PRESET_CENTER)
	_recall.position = Vector2(-130, 100)
	add_child(_recall)
	_recall_note = UiKit.label("", 16, UiKit.ENERGY)
	_recall_note.set_anchors_preset(Control.PRESET_CENTER)
	_recall_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recall_note.position = Vector2(-160, 116)
	_recall_note.custom_minimum_size.x = 320
	add_child(_recall_note)
	hold_bar = HoldBar.new()
	add_child(hold_bar)
	_edge = Panel.new()
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1.0, 0.1, 0.05)
	sb.set_border_width_all(36)
	sb.shadow_color = Color(1.0, 0.1, 0.05, 0.5)
	sb.shadow_size = 40
	_edge.add_theme_stylebox_override("panel", sb)
	_edge.modulate.a = 0.0
	add_child(_edge)
	_lost_chip = UiKit.label("", 15, UiKit.BAD)
	_lost_chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lost_chip.position = Vector2(-260, 48)
	_lost_chip.visible = false
	add_child(_lost_chip)


## Red screen-edge pulse (base alert).
func pulse() -> void:
	_edge_t = Config.BASE_ALERT_PULSE


func set_losses(n: int) -> void:
	_lost_chip.visible = n > 0
	_lost_chip.text = "BASE: %d lost / %ds" % [n, int(Config.BASE_LOST_WINDOW)]


func _process(dt: float) -> void:
	_edge_t = maxf(0.0, _edge_t - dt)
	_edge.modulate.a = 0.6 * (_edge_t / Config.BASE_ALERT_PULSE) * (0.6 + 0.4 * sin(_edge_t * 25.0))


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _centered(l: Label, y: float) -> Label:
	l.set_anchors_preset(Control.PRESET_CENTER_TOP if y < 0 else Control.PRESET_CENTER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.position.y = (-y if y < 0 else y)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_font_override("font", UiTheme.header_font())
	add_child(l)
	return l


func spotted_lit() -> bool:
	return _spotted.visible and _spotted.text == "SPOTTED"


func refresh(fps: FpsMode, spotted := false) -> void:
	var cap := maxf(1.0, OperativeUpgrades.suit_max())
	var suit := clampf(maxf(0.0, fps.suit) / cap, 0.0, 1.0)
	_suit.value = suit
	_suit_lbl.text = "%d / %d" % [ceili(maxf(0.0, fps.suit)), roundi(cap)]
	UiKit.set_bar_color(_suit, UiKit.BAD if suit < 0.35 else UiKit.GOOD)
	var smax := OperativeUpgrades.shield_max()
	_shield_lbl.visible = smax > 0.0
	_shield.visible = smax > 0.0
	if smax > 0.0:
		_shield.value = clampf(fps.shield / smax, 0.0, 1.0)
	_hit.feel = fps.weapons.feel
	_tank.value = fps.weapons.tank / Config.TANK_MAX
	var low := fps.weapons.tank < Config.TANK_MAX * 0.2
	UiKit.set_bar_color(_tank, UiKit.BAD if low else (Color("5fffd0") if fps.weapons.spraying else Color("9ff6ff")))
	_weapon.text = fps.weapons.label()
	_salvage.text = fps.weapons.advanced.salvage_line()
	if OperativeUpgrades.charges > 0:
		_salvage.text += ("  |  " if _salvage.text != "" else "") + "Demo charges %d/%d" % [OperativeUpgrades.charges, Config.DEMO_CHARGE_MAX]
	_salvage.visible = _salvage.text != ""
	var ch := fps.weapons.advanced.charge_ratio()
	_charge.visible = ch >= 0.0
	if ch >= 0.0:
		_charge.value = ch
	_need.text = fps.weapons.advanced.hud_need()
	_prompt.text = fps.prompt
	_warn.text = ("IN CREEPER: SUIT BURNING%s" % (" FAST" if fps.creeper_depth > 1.0 else "")) if fps.in_creeper else ""
	_spotted.visible = spotted
	_spotted.text = "SPOTTED" if spotted else ""
	if spotted:
		_spotted.modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.006))
	_cross.color = UiKit.BAD if fps.weapons.hit_marker > 0.0 else UiKit.TEXT
	var holding := fps.recall_hold > 0.0
	_recall.visible = holding
	_recall.value = fps.recall_hold / Config.RECALL_HOLD
	_recall_note.visible = holding
	_recall_note.text = "Free recall" if fps.recall_cd <= 0.0 else "Teleporter cooldown %ds" % ceili(fps.recall_cd)
	if fps.hold_frac >= 0.0:
		hold_bar.show_hold(fps.hold_label, fps.hold_frac)
	else:
		hold_bar.hide_hold()
	_flash.color.a = 0.12 if fps.hurt_flash > 0.0 else (0.12 if fps.in_creeper else 0.0)
	_tint.color.a = minf(0.45, 0.15 + fps.creeper_depth * 0.15) if fps.in_creeper else 0.0
