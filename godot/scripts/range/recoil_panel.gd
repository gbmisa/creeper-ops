class_name RecoilPanel
extends CanvasLayer
## Live Tarkov recoil tuning (F56, range map only), toggled with `t_recoil_panel` (F7). Sliders for the gun in
## hand's TacRecoilDefs row and the global stance factors; every change goes into TacRecoilDefs.overrides /
## POSE at once and the next shot uses it. "Print row" writes the row to the log in GDScript form. While it is
## open the mouse is free and the player can't move or fire; close it (F7) to shoot.

## [row key (".x"/".y" = a Vector2 part), min, max, step]
const SLIDERS := [
	["force_up", 0.0, 600.0, 1.0], ["force_back", 0.0, 1500.0, 5.0], ["angle", 45.0, 135.0, 0.5],
	["dispersion", 0.0, 40.0, 0.5], ["camera", 0.0, 0.3, 0.005], ["convergence", 0.2, 10.0, 0.05],
	["damping", 0.5, 0.99, 0.005], ["category_mult", 0.05, 0.6, 0.005], ["stable_shot", 1.0, 15.0, 1.0],
	["stable_step", 0.0, 10.0, 0.1], ["stable_angle.y", 0.0, 60.0, 0.5],
	["post_v.x", -5.0, 0.0, 0.05], ["post_v.y", -3.0, 3.0, 0.05], ["post_h.x", -5.0, 0.0, 0.05], ["post_h.y", 0.0, 5.0, 0.05],
	["return_offset", 0.0, 0.1, 0.001], ["return_damping", 0.1, 0.95, 0.01],
	["hip_gain", 0.0, 1.0, 0.01], ["hip_delay", 0.0, 1.0, 0.01], ["hip_speed", 0.5, 20.0, 0.1],
	["cam_to_weapon.x", 0.0, 1.0, 0.01], ["cam_to_weapon.y", 0.0, 1.0, 0.01],
]
const POSE_NAMES := ["prone", "crouched", "standing"]

var weapons: PlayerWeapons
var player: TacticalPlayer
var input: InputState
var _list: VBoxContainer
var _title: Label
var _id := ""


func setup(w: PlayerWeapons, p: TacticalPlayer, i: InputState) -> void:
	weapons = w
	player = p
	input = i
	layer = 9
	visible = false
	var box := UiKit.panel(Color(0.05, 0.06, 0.08, 0.92))
	box.position = Vector2(20, 60)
	box.custom_minimum_size = Vector2(430, 780)
	add_child(box)
	var col := VBoxContainer.new()
	box.add_child(col)
	_title = UiKit.label("Recoil", 18)
	col.add_child(_title)
	var row := HBoxContainer.new()
	col.add_child(row)
	row.add_child(UiKit.button("Print row", print_row, 13))
	row.add_child(UiKit.button("Reset gun", _reset, 13))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 700)
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	w.switched.connect(func(_g): if visible: _build())


func _process(_dt: float) -> void:
	if input != null and input.frame.act("t_recoil_panel"):
		toggle()


func toggle() -> void:
	visible = not visible
	player.enabled = not visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	if visible:
		_build()


func _build() -> void:
	for c in _list.get_children():
		c.queue_free()
	_id = weapons.gun.id if weapons.gun != null else "ak47"
	_title.text = "Recoil: %s (%s)" % [WeaponDefs.of(_id)["name"], Keybinds.short("t_recoil_panel")]
	var r := TacRecoilDefs.row(_id)
	for s in SLIDERS:
		_slider(s[0], _row_value(r, s[0]), s[1], s[2], s[3], func(v): _set_row(s[0], v))
	_list.add_child(UiKit.label("Stance factors (all guns) [x up, y side, z back]", 14))
	for p in 2:   # prone, crouched; standing is the 1.0 reference
		for ax in 3:
			var key := "%s.%s" % [POSE_NAMES[p], "xyz"[ax]]
			_slider(key, (TacRecoilDefs.POSE[p] as Vector3)[ax], 0.1, 1.5, 0.01, func(v): _set_pose(p, ax, v))


func _slider(name: String, value: float, lo: float, hi: float, step: float, on_change: Callable) -> void:
	var line := HBoxContainer.new()
	_list.add_child(line)
	var lab := UiKit.label(name, 13)
	lab.custom_minimum_size = Vector2(130, 0)
	line.add_child(lab)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = value
	sl.custom_minimum_size = Vector2(200, 20)
	line.add_child(sl)
	var val := UiKit.label(_fmt(value), 13)
	line.add_child(val)
	sl.value_changed.connect(func(v):
		val.text = _fmt(v)
		on_change.call(v))


static func _fmt(v: float) -> String:
	return ("%.3f" % v).rstrip("0").rstrip(".") if v != 0.0 else "0"


static func _row_value(r: Dictionary, key: String) -> float:
	var parts := key.split(".")
	if parts.size() == 1:
		return float(r[key])
	return float((r[parts[0]] as Vector2)[0 if parts[1] == "x" else 1])


func _set_row(key: String, v: float) -> void:
	var o: Dictionary = TacRecoilDefs.overrides.get(_id, {})
	var parts := key.split(".")
	if parts.size() == 1:
		o[key] = int(v) if key == "stable_shot" else v
	else:
		var cur: Vector2 = o.get(parts[0], TacRecoilDefs.row(_id)[parts[0]])
		cur[0 if parts[1] == "x" else 1] = v
		o[parts[0]] = cur
	TacRecoilDefs.overrides[_id] = o


static func _set_pose(p: int, ax: int, v: float) -> void:
	var f: Vector3 = TacRecoilDefs.POSE[p]
	f[ax] = v
	TacRecoilDefs.POSE[p] = f


func _reset() -> void:
	TacRecoilDefs.overrides.erase(_id)
	_build()


## The gun's row and the stance factors as GDScript, for pasting into TacRecoilDefs.
func print_row() -> void:
	var r := TacRecoilDefs.row(_id)
	var keys := []
	for s in SLIDERS:
		var k: String = s[0].split(".")[0]
		if not keys.has(k):
			keys.append(k)
	var parts := []
	for k in keys:
		parts.append('"%s": %s' % [k, var_to_str(r[k])])
	print('[recoil] "%s": {%s},' % [_id, ", ".join(parts)])
	print("[recoil] static var POSE := %s" % var_to_str(TacRecoilDefs.POSE))
