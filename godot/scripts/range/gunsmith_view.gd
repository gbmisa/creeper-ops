class_name GunsmithView
extends Control
## F141: draws the gunsmith screen and turns the mouse into fit / remove requests for GunsmithUI.
## Left: the player's guns. Middle: GunsmithPreview (drag to rotate). Right: the gun's slots, then (F145) every part
## that fits the selected slot: bag spares first, then the supply catalogue (range / loadout room supply is unlimited).
## Click a slot to pick it, click a part to fit it. Drag a part (or a fitted one) onto the gun, its slot or another
## gun in the list; right-click a fitted part to take it off. No rules live here: GunsmithUI / Attachments / AttachmentDefs decide.

const LIST_W := 250.0
const SIDE_W := 330.0
const ROW := 52.0
const SLOT_ROW := 44.0
const SPARE_ROW := 34.0

var ui: GunsmithUI
var preview := GunsmithPreview.new()
var sel := 0
var drag := {}
var _guns: Array = []
var _spares: Array = []
var _rotating := false
var pick_slot := ""   # F145: the slot whose parts are listed
var mags_mode := false  # F147: the Magazines row is picked: the list shows this gun's mags
var note := ""
var _slot_press := -1  # slot row pressed: dragging away from it pulls the fitted part off
var _press_pos := Vector2.ZERO


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(preview)
	resized.connect(_layout)


func _layout() -> void:
	preview.position = Vector2(LIST_W + 50, 80)
	preview.size = Vector2(maxf(100.0, size.x - LIST_W - SIDE_W - 110), maxf(100.0, size.y - 160))


func refresh() -> void:
	_guns = ui.guns()
	_spares = choices()
	sel = clampi(sel, 0, maxi(0, _guns.size() - 1))
	_layout()
	preview.show_gun(_guns[sel]["gun"] if not _guns.is_empty() else null)
	queue_redraw()


func cancel_drag() -> void:
	if not drag.is_empty():
		ui.stash(drag)
	drag = {}
	_rotating = false


func gun_item() -> Dictionary:
	return _guns[sel] if sel < _guns.size() else {}


func _gun_rect(i: int) -> Rect2:
	return Rect2(30, 90 + i * (ROW + 6), LIST_W, ROW)


func slot_list() -> Array:
	var g := gun_item()
	var out := []
	if g.is_empty():
		return out
	for s in AttachmentDefs.SLOTS:
		if s in (g["gun"] as Gun).def["slots"]:
			out.append(s)
	return out


func _slot_rect(i: int) -> Rect2:
	return Rect2(size.x - SIDE_W - 20, 90 + i * (SLOT_ROW + 6), SIDE_W, SLOT_ROW)


## F145: parts for the picked slot (bag spares, then supply); F147: this gun's mags when the Magazines row is picked.
func choices() -> Array:
	var g := gun_item()
	var slots := slot_list()
	if g.is_empty() or slots.is_empty():
		return []
	if not (pick_slot in slots):
		pick_slot = slots[0]
	return GunsmithMags.choices(g["gun"]) if mags_mode else GunsmithMags.parts(g["gun"], ui.spares(), pick_slot)


func _mag_rect() -> Rect2:
	return Rect2(size.x - SIDE_W - 20, 90 + slot_list().size() * (SLOT_ROW + 6), SIDE_W, SLOT_ROW)


