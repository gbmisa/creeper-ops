class_name RangeHitLog
extends CanvasLayer
## Left-hand log of the last 8 hits (target, zone, distance, damage, PEN / BLOCKED / RICOCHET, armor left).

const MAX_LINES := 8
var lines: Array[String] = []
var _lbl: Label
var _tgt: Label
var _tgt_panel: PanelContainer


func _init() -> void:
	layer = 5
	var p := UiKit.panel(Color(0.04, 0.05, 0.07, 0.55))
	p.position = Vector2(8, 330)
	p.custom_minimum_size = Vector2(430, 0)
	add_child(p)
	_lbl = UiKit.label("HIT LOG", 13, Color(0.92, 0.92, 0.85))
	p.add_child(_lbl)
	_tgt_panel = UiKit.panel(Color(0.04, 0.05, 0.07, 0.7))
	_tgt_panel.position = Vector2(1330, 20)
	_tgt_panel.custom_minimum_size = Vector2(250, 0)
	_tgt_panel.visible = false
	add_child(_tgt_panel)
	_tgt = UiKit.label("", 18)
	_tgt_panel.add_child(_tgt)
	_refresh()


## Last-hit dummy per-zone panel (top-right, readable at any range).
func set_target(text: String, dead: bool) -> void:
	_tgt.text = text
	_tgt.modulate = Color(1, 0.55, 0.5) if dead else Color(1, 1, 0.85)
	_tgt_panel.visible = true


func add(text: String) -> void:
	lines.append(text)
	while lines.size() > MAX_LINES:
		lines.pop_front()
	_refresh()


func clear() -> void:
	lines.clear()
	_tgt_panel.visible = false
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
