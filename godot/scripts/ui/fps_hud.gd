class_name FpsHud
extends Control
## Operative HUD: crosshair, suit and sprayer-tank bars, weapon name, interaction prompt,
## creeper warning, recall progress, damage flash and in-creeper tint.

var _cross: Label
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
var _recall: ProgressBar
var _recall_note: Label
var _flash: ColorRect
var _tint: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint = _rect(Color(0.1, 0.3, 1.0, 0.0))
	_flash = _rect(Color(1.0, 0.1, 0.05, 0.0))
	_cross = UiKit.label("+", 26)
	_cross.set_anchors_preset(Control.PRESET_CENTER)
	_cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cross.position -= Vector2(8, 18)
	add_child(_cross)
	var box := UiKit.vbox(4)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.position = Vector2(-130, -176)  # bottom centre: the event log owns bottom-left
	add_child(box)
	box.add_child(UiKit.label("SUIT", 11, UiKit.DIM))
	_suit = UiKit.bar(260, 14, UiKit.GOOD)
	box.add_child(_suit)
	_shield_lbl = UiKit.label("SHIELD", 11, UiKit.ENERGY)
	box.add_child(_shield_lbl)
	_shield = UiKit.bar(260, 10, UiKit.ENERGY)
	box.add_child(_shield)
	box.add_child(UiKit.label("SPRAYER TANK", 11, UiKit.DIM))
	_tank = UiKit.bar(260, 10, Color("9ff6ff"))
	box.add_child(_tank)
	_weapon = UiKit.label("", 16)
	box.add_child(_weapon)
	_salvage = UiKit.label("", 14, UiKit.WARN)
	box.add_child(_salvage)
	_charge = UiKit.bar(260, 8, Color("e8fbff"))
	box.add_child(_charge)
	_need = _centered(UiKit.label("", 18, UiKit.WARN), 78)
	_prompt = _centered(UiKit.label("", 20, UiKit.WARN), 60)
	_warn = _centered(UiKit.label("", 22, UiKit.BAD), -140)
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
	add_child(l)
	return l


func refresh(fps: FpsMode) -> void:
	var cap := maxf(1.0, OperativeUpgrades.suit_max())
	var suit := clampf(maxf(0.0, fps.suit) / cap, 0.0, 1.0)
	_suit.value = suit
	UiKit.set_bar_color(_suit, UiKit.BAD if suit < 0.35 else UiKit.GOOD)
	var smax := OperativeUpgrades.shield_max()
	_shield_lbl.visible = smax > 0.0
	_shield.visible = smax > 0.0
	if smax > 0.0:
		_shield.value = clampf(fps.shield / smax, 0.0, 1.0)
	_tank.value = fps.weapons.tank / Config.TANK_MAX
	_weapon.text = fps.weapons.label()
	_salvage.text = fps.weapons.advanced.salvage_line()
	_salvage.visible = _salvage.text != ""
	var ch := fps.weapons.advanced.charge_ratio()
	_charge.visible = ch >= 0.0
	if ch >= 0.0:
		_charge.value = ch
	_need.text = fps.weapons.advanced.hud_need()
	_prompt.text = fps.prompt
	_warn.text = ("IN CREEPER: SUIT BURNING%s" % (" FAST" if fps.creeper_depth > 1.0 else "")) if fps.in_creeper else ""
	_cross.add_theme_color_override("font_color", UiKit.BAD if fps.weapons.hit_marker > 0.0 else UiKit.TEXT)
	var holding := fps.recall_hold > 0.0
	_recall.visible = holding
	_recall.value = fps.recall_hold / Config.RECALL_HOLD
	_recall_note.visible = holding
	_recall_note.text = "Free recall" if fps.recall_cd <= 0.0 else "Teleporter cooldown %ds" % ceili(fps.recall_cd)
	_flash.color.a = 0.3 if fps.hurt_flash > 0.0 else (0.12 if fps.in_creeper else 0.0)
	_tint.color.a = minf(0.45, 0.15 + fps.creeper_depth * 0.15) if fps.in_creeper else 0.0
