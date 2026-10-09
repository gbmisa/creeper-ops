class_name Hud
extends CanvasLayer
## Root of the HUD. Composes the top bar, build menu, info panel, objectives, markers,
## Operative HUD, event log, centre alerts, placement reason, drag-select box, help line and
## modal overlays. Game calls refresh() every rendered frame.

var top: TopBar
var build: BuildMenu
var info: InfoPanel
var objectives: Objectives
var markers: Markers
var fps: FpsHud
var keys: KeybindMenu
var _log: VBoxContainer
var alerts: HudAlerts
var _selbox: Panel
var _help: Label
var _overlay: HudOverlay
var _mode := ""
const LOG_LIFT := 178.0


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
	_log.anchor_top = 1.0
	_log.anchor_bottom = 1.0
	_log.alignment = BoxContainer.ALIGNMENT_END
	_log.offset_left = 12
	_log.offset_right = 452
	_lift_log(LOG_LIFT)
	add_child(_log)
	alerts = HudAlerts.new()
	alerts.setup(self)
	_selbox = Panel.new()
	_selbox.add_theme_stylebox_override("panel", UiKit.style(Color(UiKit.ACCENT, 0.1), Color(UiKit.ACCENT, 0.85), 0, 0))
	_selbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selbox)
	_help = UiKit.label("", 13, UiKit.DIM)
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
	var th := UiTheme.build()
	for c in get_children():  # a CanvasLayer stops theme propagation from the Window
		if c is Control:
			(c as Control).theme = th
	build.show_tab(build.tab)  # rebuild the cards now that the theme fonts are in
	set_mode("command")


func _build_overlay() -> void:
	_overlay = HudOverlay.new()
	add_child(_overlay)


func add_log(text: String, kind: String) -> void:
	var life := _log_life(kind)
	var top_l: Label = _log.get_child(_log.get_child_count() - 1) if _log.get_child_count() > 0 else null
	if top_l and top_l.get_meta("text") == text:  # collapse repeats into "xN"
		var n: int = top_l.get_meta("count") + 1
		top_l.set_meta("count", n)
		top_l.set_meta("age", 0.0)
		top_l.set_meta("life", life)
		top_l.text = "%s  x%d" % [text, n]
		top_l.modulate.a = 1.0
		return
	var l := UiKit.label(text, 16, UiKit.KIND_COLORS.get(kind, UiKit.TEXT))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var w := UiTheme.font().get_string_size(text + "  x99", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16.0
	l.custom_minimum_size.x = minf(w, 430.0)  # plate hugs short lines; long ones wrap
	l.set_meta("text", text)
	l.set_meta("count", 1)
	l.set_meta("age", 0.0)
	l.set_meta("life", life)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 2)
	var plate := UiTheme.box(Color(0.03, 0.035, 0.025, 0.55), UiKit.KIND_COLORS.get(kind, UiKit.TEXT), 0, 0)
	plate.border_width_left = 3
	plate.content_margin_left = 7
	plate.content_margin_right = 6
	l.add_theme_stylebox_override("normal", plate)
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_log.add_child(l)
	_trim_log()


## The log sits above the build menu in command mode so wide card rows never cover it.
func _lift_log(lift: float) -> void:
	_log.offset_bottom = -lift
	_log.offset_top = -lift - 300.0


func _log_life(kind: String) -> float:
	return Config.HUD_LOG_LIFE * (2.0 if kind == "warn" or kind == "bad" else 1.0)


func _trim_log() -> void:
	while _log.get_child_count() > Config.HUD_LOG_LINES:
		var old := _log.get_child(0)
		_log.remove_child(old)
		old.queue_free()


func _tick_log(dt: float) -> void:
	var gone: Array[Node] = []
	for c in _log.get_children():
		var age: float = float(c.get_meta("age")) + dt
		var life: float = float(c.get_meta("life"))
		c.set_meta("age", age)
		var left := life - age
		if left <= 0.0:
			gone.append(c)
		else:
			(c as CanvasItem).modulate.a = clampf(left, 0.0, 1.0)
	for c in gone:
		_log.remove_child(c)
		c.queue_free()


func log_count() -> int:
	return _log.get_child_count()


func log_has(text: String) -> bool:
	return log_line(text) != ""


func log_line(text: String) -> String:
	for c in _log.get_children():
		if str(c.get_meta("text")) == text:
			return (c as Label).text
	return ""


func alert(text: String, kind := "bad", _secs := 0.0) -> void:
	alerts.alert(text, kind, _secs)


func set_mode(mode: String) -> void:
	_mode = mode
	var cmd := mode == "command"
	fps.visible = not cmd
	build.visible = cmd
	info.visible = false
	alerts.set_reason_visible(cmd)
	_lift_log(LOG_LIFT if cmd else 12.0)
	_help.offset_bottom = -(LOG_LIFT if cmd else 12.0)
	_help.offset_top = _help.offset_bottom - 24.0
	var k := Keybinds.short
	_help.text = ("%s%s%s%s/edge pan · %s/%s rotate · wheel zoom · right-click move/order · %s move · %s recycle · %s Operative · %s pause · %s/%s speed · %s controls" % [
		k.call("cam_forward"), k.call("cam_left"), k.call("cam_back"), k.call("cam_right"), k.call("cam_rot_left"), k.call("cam_rot_right"),
		k.call("move"), k.call("recycle"), k.call("teleport"), k.call("pause"), k.call("speed_up"), k.call("speed_down"), k.call("keybinds")]
		if cmd else "%s%s%s%s move · %s sprint · %s jump · %s/%s/%s/%s pulse/sprayer/rockets/crossbow · %s/%s/%s rail/plasma/charge · %s use · %s build · hold %s recall (free at a Totem) · Esc pause" % [
		k.call("op_forward"), k.call("op_left"), k.call("op_back"), k.call("op_right"), k.call("sprint"), k.call("jump"),
		k.call("rifle"), k.call("sprayer"), k.call("rocket"), k.call("crossbow"), k.call("adv_railgun"), k.call("adv_plasma"), k.call("adv_demo"),
		k.call("use"), k.call("op_build"), k.call("recall")])


## Modal overlay: BBCode text + buttons [{ label, on_click }]; the first is the primary action.
func show_overlay(bbcode: String, buttons: Array) -> void:
	_overlay.open(bbcode, buttons)


func hide_overlay() -> void:
	_overlay.visible = false


func overlay_open() -> bool:
	return _overlay.visible or keys.visible


func refresh(g, dt: float) -> void:
	top.refresh(g)
	objectives.refresh(dt, g.input, g.mode != "command")
	_tick_log(dt)
	_help.visible = g.time < Config.HUD_HINT_SECS
	alerts.tick(dt)
	var world: World = g.cave if g.mode == "cave" else g.surface
	var cam: Camera3D = g.command.cam if g.mode == "command" else g.fps.camera
	markers.refresh(world, cam, g.mode != "command")
	if g.mode == "command":
		alerts.set_reason(g.command.reason)
		build.level = g.level
		build.refresh(g.economy.energy)
		info.refresh()
		var r: Rect2 = g.command.drag_rect
		_selbox.visible = r.size.length() > 1.0
		_selbox.position = r.position
		_selbox.size = r.size
	else:
		_selbox.visible = false
		fps.refresh(g.fps, g.fps.world == g.surface and EnemyMortarFire.any_spotted(g.hazards.nests))
	if ArmouryMenu.is_open():
		ArmouryMenu.current.refresh()
