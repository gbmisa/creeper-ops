class_name BuildMenu
extends PanelContainer
## CW3-style build panel: one tab per StructureDefs.TABS (Structures, Weapons, Titans, Orbital, Castle).
## Tab keys (F1..) or Tab switch screens; 1-9 pick an item on the current screen (all rebindable).
## Hovering an item shows its full description and numbers on the line under the cards.

var on_pick := Callable()   # func(item: String) — structure type or "@action"
var level: Dictionary = {}  # live level dict; Hud assigns it before refresh
var tab := 0
var _tab_buttons: Array[Button] = []
var _items: HBoxContainer
var _buttons := {}          # item -> BuildCard
var _tip: Label
var _active_tool := ""


func _init() -> void:
	add_theme_stylebox_override("panel", UiKit.style(UiKit.BG, UiKit.EDGE, 1, 8))
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -10
	UiKit.brackets(self)
	var v := UiKit.vbox(6)
	add_child(v)
	var tabs := UiKit.hbox(2)
	v.add_child(tabs)
	for i in StructureDefs.TABS.size():
		var b := UiKit.button("", func(): show_tab(i), 15)
		b.toggle_mode = true
		tabs.add_child(b)
		_tab_buttons.append(b)
	relabel()
	_items = UiKit.hbox(6)
	v.add_child(_items)
	_tip = UiKit.label("", 14, UiKit.DIM)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(640, 36)
	v.add_child(_tip)
	Bus.tool_changed.connect(_on_tool)
	show_tab(0)


func _on_tool(t: String) -> void:
	_active_tool = t
	_highlight()


func show_tab(i: int) -> void:
	tab = i
	for k in _tab_buttons.size():
		_tab_buttons[k].button_pressed = k == i
	for c in _items.get_children():
		c.queue_free()
	_buttons.clear()
	var list: Array = StructureDefs.MENU[StructureDefs.TABS[i]]
	for n in list.size():
		var item: String = list[n]
		var b := BuildCard.new(item, n)
		b.pressed.connect(func(): _pick(item))
		b.mouse_entered.connect(func():
			var why := StructureDefs.lock_reason(level, item)
			_tip.text = why if why != "" else "%s: %s" % [StructureDefs.label(item), StructureDefs.desc(item)])
		b.mouse_exited.connect(func(): _tip.text = "")
		_items.add_child(b)
		_buttons[item] = b
		_fill(b)
	_highlight()


func _pick(item: String) -> void:
	var locked := StructureDefs.lock_reason(level, item)
	if locked != "":
		Sfx.play("deny")
		Bus.say(locked, "warn")
		return
	Sfx.play("click")
	if on_pick.is_valid():
		on_pick.call(item)
	_highlight()


func _highlight() -> void:
	for item in _buttons:
		(_buttons[item] as Button).set_pressed_no_signal(item == _active_tool)


## Tab captions follow the current keybinds.
func relabel() -> void:
	for i in _tab_buttons.size():
		_tab_buttons[i].text = "%s  %s" % [Keybinds.short("tab_%d" % (i + 1)), StructureDefs.TABS[i].to_upper()]


## Hotkeys (called by Hud while in command mode). Returns true if consumed.
func handle_key(key: int) -> bool:
	for i in StructureDefs.TABS.size():
		if Keybinds.matches("tab_%d" % (i + 1), key):
			show_tab(i)
			return true
	if Keybinds.matches("tab_next", key):
		show_tab((tab + 1) % StructureDefs.TABS.size())
		return true
	var list: Array = StructureDefs.MENU[StructureDefs.TABS[tab]]
	for n in mini(list.size(), 9):
		if Keybinds.matches("build_%d" % (n + 1), key):
			_pick(list[n])
			return true
	return false


func _fill(b: BuildCard) -> void:
	var n := int(b.get_meta("slot", 0))
	var key := Keybinds.short("build_%d" % (n + 1)) if n < 9 else ""
	var locked := StructureDefs.lock_reason(level, b.item)
	b.show_info(key, StructureDefs.label(b.item), StructureDefs.cost_text(b.item), locked, locked != "")


## Grey out a locked item, and anything that has to be paid up front (drop pods / lance).
func refresh(energy: float) -> void:
	for item in _buttons:
		var b: BuildCard = _buttons[item]
		_fill(b)
		if b.disabled:
			b.modulate = Color(1, 1, 1, 0.55)
			continue
		var up_front := 0.0
		if item == "@lance":
			up_front = Config.LANCE_COST
		elif item == "@drop":
			up_front = Config.DROP_BASE
		elif not str(item).begins_with("@") and StructureDefs.DEFS[item].get("drop_pod", false):
			up_front = StructureDefs.DEFS[item].cost
		b.modulate = Color(1, 1, 1, 0.5) if energy < up_front else Color.WHITE
