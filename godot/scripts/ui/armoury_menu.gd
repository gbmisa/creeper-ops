class_name ArmouryMenu
extends Control
## Salvage shop. The Command Node panel and the first-person overlay share add_rows().
## A held castle opens the same overlay later with ArmouryMenu.open(fps, stockpile).

const REACH := 4.0  # metres: first-person "[E] Armoury" at the Command Node

static var current: ArmouryMenu
static var suppress_use := false

var stockpile: Stockpile
var _fps: FpsMode
var _host = null  # Game, for ignore_capture
var _open := false
var _rows: VBoxContainer
var _salvage: Label


func _init() -> void:
	current = self
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(UiKit.BG_SOLID)
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var box := UiKit.vbox(8)
	panel.add_child(box)
	UiKit.brackets(panel, UiKit.ACCENT, 14.0)
	box.add_child(UiKit.header("Armoury", 22))
	_salvage = UiKit.label("", 16, UiKit.WARN)
	box.add_child(_salvage)
	_rows = UiKit.vbox(4)
	box.add_child(_rows)
	var hint := UiKit.label("Esc or E closes", 13, UiKit.DIM)
	box.add_child(hint)


static func bind(host) -> void:
	if current:
		current._host = host


static func is_open() -> bool:
	return current != null and current._open


static func open(fps: FpsMode, pile: Stockpile) -> void:
	if current == null:
		return
	current._fps = fps
	current.stockpile = pile
	current._open = true
	current.visible = true
	current._rebuild()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func close_menu() -> void:
	if not is_open():
		return
	var fps := current._fps
	current._open = false
	current.visible = false
	var capture: bool = current._host == null or not current._host.ignore_capture
	if capture and fps != null and fps.world != null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func take_suppress() -> bool:
	var was := suppress_use
	suppress_use = false
	return was


static func add_rows(parent: Container, pile: Stockpile, done: Callable, fps: FpsMode = null) -> void:
	for id in OperativeUpgrades.ORDER:
		var pick: String = id
		var b := UiKit.button(OperativeUpgrades.button_text(pick), func():
			_purchase(pick, pile, fps)
			done.call())
		b.tooltip_text = OperativeUpgrades.DEFS[pick].desc
		parent.add_child(b)
	var cb := UiKit.button(OperativeUpgrades.charge_text(), func():
		var why := OperativeUpgrades.buy_charge(pile)
		Sfx.play("deny" if why != "" else "good")
		Bus.say(why if why != "" else "Armoury: %s." % OperativeUpgrades.charge_text(), "warn" if why != "" else "good")
		done.call())
	cb.tooltip_text = "Plant on a big enemy structure or the crown nest (hold %s) for an instant kill. Fuse %d s. Carry up to %d." % [Keybinds.short("use"), int(Config.DEMO_FUSE), Config.DEMO_CHARGE_MAX]
	parent.add_child(cb)


static func _purchase(id: String, pile: Stockpile, fps: FpsMode) -> void:
	var why := OperativeUpgrades.buy(id, pile)
	if why != "":
		Sfx.play("deny")
		Bus.say(why, "warn")
		return
	if id == "armour" and fps != null:
		fps.shield = OperativeUpgrades.shield_max()
	Sfx.play("good")
	Bus.say("Armoury: %s." % OperativeUpgrades.button_text(id), "good")


func refresh() -> void:
	if not _open or stockpile == null:
		return
	_salvage.text = "Salvage %s" % String.num(stockpile.salvage, 1)


func _rebuild() -> void:
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	if stockpile == null:
		return
	add_rows(_rows, stockpile, _rebuild, _fps)
	refresh()