func _spare_rect(i: int) -> Rect2:
	var top := 90 + slot_list().size() * (SLOT_ROW + 6) + 100
	return Rect2(size.x - SIDE_W - 20, top + i * (SPARE_ROW + 4), SIDE_W, SPARE_ROW)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if _slot_press >= 0 and drag.is_empty() and e.position.distance_to(_press_pos) > 8.0:
			var slots := slot_list()
			if _slot_press < slots.size() and (gun_item()["gun"] as Gun).fit.has(slots[_slot_press]):
				drag = ui.unfit(gun_item(), slots[_slot_press])
				_after()
			_slot_press = -1
		if _rotating:
			preview.turn(e.relative)
		queue_redraw()
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			_press(e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			_release(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and drag.is_empty():
			var slots := slot_list()
			for i in slots.size():
				if _slot_rect(i).has_point(e.position) and (gun_item()["gun"] as Gun).fit.has(slots[i]):
					ui.stash(ui.unfit(gun_item(), slots[i]))
					_after()


func _press(p: Vector2) -> void:
	for i in _guns.size():
		if _gun_rect(i).has_point(p):
			sel = i
			preview.show_gun(_guns[i]["gun"])
			queue_redraw()
			return
	var slots := slot_list()
	for i in slots.size():
		if _slot_rect(i).has_point(p):
			pick_slot = slots[i]
			mags_mode = false
			note = ""
			_slot_press = i
			_press_pos = p
			_after()
			return
	if not slots.is_empty() and _mag_rect().has_point(p):
		mags_mode = true
		note = ""
		_after()
		return
	for i in _spares.size():
		if _spare_rect(i).has_point(p):
			var it: Dictionary = _spares[i]
			if it.has("mag"):
				note = GunsmithMags.give(ui.weapons.inv, it["id"])
				ui.inv_ui._settle()
				_after()
				return
			if it.has("catalog"):
				it = ui.weapons.inv.make(it["id"])
			ui.fit(it, gun_item())
			_after()
			return
	if Rect2(preview.position, preview.size).has_point(p):
		_rotating = true


func _release(p: Vector2) -> void:
	_rotating = false
	_slot_press = -1
	if drag.is_empty():
		return
	var att := drag
	drag = {}
	var target := {}
	for i in _guns.size():
		if _gun_rect(i).has_point(p):
			target = _guns[i]
	var slots := slot_list()
	for i in slots.size():
		if _slot_rect(i).has_point(p) and AttachmentDefs.ROWS[att["id"]]["slot"] == slots[i]:
			target = gun_item()
	if target.is_empty() and Rect2(preview.position, preview.size).has_point(p):
		target = gun_item()
	if target.is_empty():
		ui.stash(att)
	else:
		ui.fit(att, target)
	_after()


func _after() -> void:
	_guns = ui.guns()
	_spares = choices()
	queue_redraw()


func _draw() -> void:
	if ui == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.03, 0.9))
	draw_string(font, Vector2(30, 50), "GUNSMITH", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiKit.ACCENT_HI)
	draw_string(font, Vector2(30, size.y - 24), "Click a gun   Click a slot, then a part to fit it   Drag parts between guns   Right-click a fitted part to remove   Drag the model to turn it   Esc / Tab close", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.TEXT)
	draw_string(font, Vector2(30, 82), "GUNS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.DIM)
	for i in _guns.size():
		var r := _gun_rect(i)
		var g := _guns[i]["gun"] as Gun
		draw_rect(r, Color(0.2, 0.26, 0.22, 0.95) if i == sel else Color(0.08, 0.09, 0.07, 0.95))
		draw_rect(r, Color(0.46, 0.49, 0.33, 0.8) if i == sel else Color(0.46, 0.49, 0.33, 0.4), false, 1.0)
		draw_string(font, r.position + Vector2(10, 22), ItemDefs.label(_guns[i]).get_slice(" (", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.TEXT)
		draw_string(font, r.position + Vector2(10, 42), "%d part(s) fitted" % g.fit.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.DIM)
		if AttachMarks.is_part(drag):  # F143: green = this gun takes the dragged part, red = it does not
			AttachMarks.mark(self, r, AttachMarks.fits(_guns[i], drag))
	if _guns.is_empty():
		draw_string(font, Vector2(30, 110), "No guns carried", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.DIM)
	var pr := Rect2(preview.position, preview.size)
	draw_rect(pr, Color(0.06, 0.08, 0.08, 0.7))
	draw_rect(pr, Color(0.46, 0.49, 0.33, 0.4), false, 1.0)
	var gi := gun_item()
	if not gi.is_empty():
		draw_string(font, pr.position + Vector2(10, 22), (gi["gun"] as Gun).def["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.TEXT)
	draw_string(font, Vector2(size.x - SIDE_W - 20, 82), "SLOTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.DIM)
	var slots := slot_list()
	for i in slots.size():
		var r := _slot_rect(i)
		var fitted: Dictionary = (gi["gun"] as Gun).fit
		var picked: bool = slots[i] == pick_slot and not mags_mode
		draw_rect(r, Color(0.2, 0.26, 0.22, 0.95) if picked else Color(0.08, 0.09, 0.07, 0.95))
		draw_rect(r, Color(0.46, 0.49, 0.33, 0.9 if picked else 0.6), false, 2.0 if picked else 1.0)
		draw_string(font, r.position + Vector2(10, 18), String(slots[i]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.DIM)
		var nm := "(empty)" if not fitted.has(slots[i]) else String(AttachmentDefs.ROWS[fitted[slots[i]]]["name"])
		if AttachMarks.is_part(drag):  # F143: only the matching slot of a compatible gun is green
			AttachMarks.mark(self, r, AttachMarks.fits(gi, drag, slots[i]))
		draw_string(font, r.position + Vector2(10, 37), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.TEXT if fitted.has(slots[i]) else UiKit.DIM)
	if not slots.is_empty():
		GunsmithMags.draw_button(self, font, _mag_rect(), mags_mode, note)
	var sy := 90 + slots.size() * (SLOT_ROW + 6) + 88
	draw_string(font, Vector2(size.x - SIDE_W - 20, sy), "MAGAZINES" if mags_mode else (("AVAILABLE: %s" % pick_slot.to_upper()) if pick_slot != "" else "AVAILABLE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.DIM)
	for i in _spares.size():
		if not drag.is_empty() and _spares[i].has("uid") and _spares[i]["uid"] == drag["uid"]:
			continue
		GunsmithMags.draw_row(self, font, _spare_rect(i), _spares[i])
	if _spares.is_empty():
		draw_string(font, Vector2(size.x - SIDE_W - 20, sy + 24), "Nothing else fits this slot" if not slots.is_empty() else "No slots on this gun", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.DIM)
	if not drag.is_empty():
		var mp := get_local_mouse_position()
		GunsmithMags.draw_row(self, font, Rect2(mp - Vector2(SIDE_W * 0.5, SPARE_ROW * 0.5), Vector2(SIDE_W, SPARE_ROW)), drag, 0.85)
