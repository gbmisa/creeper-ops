class_name RangeBodyHud
extends Control
## Mini 7-zone body readout (bottom-left), red damage-direction wedges around the screen centre when hit,
## a red flash on every hit and the death fade.

const CUE_TIME := 1.4
const SHAPES := {"head": Rect2(-9, -78, 18, 18), "thorax": Rect2(-17, -58, 34, 26), "stomach": Rect2(-14, -30, 28, 16),
	"larm": Rect2(-27, -58, 9, 34), "rarm": Rect2(18, -58, 9, 34), "lleg": Rect2(-14, -12, 13, 40), "rleg": Rect2(1, -12, 13, 40)}
const ORIGIN := Vector2(300, 820)

var player: TacticalPlayer
var cues: Array = []  # {ang, t}
var flash := 0.0
var fade := 0.0


func setup(p: TacticalPlayer) -> void:
	player = p
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.hit_taken.connect(_on_hit)


func _on_hit(from: Vector3, _res: Dictionary) -> void:
	var to := from - player.global_position
	to.y = 0.0
	var local := to.rotated(Vector3.UP, -player.yaw)
	cues.append({"ang": atan2(local.x, -local.z), "t": CUE_TIME})
	flash = 0.35


func _process(delta: float) -> void:
	for c in cues:
		c["t"] -= delta
	cues = cues.filter(func(c): return c["t"] > 0.0)
	flash = maxf(0.0, flash - delta)
	fade = move_toward(fade, 1.0 if player.dead_t > 0.0 else 0.0, delta * (0.8 if player.dead_t > 0.0 else 1.5))
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var size_v := get_viewport_rect().size
	draw_rect(Rect2(ORIGIN + Vector2(-48, -92), Vector2(96, 150)), Color(0.04, 0.05, 0.07, 0.55))
	for z in SHAPES:
		var f: float = player.body.hp[z] / BodyHealth.MAX[z]
		var col := Color(0.15, 0.04, 0.04) if f <= 0.0 else Color(1.0 - f * 0.7, 0.25 + f * 0.65, 0.2)
		var r: Rect2 = SHAPES[z]
		draw_rect(Rect2(ORIGIN + r.position, r.size), col)
		if player.body.armor.has(z):
			draw_rect(Rect2(ORIGIN + r.position, r.size), Color(0.7, 0.8, 1.0, 0.8), false, 1.5)
	for b in player.body.bleeds:
		var r2: Rect2 = SHAPES[b["zone"]]
		draw_circle(ORIGIN + r2.get_center(), 3.0, Color(0.85, 0.0, 0.0))
	var centre := size_v * 0.5
	for c in cues:
		var a: float = c["ang"]
		var dir := Vector2(sin(a), -cos(a))
		var perp := Vector2(-dir.y, dir.x)
		var p0 := centre + dir * 170.0
		var al: float = clampf(c["t"] / CUE_TIME, 0.0, 1.0)
		draw_colored_polygon(PackedVector2Array([p0 + dir * 34.0, p0 + perp * 16.0, p0 - perp * 16.0]), Color(1, 0.1, 0.05, al))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size_v), Color(0.8, 0.0, 0.0, flash * 0.5))
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size_v), Color(0.05, 0.0, 0.0, fade))
		draw_string(ThemeDB.fallback_font, centre + Vector2(-70, 0), "YOU DIED", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.9, 0.2, 0.2, fade))
