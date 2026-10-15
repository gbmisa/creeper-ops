class_name InventoryUI
extends CanvasLayer
## Full-screen Tarkov-style inventory for the range. Tab toggles it.
## Equipment left, pockets / rig / backpack middle, nearby ground items right.
## Drag/drop between slots and grids, R rotates while dragging, drop outside the
## panel drops to the ground, Ctrl+click quick-moves, hover shows a tooltip.

const CELL := 40

const KIND_COLORS := {
	"gun": Color(0.42, 0.30, 0.28),
	"mag": Color(0.38, 0.40, 0.22),
	"ammo": Color(0.48, 0.34, 0.16),
	"armor": Color(0.25, 0.32, 0.45),
	"rig": Color(0.24, 0.38, 0.26),
	"backpack": Color(0.40, 0.30, 0.18),
	"med": Color(0.55, 0.30, 0.30),
}

var player: TacticalPlayer
var weapons: PlayerWeapons
var world_items: Array = []
var is_open := false

var _dim: ColorRect
var _center: CenterContainer
var _panel: PanelContainer
var _weight: Label
var _slot_views := {}
var _grid_views := {}
var _near_list: VBoxContainer
var _tip: PanelContainer
var _tip_lbl: Label
var _drag := {}
var _near_t := 0.0


func _ready() -> void:
	layer = 10
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.62)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(_center)
	var panel := PanelContainer.new()
	_panel = panel
	panel.add_theme_stylebox_override("panel", _box(Color(0.09, 0.09, 0.11, 0.98), 2))
	_center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := HBoxContainer.new()
	vb.add_child(title)
	var h := Label.new()
	h.text = "INVENTORY"
	h.add_theme_font_size_override("font_size", 22)
	title.add_child(h)
	var hints := Label.new()
	hints.text = "  drag to move · R rotate · Ctrl+click quick move · drop outside = drop · Tab close"
	hints.add_theme_font_size_override("font_size", 13)
	hints.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title.add_child(hints)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	vb.add_child(cols)
	var left := VBoxContainer.new()
	left.add_child(_head("EQUIPMENT"))
	cols.add_child(left)
	for s in Inventory.SLOT_NAMES:
		left.add_child(_slot_view(s))
	var mid := VBoxContainer.new()
	mid.add_child(_head("CARRY"))
	cols.add_child(mid)
	var right := VBoxContainer.new()
	right.add_child(_head("NEARBY (2 m)"))
	cols.add_child(right)
	_near_list = VBoxContainer.new()
	right.add_child(_near_list)
	_mid_holder = mid
	_weight = Label.new()
	_weight.add_theme_font_size_override("font_size", 16)
	vb.add_child(_weight)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", _box(Color(0.05, 0.05, 0.07, 0.97), 1))
	_tip.visible = false
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(_tip)
	_tip_lbl = Label.new()
	_tip_lbl.add_theme_font_size_override("font_size", 14)
	_tip.add_child(_tip_lbl)


var _mid_holder: VBoxContainer


func setup(p: TacticalPlayer, w: PlayerWeapons) -> void:
	player = p
	weapons = w


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	_dim.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	weapons.ui_open = true
	refresh()


func close() -> void:
	is_open = false
	_end_drag()
	_tip.visible = false
	_dim.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapons.ui_open = false


func _process(delta: float) -> void:
	if not is_open:
		return
	if not _drag.is_empty():
		var g: Control = _drag["ghost"]
		g.position = _dim.get_global_mouse_position() - g.size * 0.5
	_near_t -= delta
	if _near_t <= 0.0:
		_near_t = 0.5
		_refresh_nearby()


