class_name InventoryView
extends Control
## Draws the inventory screen (equipment slots left, grids middle, ground right) and turns mouse input into
## drag / drop requests for the InventoryUI host. No inventory rules live here.

signal drop_requested(item: Dictionary, target: Dictionary, origin: Dictionary)  # target {} = outside every region
signal quick_requested(item: Dictionary)
signal unfit_requested(gun_item: Dictionary, slot: String, drag: bool)  # right-click a fitted-part chip = remove, left-press = drag it off

const C := 36  # cell px
const SLOT_CELLS := {"primary": Vector2i(5, 2), "secondary": Vector2i(5, 2), "holster": Vector2i(5, 1),
	"armor": Vector2i(3, 3), "rig": Vector2i(3, 2), "backpack": Vector2i(4, 4)}
const SLOT_TITLE := {"primary": "PRIMARY", "secondary": "SECONDARY", "holster": "HOLSTER", "armor": "ARMOR", "rig": "RIG", "backpack": "BACKPACK"}
const KIND_COL := {"gun": Color(0.32, 0.36, 0.42), "mag": Color(0.3, 0.3, 0.3), "ammo": Color(0.55, 0.42, 0.12), "armor": Color(0.25, 0.4, 0.28),
	"rig": Color(0.45, 0.38, 0.22), "backpack": Color(0.35, 0.45, 0.3), "med": Color(0.6, 0.18, 0.18), "attach": Color(0.2, 0.42, 0.5)}
const CHIP := 14.0

var inv: Inventory
var drag := {}
var drag_rot := 0
var origin := {}
var grab := Vector2.ZERO


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Every drop target: {loc, rect, slot, title}. Grids that don't exist (no rig worn) are left out.
func regions() -> Array:
	var out := []
	var y := 60.0
	for s in Inventory.SLOTS:
		var sz: Vector2i = SLOT_CELLS[s]
		out.append({"loc": s, "rect": Rect2(40, y + 18, sz.x * C, sz.y * C), "slot": true, "title": SLOT_TITLE[s]})
		y += 18 + sz.y * C + 10
	y = 60.0
	for g in [["rig_g", "RIG"], ["pockets", "POCKETS"], ["pack_g", "BACKPACK"]]:
		var gs := inv.grid_size(g[0])
		if gs != Vector2i.ZERO:
			out.append({"loc": g[0], "rect": Rect2(290, y + 18, gs.x * C, gs.y * C), "slot": false, "title": g[1]})
			y += 18 + gs.y * C + 10
	var gr := inv.grid_size("ground")
	out.append({"loc": "ground", "rect": Rect2(540, 78, gr.x * C, gr.y * C), "slot": false, "title": "GROUND (within 2 m)"})
	return out


func item_rect(r: Dictionary, it: Dictionary) -> Rect2:
	var rect: Rect2 = r["rect"]
	if r["slot"]:
		var d := ItemDefs.def_of(it)
		return Rect2(rect.position, Vector2(d["w"], d["h"]) * C)
	return Rect2(rect.position + Vector2(it["x"], it["y"]) * C, Vector2(inv.size_of(it)) * C)


func item_at(p: Vector2) -> Dictionary:
	for r in regions():
		if not (r["rect"] as Rect2).has_point(p):
			continue
		var list: Array = [inv.equipped(r["loc"])] if r["slot"] else inv.grid_items(r["loc"])
		for it in list:
			if it != null and item_rect(r, it).has_point(p):
				return it
	return {}


## Where a drop at the mouse would land: {loc, x, y, rot}, or {} outside every region.
func target_at(p: Vector2) -> Dictionary:
	for r in regions():
		var rect: Rect2 = r["rect"]
		if r["slot"]:
			if rect.has_point(p):
				return {"loc": r["loc"], "x": 0, "y": 0, "rot": drag_rot}
		elif rect.has_point(p) or rect.has_point(p - grab):
			var top_left := (p - grab - rect.position) / C
			return {"loc": r["loc"], "x": roundi(top_left.x), "y": roundi(top_left.y), "rot": drag_rot}
	return {}


func rotate_drag() -> void:
	var d := ItemDefs.def_of(drag)
	if not drag.is_empty() and d["w"] != d["h"]:
		drag_rot = 1 - drag_rot
		queue_redraw()


## Chip rects of a gun's fitted parts, bottom-right of its cell: {slot: Rect2}.
func chips(it: Dictionary, rect: Rect2) -> Dictionary:
	var out := {}
	var i := 0
	for slot in AttachmentDefs.SLOTS:
		if (it["gun"] as Gun).fit.has(slot):
			out[slot] = Rect2(rect.end - Vector2(CHIP * (i + 1) + 3, CHIP + 3), Vector2(CHIP, CHIP))
			i += 1
	return out


## {item, slot} for a fitted-part chip under p, or {}.
func chip_at(p: Vector2) -> Dictionary:
	var it := item_at(p)
	if it.is_empty() or not it.has("gun"):
		return {}
	var ch := chips(it, _rect_of(it))
	for slot in ch:
		if (ch[slot] as Rect2).has_point(p):
			return {"item": it, "slot": slot}
	return {}


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		queue_redraw()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		var c := chip_at(e.position)
		if not c.is_empty():
			unfit_requested.emit(c["item"], c["slot"], false)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var chip := chip_at(e.position) if e.pressed else {}
		if not chip.is_empty():
			unfit_requested.emit(chip["item"], chip["slot"], true)
			return
		var it := item_at(e.position)
		if e.pressed and not it.is_empty():
			if e.ctrl_pressed:
				quick_requested.emit(it)
			else:
				drag = it
				drag_rot = int(it["rot"])
				origin = {"loc": it["loc"], "x": it["x"], "y": it["y"], "rot": it["rot"]}
				var hit := _rect_of(it)
				grab = e.position - hit.position
		elif not e.pressed and not drag.is_empty():
			var it2 := drag
			var t := target_at(e.position)
			drag = {}
			drop_requested.emit(it2, t, origin)
		queue_redraw()


