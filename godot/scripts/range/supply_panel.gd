class_name SupplyPanel
extends RefCounted
## The SUPPLY panel drawn in place of GROUND while the ammo bench opened the inventory: refill button, category tabs,
## a scrolling list of rows. Input turns into InventoryView signals (take / drop / return / refill).

const W := 360.0
const H := 504.0
const ROW_H := 28.0
const TAB_H := 24.0
const TOP := 34.0  # refill button + gap
const LIST_Y := 90.0
const LIST_H := 378.0  # ends 36 px above the bottom for the footer

var origin := Vector2.ZERO  # top-left, set by the view each frame
var cat := 0
var scroll := 0.0
var press := {}  # {id, pos}: a row is held down (click = take, move = drag it out)


func rect() -> Rect2:
	return Rect2(origin, Vector2(W, H))


func _refill_rect() -> Rect2:
	return Rect2(origin, Vector2(W, 28))


func _tab_rect(i: int) -> Rect2:
	return Rect2(origin + Vector2((i % 4) * W / 4.0, TOP + (i / 4) * TAB_H), Vector2(W / 4.0, TAB_H))


func _list_rect() -> Rect2:
	return Rect2(origin + Vector2(0, LIST_Y), Vector2(W, LIST_H))


func _row_rect(i: int) -> Rect2:
	return Rect2(origin + Vector2(0, LIST_Y + i * ROW_H - scroll), Vector2(W - 2, ROW_H - 2))


## {kind: "refill"} / {kind: "tab", i} / {kind: "row", id} / {}.
func hit(p: Vector2) -> Dictionary:
	if _refill_rect().has_point(p):
		return {"kind": "refill"}
	for i in SupplyCatalogDefs.NAMES.size():
		if _tab_rect(i).has_point(p):
			return {"kind": "tab", "i": i}
	if _list_rect().has_point(p):
		var ids := SupplyCatalogDefs.ids(cat)
		var i := int((p.y - origin.y - LIST_Y + scroll) / ROW_H)
		if i >= 0 and i < ids.size():
			return {"kind": "row", "id": ids[i]}
	return {}


## True when the event was consumed.
func input(e: InputEvent, v: InventoryView) -> bool:
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if rect().has_point(e.position):
			var max_s := maxf(0.0, SupplyCatalogDefs.ids(cat).size() * ROW_H - LIST_H)
			scroll = clampf(scroll + (-ROW_H if e.button_index == MOUSE_BUTTON_WHEEL_UP else ROW_H), 0.0, max_s)
			v.queue_redraw()
			return true
		return false
	if not (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		return false
	if e.pressed:
		if not v.drag.is_empty() or not rect().has_point(e.position):
			return false
		var h := hit(e.position)
		match h.get("kind", ""):
			"refill":
				v.supply_refill.emit()
			"tab":
				cat = h["i"]
				scroll = 0.0
			"row":
				press = {"id": h["id"], "pos": e.position}
		v.queue_redraw()
		return true
	if not press.is_empty():
		var id: String = press["id"]
		var moved: bool = (e.position - (press["pos"] as Vector2)).length() > 8.0
		press = {}
		if not moved:
			v.supply_take.emit(id)
		else:
			v.drag_rot = 0
			v.grab = Vector2(InventoryView.C, InventoryView.C) * 0.5
			v.supply_drop.emit(id, v.target_at(e.position))
		v.queue_redraw()
		return true
	if not v.drag.is_empty() and rect().has_point(e.position):
		var it := v.drag
		v.drag = {}
		v.supply_return.emit(it)
		v.queue_redraw()
		return true
	return false


func draw(ci: CanvasItem, font: Font, mp: Vector2) -> void:
	ci.draw_string(font, origin + Vector2(0, -5), "SUPPLY (unlimited)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.DIM)
	ci.draw_rect(rect(), Color(0.08, 0.09, 0.07, 0.95))
	ci.draw_rect(rect(), Color(0.46, 0.49, 0.33, 0.6), false, 1.0)
	_button(ci, font, _refill_rect(), "Refill held gun + mags", false)
	for i in SupplyCatalogDefs.NAMES.size():
		_button(ci, font, _tab_rect(i), SupplyCatalogDefs.NAMES[i], i == cat)
	var ids := SupplyCatalogDefs.ids(cat)
	var lr := _list_rect()
	for i in ids.size():
		var r := _row_rect(i)
		if r.position.y < lr.position.y or r.end.y > lr.end.y:
			continue
		var d := ItemDefs.of(ids[i])
		var col: Color = InventoryView.KIND_COL[d["kind"]]
		ci.draw_rect(r, Color(col.r, col.g, col.b, 0.85 if r.has_point(mp) else 0.6))
		ci.draw_rect(r, Color(0.9, 0.9, 0.8, 0.4), false, 1.0)
		ci.draw_string(font, r.position + Vector2(8, 19), "%s   %dx%d" % [d["name"], d["w"], d["h"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
	ci.draw_string(font, origin + Vector2(6, H - 12), "Click = take   Drag out to a slot / grid   Drop an item here = return it", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiKit.DIM)
	if not press.is_empty() and (mp - (press["pos"] as Vector2)).length() > 8.0:
		ci.draw_string(font, mp + Vector2(10, 4), ItemDefs.of(press["id"])["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.ACCENT_HI)


func _button(ci: CanvasItem, font: Font, r: Rect2, text: String, on: bool) -> void:
	ci.draw_rect(r.grow(-1), Color(0.2, 0.26, 0.22, 0.95) if on else Color(0.12, 0.13, 0.1, 0.95))
	ci.draw_rect(r.grow(-1), Color(0.46, 0.49, 0.33, 0.9 if on else 0.5), false, 1.0)
	ci.draw_string(font, r.position + Vector2(5, 17), text, HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x) - 8, 11, UiKit.TEXT)