func _input(event: InputEvent) -> void:
	if not is_open or _drag.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_drag["rot"] = 1 - int(_drag["rot"])
		_size_ghost()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if not is_open:
		return
	var inv: Inventory = weapons.inv
	for s in _slot_views:
		_clear(_slot_views[s])
		var eq: Dictionary = inv.equipped(s)
		if not eq.is_empty():
			_slot_views[s].add_child(_item_panel(eq))
	for g in _grid_views:
		(_grid_views[g] as Control).queue_free()
	_grid_views.clear()
	for g in ["pockets", "rig_grid", "pack_grid"]:
		if not inv.grid_dim.has(g):
			continue
		var dd: Vector2i = inv.grid_dim[g]
		var gv := _grid_view(g, dd)
		_mid_holder.add_child(gv)
		_grid_views[g] = gv
		for uid in inv.items:
			var l: Dictionary = inv.loc.get(uid, {})
			if (l as Dictionary).get("c", "") == g:
				var p := _item_panel(inv.items[uid])
				p.position = Vector2((l as Dictionary)["x"], (l as Dictionary)["y"]) * CELL
				gv.add_child(p)
	_weight.text = "Weight: %.1f kg" % inv.total_kg()
	_refresh_nearby()


# ---------- construction ----------

func _box(c: Color, border: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = Color(0.55, 0.55, 0.6)
	s.set_border_width_all(border)
	s.set_corner_radius_all(4)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _head(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.6))
	return l


func _slot_view(slot: String) -> VBoxContainer:
	var vb := VBoxContainer.new()
	var l := Label.new()
	l.text = slot.capitalize()
	l.add_theme_font_size_override("font_size", 13)
	vb.add_child(l)
	var dims := {"primary": Vector2i(4, 2), "secondary": Vector2i(4, 2), "holster": Vector2i(2, 1),
		"armor": Vector2i(3, 2), "rig": Vector2i(4, 2), "backpack": Vector2i(5, 3)}[slot] as Vector2i
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(dims) * CELL
	p.add_theme_stylebox_override("panel", _box(Color(0.13, 0.13, 0.15, 1), 1))
	p.set_meta("slot", slot)
	_slot_views[slot] = p
	vb.add_child(p)
	return vb


func _grid_view(grid: String, dd: Vector2i) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.set_meta("is_grid", true)
	var l := Label.new()
	l.text = {"pockets": "Pockets", "rig_grid": "Rig", "pack_grid": "Backpack"}[grid]
	l.add_theme_font_size_override("font_size", 13)
	vb.add_child(l)
	var c := Control.new()
	c.custom_minimum_size = Vector2(dd) * CELL
	c.set_meta("grid", grid)
	c.set_meta("dim", dd)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# grid background cells
	for yy in dd.y:
		for xx in dd.x:
			var cell := ColorRect.new()
			cell.color = Color(0.16, 0.16, 0.18)
			cell.position = Vector2(xx, yy) * CELL
			cell.size = Vector2(CELL - 1, CELL - 1)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(cell)
	vb.add_child(c)
	return vb


func _clear(c: Control) -> void:
	for ch in c.get_children():
		ch.queue_free()


func _item_panel(item: Dictionary) -> PanelContainer:
	var idef := ItemDefs.of(item["id"])
	var rot := int(item.get("rot", 0))
	var w: int = idef["w"] if rot == 0 else idef["h"]
	var h: int = idef["h"] if rot == 0 else idef["w"]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, h) * CELL
	p.size = p.custom_minimum_size
	p.add_theme_stylebox_override("panel", _box(KIND_COLORS.get(idef["kind"], Color(0.3, 0.3, 0.3)), 1))
	var l := Label.new()
	l.text = _item_text(item, idef)
	l.add_theme_font_size_override("font_size", 12)
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.set_meta("uid", item["uid"])
	p.gui_input.connect(_on_item_input.bind(p, item["uid"]))
	p.mouse_entered.connect(_on_item_hover.bind(item))
	p.mouse_exited.connect(func(): _tip.visible = false)
	return p


func _item_text(item: Dictionary, idef: Dictionary) -> String:
	var extra := ""
	if idef["kind"] == "mag":
		extra = " %d" % int(item.get("rounds", 0))
	elif idef["kind"] == "ammo":
		extra = " x%d" % int(item.get("count", 0))
	return idef["name"] + extra


