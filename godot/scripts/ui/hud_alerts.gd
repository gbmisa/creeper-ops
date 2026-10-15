class_name HudAlerts
extends RefCounted
## Center-screen banner alerts and the command-mode placement-reason line.
## Split out of Hud (keep files under ~250 lines).

var _alert: Label
var _alert_panel: PanelContainer
var _alert_t := 0.0
var _reason: Label
var _reason_panel: PanelContainer


func setup(parent: CanvasLayer) -> void:
	_alert_panel = UiKit.panel(Color(UiKit.BG_SOLID, 0.8))
	_alert_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_alert_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_alert_panel.position.y = 100
	_alert = UiKit.label("", Config.HUD_BANNER_SIZE, UiKit.BAD)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert.add_theme_constant_override("outline_size", 6)
	_alert_panel.add_child(_alert)
	_alert_panel.visible = false
	parent.add_child(_alert_panel)
	_reason_panel = UiKit.panel(Color(UiKit.BG_SOLID, 0.8))
	_reason_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_reason_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reason_panel.position.y = -180
	_reason = UiKit.label("", 16, UiKit.WARN)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.add_theme_color_override("font_outline_color", Color.BLACK)
	_reason.add_theme_constant_override("outline_size", 5)
	_reason_panel.add_child(_reason)
	parent.add_child(_reason_panel)


func alert(text: String, kind := "bad", _secs := 0.0) -> void:
	_alert.text = text
	_alert.add_theme_color_override("font_color", UiKit.KIND_COLORS.get(kind, UiKit.BAD))
	_alert.modulate.a = 1.0
	_alert_panel.visible = true
	_alert_t = Config.HUD_BANNER_LIFE


## Fade the banner; call every frame.
func tick(dt: float) -> void:
	_alert_t -= dt
	_alert_panel.modulate.a = clampf(_alert_t, 0.0, 1.0)
	_alert_panel.visible = _alert_t > 0.0


func set_reason_visible(v: bool) -> void:
	_reason_panel.visible = v


func set_reason(text: String) -> void:
	_reason.text = text
	_reason_panel.visible = text != ""
