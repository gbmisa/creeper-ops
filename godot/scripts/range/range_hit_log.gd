class_name RangeHitLog
extends CanvasLayer
## Left-hand log of the last 8 hits (target, zone, distance, damage, PEN / BLOCKED / RICOCHET, armor left).

const MAX_LINES := 8
var lines: Array[String] = []
var _lbl: Label


func _init() -> void:
	layer = 5
	var p := UiKit.panel(Color(0.04, 0.05, 0.07, 0.55))
	p.position = Vector2(8, 330)
	p.custom_minimum_size = Vector2(430, 0)
	add_child(p)
	_lbl = UiKit.label("HIT LOG", 13, Color(0.92, 0.92, 0.85))
	p.add_child(_lbl)
	_refresh()


func add(text: String) -> void:
	lines.append(text)
	while lines.size() > MAX_LINES:
		lines.pop_front()
	_refresh()


func clear() -> void:
	lines.clear()
	_refresh()


func _refresh() -> void:
	_lbl.text = "HIT LOG\n" + "\n".join(lines)


## One body-hit line from a Ballistics.body_hit dictionary.
static func format(res: Dictionary) -> String:
	var who: String = res["owner"].label_name if res.get("owner") != null and "label_name" in res["owner"] else "Body"
	var armor := ""
	if res.get("armor_dur", -1.0) >= 0.0:
		armor = " | armor %d" % int(res["armor_dur"])
	var tail := " KILL" if res.get("killed", false) else ""
	return "%s | %s | %.0f m | %d dmg | %s%s%s" % [who, res["zone"], res["dist"], int(round(res["dmg"])), res["result"], armor, tail]
