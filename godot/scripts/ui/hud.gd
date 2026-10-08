class_name Hud
extends CanvasLayer
## Root of the HUD. Composes the top bar, build menu, info panel, objectives, markers,
## Operative HUD, event log, centre alerts, placement reason, drag-select box, help line and
## modal overlays. Game calls refresh() every rendered frame.

const MAX_LOG := 9

var top: TopBar
var build: BuildMenu
var info: InfoPanel
var objectives: Objectives
var markers: Markers
var fps: FpsHud
var keys: KeybindMenu
var _log: VBoxContainer
var _alert: Label
var _alert_t := 0.0
var _reason: Label
var _selbox: Panel
var _help: Label
var _overlay: Control
var _overlay_box: VBoxContainer
var _mode := ""


func setup(cm: CommandMode, um: UnitManager) -> void:
	markers = Markers.new()
	add_child(markers)
	fps = FpsHud.new()
	add_child(fps)
	top = TopBar.new()
	add_child(top)
	objectives = Objectives.new(cm.level.get("objectives", Objectives.LIST))
	add_child(objectives)
	build = BuildMenu.new()
	add_child(build)
	info = InfoPanel.new()
	info.setup(cm, um)
	add_child(info)
	_log = UiKit.vbox(2)
	_log.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_log.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_log.position = Vector2(12, -12)
	add_child(_log)
	_alert = UiKit.label("", 30, UiKit.BAD)
	_alert.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_alert.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.position.y = 110
	_alert.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert.add_theme_constant_override("outline_size", 6)
	add_child(_alert)
	_reason = UiKit.label("", 16, UiKit.WARN)
	_reason.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_reason.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.position.y = -190
	_reason.add_theme_color_override("font_outline_color", Color.BLACK)
	_reason.add_theme_constant_override("outline_size", 5)
	add_child(_reason)
	_selbox = Panel.new()
	_selbox.add_theme_stylebox_override("panel", UiKit.style(Color(0.6, 1.0, 0.5, 0.12), Color(0.6, 1.0, 0.5, 0.8), 0, 0))
	_selbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selbox)
	_help = UiKit.label("", 12, UiKit.DIM)
	_help.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_help.position = Vector2(-12, -12)
	add_child(_help)
	_build_overlay()
	keys = KeybindMenu.new()
	keys.on_close = func():
		build.show_tab(build.tab)
		build.relabel()
		set_mode(_mode)
	add_child(keys)
	add_child(ArmouryMenu.new())
	Bus.log_msg.connect(add_log)
	set_mode("command")


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(c)
	var p := UiKit.panel(Color(0.05, 0.07, 0.1, 0.96))
	c.add_child(p)
	_overlay_box = UiKit.vbox(10)
	_overlay_box.custom_minimum_size.x = 620
	_overlay_box.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(_overlay_box)
	_overlay.visible = false


func add_log(text: String, kind: String) -> void:
	var top_l: Label = _log.get_child(_log.get_child_count() - 1) if _log.get_child_count() > 0 else null
	if top_l and top_l.get_meta("text") == text:  # collapse repeats into "xN"
		var n: int = top_l.get_meta("count") + 1
		top_l.set_meta("count", n)
		top_l.text = "%s  x%d" % [text, n]
		return
	var l := UiKit.label(text, 14, UiKit.KIND_COLORS.get(kind, UiKit.TEXT))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 400  # stays clear of the centred build menu
	l.set_meta("text", text)
	l.set_meta("count", 1)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	_log.add_child(l)
	while _log.get_child_count() > MAX_LOG:
		var old := _log.get_child(0)
		_log.remove_child(old)
		old.queue_free()


func alert(text: String, kind := "bad", secs := 3.0) -> void:
	_alert.text = text
	_alert.add_theme_color_override("font_color", UiKit.KIND_COLORS.get(kind, UiKit.BAD))
	_alert_t = secs


func set_mode(mode: String) -> void:
	_mode = mode
	var cmd := mode == "command"
	fps.visible = not cmd
	build.visible = cmd
	info.visible = false
	_reason.visible = cmd
	var k := Keybinds.short
	_help.text = ("%s%s%s%s/edge pan · %s/%s rotate · wheel zoom · right-click move/order · %s move · %s recycle · %s Operative · %s pause · %s/%s speed · %s controls" % [
		k.call("cam_forward"), k.call("cam_left"), k.call("cam_back"), k.call("cam_right"), k.call("cam_rot_left"), k.call("cam_rot_right"),
		k.call("move"), k.call("recycle"), k.call("teleport"), k.call("pause"), k.call("speed_up"), k.call("speed_down"), k.call("keybinds")]
		if cmd else "%s%s%s%s move · %s sprint · %s jump · %s/%s/%s rifle/sprayer/rockets · %s/%s/%s rail/plasma/charge · %s use · %s build · hold %s recall (free at a Totem) · Esc pause" % [
		k.call("op_forward"), k.call("op_left"), k.call("op_back"), k.call("op_right"), k.call("sprint"), k.call("jump"),
		k.call("rifle"), k.call("sprayer"), k.call("rocket"), k.call("adv_railgun"), k.call("adv_plasma"), k.call("adv_demo"),
		k.call("use"), k.call("op_build"), k.call("recall")])


## Modal overlay: html-free rich text + buttons [{ label, on_click }].
func show_overlay(bbcode: String, buttons: Array) -> void:
	for c in _overlay_box.get_children():
		c.queue_free()
	var t := UiKit.rich(16)
	t.text = bbcode
	_overlay_box.add_child(t)
	var row := UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_overlay_box.add_child(row)
	for b in buttons:
		row.add_child(UiKit.button(b.label, b.on_click, 18))
	_overlay.visible = true


func hide_overlay() -> void:
	_overlay.visible = false


func overlay_open() -> bool:
	return _overlay.visible or keys.visible


func refresh(g, dt: float) -> void:
	top.refresh(g)
	_alert_t -= dt
	_alert.modulate.a = clampf(_alert_t, 0.0, 1.0)
	var world: World = g.cave if g.mode == "cave" else g.surface
	var cam: Camera3D = g.command.cam if g.mode == "command" else g.fps.camera
	markers.refresh(world, cam, g.mode != "command")
	if g.mode == "command":
		_reason.text = g.command.reason
		build.level = g.level
		build.refresh(g.economy.energy)
		info.refresh()
		var r: Rect2 = g.command.drag_rect
		_selbox.visible = r.size.length() > 1.0
		_selbox.position = r.position
		_selbox.size = r.size
	else:
		_selbox.visible = false
		fps.refresh(g.fps)
	if ArmouryMenu.is_open():
		ArmouryMenu.current.refresh()