func _rect_of(it: Dictionary) -> Rect2:
	for r in regions():
		if r["loc"] == it["loc"]:
			return item_rect(r, it)
	return Rect2()


func _input(e: InputEvent) -> void:
	if visible and not drag.is_empty() and e is InputEventKey and e.pressed and not e.echo and Keybinds.matches("t_reload", e.keycode):
		rotate_drag()
		accept_event()


func _draw() -> void:
	if inv == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.03, 0.88))
	for r in regions():
		var rect: Rect2 = r["rect"]
		draw_string(font, rect.position + Vector2(0, -5), r["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.DIM)
		draw_rect(rect, Color(0.08, 0.09, 0.07, 0.95))
		if not r["slot"]:
			for gx in range(int(rect.size.x / C) + 1):
				draw_line(rect.position + Vector2(gx * C, 0), rect.position + Vector2(gx * C, rect.size.y), Color(1, 1, 1, 0.07))
			for gy in range(int(rect.size.y / C) + 1):
				draw_line(rect.position + Vector2(0, gy * C), rect.position + Vector2(rect.size.x, gy * C), Color(1, 1, 1, 0.07))
		draw_rect(rect, Color(0.46, 0.49, 0.33, 0.6), false, 1.0)
		var list: Array = [inv.equipped(r["loc"])] if r["slot"] else inv.grid_items(r["loc"])
		for it in list:
			if it != null and (drag.is_empty() or it["uid"] != drag["uid"]):
				_draw_item(font, it, item_rect(r, it), 1.0)
	var mp := get_local_mouse_position()
	if not drag.is_empty():
		var t := target_at(mp)
		if not t.is_empty() and not inv.is_slot(t["loc"]):
			var ok := inv.fits(t["loc"], drag, t["x"], t["y"], drag_rot)
			for r in regions():
				if r["loc"] == t["loc"]:
					var fp := Rect2((r["rect"] as Rect2).position + Vector2(t["x"], t["y"]) * C, Vector2(inv.size_of(drag, drag_rot)) * C)
					draw_rect(fp, Color(0.2, 0.8, 0.2, 0.3) if ok else Color(0.9, 0.2, 0.2, 0.3))
		_draw_item(font, drag, Rect2(mp - grab, Vector2(inv.size_of(drag, drag_rot)) * C), 0.8)
	else:
		_tooltip(font, item_at(mp), mp)
	draw_string(font, Vector2(40, size.y - 24), "Weight: %.1f kg     Drag to move   R rotate   Ctrl+click quick move   drop outside = on the ground   Tab / Esc close" % inv.total_kg(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.TEXT)


func _draw_item(font: Font, it: Dictionary, rect: Rect2, alpha: float) -> void:
	var col: Color = KIND_COL[ItemDefs.def_of(it)["kind"]]
	draw_rect(rect.grow(-1), Color(col.r, col.g, col.b, alpha))
	draw_rect(rect.grow(-1), Color(0.9, 0.9, 0.8, alpha * 0.6), false, 1.0)
	var chars := maxi(3, int(rect.size.x / 6.5))
	var nm: String = ItemDefs.def_of(it)["name"]
	draw_string(font, rect.position + Vector2(4, 14), nm.substr(0, chars), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, alpha))
	if it.has("gun"):
		var ch := chips(it, rect)
		for slot in ch:
			var r: Rect2 = ch[slot]
			draw_rect(r, Color(0.2, 0.42, 0.5, alpha))
			draw_rect(r, Color(1, 1, 1, 0.7), false, 1.0)
			draw_string(font, r.position + Vector2(3, 11), String(slot).substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, alpha))
	var extra := ""
	if it.has("count"):
		extra = str(it["count"])
	elif it.has("rounds"):
		extra = str(it["rounds"])
	if extra != "":
		draw_string(font, rect.position + Vector2(4, rect.size.y - 5), extra, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.ACCENT_HI)


func _tooltip(font: Font, it: Dictionary, p: Vector2) -> void:
	if it.is_empty():
		return
	var lines: Array[String] = [ItemDefs.label(it), "%.2f kg" % ItemDefs.item_kg(it)]
	if it.has("gun"):
		lines.append("%d rounds loaded" % (it["gun"] as Gun).rounds_total())
		var gd: Dictionary = (it["gun"] as Gun).def
		lines.append("Slots: %s" % ", ".join(gd["slots"]))
		for slot in (it["gun"] as Gun).fit:
			lines.append("  %s: %s" % [slot, AttachmentDefs.ROWS[(it["gun"] as Gun).fit[slot]]["name"]])
		if not (it["gun"] as Gun).fit.is_empty():
			lines.append("(right-click or drag a chip to remove)")
	elif ItemDefs.def_of(it)["kind"] == "attach":
		lines.append(AttachmentDefs.describe(it["id"]))
		lines.append("Drag onto a gun to fit")
	var w := 0.0
	for l in lines:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
	var box := Rect2(p + Vector2(16, 16), Vector2(w + 14, lines.size() * 18 + 8))
	draw_rect(box, Color(0.05, 0.06, 0.04, 0.96))
	draw_rect(box, UiKit.EDGE, false, 1.0)
	for i in lines.size():
		draw_string(font, box.position + Vector2(7, 18 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.TEXT if i == 0 else UiKit.DIM)