func _tooltip_text(item: Dictionary) -> String:
	var idef := ItemDefs.of(item["id"])
	var lines := [idef["name"], "Kind: %s" % idef["kind"], "Size: %dx%d" % [idef["w"], idef["h"]], "Weight: %.2f kg" % idef["kg"]]
	if idef["kind"] == "mag":
		lines.append("Rounds: %d / %d" % [int(item.get("rounds", 0)), idef["cap"]])
	elif idef["kind"] == "ammo":
		lines.append("Count: %d" % int(item.get("count", 0)))
	elif idef["kind"] == "gun":
		lines.append("Caliber: %s" % WeaponDefs.of(idef["weapon"])["cal"])
	return "\n".join(lines)


# ---------- item input ----------

func _on_item_input(event: InputEvent, panel: PanelContainer, uid: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_key_pressed(KEY_CTRL):
			if weapons.inv.quick_move(uid):
				weapons.sync_weight()
				refresh()
		else:
			_begin_drag(uid, panel)


func _on_item_hover(item: Dictionary) -> void:
	_tip_lbl.text = _tooltip_text(item)
	_tip.visible = true
	_tip.position = _dim.get_global_mouse_position() + Vector2(16, 12)


func _begin_drag(uid: int, panel: PanelContainer) -> void:
	_end_drag()
	var item: Dictionary = weapons.inv.items[uid]
	_drag = {"uid": uid, "rot": int(item.get("rot", 0))}
	var ghost := _item_panel(item)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(ghost)
	_drag["ghost"] = ghost
	_size_ghost()
	panel.modulate = Color(1, 1, 1, 0.25)


func _size_ghost() -> void:
	var item: Dictionary = weapons.inv.items[_drag["uid"]]
	var idef := ItemDefs.of(item["id"])
	var rot := int(_drag["rot"])
	var w: int = idef["w"] if rot == 0 else idef["h"]
	var h: int = idef["h"] if rot == 0 else idef["w"]
	var g: Control = _drag["ghost"]
	g.custom_minimum_size = Vector2(w, h) * CELL
	g.size = g.custom_minimum_size


func _end_drag() -> void:
	if _drag.has("ghost"):
		(_drag["ghost"] as Control).queue_free()
	_drag = {}
	refresh()


func _finish_drag() -> void:
	var uid := int(_drag["uid"])
	var rot := int(_drag["rot"])
	var ghost: Control = _drag["ghost"]
	ghost.queue_free()
	_drag = {}
	var mp := _dim.get_global_mouse_position()
	# slots first
	for s in _slot_views:
		var c: Control = _slot_views[s]
		if c.get_global_rect().has_point(mp):
			if weapons.inv.move(uid, s):
				weapons.sync_weight()
			refresh()
			return
	# then grids
	for g in _grid_views:
		var c: Control = _grid_views[g]
		var r := c.get_global_rect()
		if r.has_point(mp):
			var dd: Vector2i = c.get_meta("dim")
			var cx := int((mp - r.position).x / CELL)
			var cy := int((mp - r.position).y / CELL)
			if weapons.inv.move(uid, g, cx, cy, rot):
				weapons.sync_weight()
			refresh()
			return
	# released over the panel but on no target: cancel the drag
	if _panel.get_global_rect().has_point(mp):
		refresh()
		return
	# dropped outside the panel: drop to the ground in front of the player
	weapons.drop_item(uid)
	refresh()


# ---------- nearby ----------

func _refresh_nearby() -> void:
	_clear(_near_list)
	var ep := player.eye_pos()
	for wi in world_items:
		if not is_instance_valid(wi):
			continue
		if (wi as Node3D).global_position.distance_to(ep) > WorldItem.REACH:
			continue
		var hb := HBoxContainer.new()
		var l := Label.new()
		l.text = (wi as WorldItem).title_text()
		l.add_theme_font_size_override("font_size", 13)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		var b := Button.new()
		b.text = "Take"
		b.pressed.connect(_on_take_nearby.bind(wi))
		hb.add_child(b)
		_near_list.add_child(hb)


func _on_take_nearby(wi: WorldItem) -> void:
	if is_instance_valid(wi):
		weapons.pickup_world_item(wi)
		refresh()
