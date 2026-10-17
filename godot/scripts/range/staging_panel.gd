class_name StagingPanel
extends CanvasLayer
## F140: the small menu for one mannequin: Save current kit here, Equip this preset, Rename, Close.

var is_open := false
var weapons: PlayerWeapons
var player: TacticalPlayer
var _m: StagingMannequin
var _title: Label
var _status: Label
var _edit: LineEdit
var _root: Control


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var pn := UiKit.panel()
	pn.position = Vector2(680, 330)
	pn.custom_minimum_size = Vector2(260, 0)
	_root.add_child(pn)
	UiKit.brackets(pn)
	var col := VBoxContainer.new()
	pn.add_child(col)
	_title = UiKit.label("", 20)
	col.add_child(_title)
	col.add_child(UiKit.button("Save current kit here", func(): _do_save()))
	col.add_child(UiKit.button("Equip this preset", func(): _do_equip()))
	_edit = LineEdit.new()
	_edit.max_length = 20
	_edit.placeholder_text = "Preset name"
	_edit.text_submitted.connect(func(_t): _do_rename())
	col.add_child(_edit)
	col.add_child(UiKit.button("Rename", func(): _do_rename()))
	_status = UiKit.label("", 14)
	col.add_child(_status)
	col.add_child(UiKit.button("Close", func(): close()))
	visible = false


func open(m: StagingMannequin) -> void:
	_m = m
	is_open = true
	visible = true
	weapons.ui_open = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh("")


func close() -> void:
	is_open = false
	visible = false
	_edit.release_focus()
	weapons.ui_open = false
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh(msg: String) -> void:
	_title.text = "MANNEQUIN %d: %s" % [_m.index + 1, _m.preset_name]
	_edit.text = _m.preset_name
	_status.text = msg


func _do_save() -> void:
	_m.save_from(weapons.inv)
	_refresh("Kit saved")


func _do_equip() -> void:
	_refresh("Preset equipped" if _m.equip(weapons) else "Nothing saved here yet")


func _do_rename() -> void:
	_m.rename(_edit.text)
	_refresh("Renamed")
