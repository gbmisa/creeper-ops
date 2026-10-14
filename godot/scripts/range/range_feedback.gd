class_name RangeFeedback
extends Node3D
## Ballistics -> feedback: floating damage numbers, the hit log, dummy panels, plate swing, paper marks.

var targets: RangeTargets
var log: RangeHitLog
const COL := {"PEN": Color(1, 0.35, 0.3), "BLOCKED": Color(1, 0.8, 0.25), "RICOCHET": Color(0.9, 0.9, 0.95)}


func setup(bal: Ballistics, t: RangeTargets, l: RangeHitLog) -> void:
	targets = t
	log = l
	bal.body_hit.connect(on_body_hit)
	bal.impact.connect(on_impact)


func on_body_hit(res: Dictionary) -> void:
	var d := res.get("owner") as RangeDummy
	if d != null:
		d.on_hit(res)
	log.add(RangeHitLog.format(res))
	number(res["pos"], str(int(round(res["dmg"]))), COL.get(res["result"], Color.WHITE), res["dist"])


func on_impact(info: Dictionary) -> void:
	var line := targets.on_impact(info)
	if line != "":
		log.add(line)


func number(pos: Vector3, text: String, col: Color, dist: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.outline_size = 14
	l.pixel_size = 0.003 * (1.0 + dist / 30.0)
	add_child(l)
	l.global_position = pos + Vector3(0, 0.15, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.6 + dist * 0.01, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
