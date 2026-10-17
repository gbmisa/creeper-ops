class_name AttachMarks
## F143: the green / red marking shared by the inventory and gunsmith screens while an attachment is dragged.
## Compatibility comes from Attachments.why_not (gun class, slot list, sniper-rail rule, busy gun): no rules here.

const OK := Color(0.2, 0.85, 0.25)
const NO := Color(0.95, 0.2, 0.2)


## True when `att` (a dragged item) can go on `gun_item`; with `slot` also only if it is that slot's part.
static func fits(gun_item: Dictionary, att: Dictionary, slot := "") -> bool:
	if slot != "" and AttachmentDefs.ROWS[att["id"]]["slot"] != slot:
		return false
	return Attachments.why_not(gun_item, att) == ""


static func is_part(drag: Dictionary) -> bool:
	return not drag.is_empty() and ItemDefs.def_of(drag)["kind"] == "attach"


## Fill + outline over `r` in the OK / NO colour.
static func mark(c: CanvasItem, r: Rect2, ok: bool) -> void:
	var col := OK if ok else NO
	c.draw_rect(r, Color(col.r, col.g, col.b, 0.32))
	c.draw_rect(r, col, false, 2.0)
