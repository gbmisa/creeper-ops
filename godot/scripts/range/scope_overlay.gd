class_name ScopeOverlay
extends Control
## Magnified sight view: black outside a circle plus a reticle (`style`: mildot, chevron, cross; Gun.reticle()).
## Shown while PlayerWeapons.scoped().

var style := "mildot":
	set(v):
		if v != style:
			style = v
			queue_redraw()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _draw() -> void:
	var c := size * 0.5
	var r := size.y * 0.46
	var black := Color.BLACK
	draw_rect(Rect2(0, 0, size.x, c.y - r), black)
	draw_rect(Rect2(0, c.y + r, size.x, size.y - c.y - r), black)
	draw_rect(Rect2(0, c.y - r, c.x - r, 2 * r), black)
	draw_rect(Rect2(c.x + r, c.y - r, size.x - c.x - r, 2 * r), black)
	# corner fill outside the circle
	var pts := PackedVector2Array()
	for q in 4:
		pts.clear()
		var sx := -1.0 if q % 2 == 0 else 1.0
		var sy := -1.0 if q < 2 else 1.0
		pts.append(c + Vector2(sx * r, sy * r))
		for i in range(17):
			var a := float(i) / 16.0 * PI * 0.5
			pts.append(c + Vector2(sx * cos(a), sy * sin(a)) * r)
		draw_colored_polygon(pts, black)
	draw_arc(c, r, 0, TAU, 96, black, 4.0)
	var ink := Color(0.02, 0.02, 0.02)
	if style == "chevron":
		_chevron(c, r, ink)
		return
	if style == "cross":
		_cross(c, r, ink)
		return
	draw_line(c + Vector2(-r, 0), c + Vector2(-14, 0), ink, 2.0)
	draw_line(c + Vector2(14, 0), c + Vector2(r, 0), ink, 2.0)
	draw_line(c + Vector2(0, -r), c + Vector2(0, -14), ink, 2.0)
	draw_line(c + Vector2(0, 14), c + Vector2(0, r), ink, 2.0)
	for i in range(1, 6):
		for sgn in [-1.0, 1.0]:
			draw_circle(c + Vector2(sgn * i * 40.0, 0), 3.0, ink)
			draw_circle(c + Vector2(0, sgn * i * 40.0), 3.0, ink)
	draw_circle(c, 1.5, Color(0.9, 0.1, 0.1))


## ACOG: chevron with a post and ranging ticks below it.
func _chevron(c: Vector2, r: float, ink: Color) -> void:
	var red := Color(0.95, 0.1, 0.08)
	draw_line(c + Vector2(0, -r), c + Vector2(0, -8), ink, 2.0)
	draw_line(c + Vector2(-r, 0), c + Vector2(-r * 0.35, 0), ink, 2.0)
	draw_line(c + Vector2(r * 0.35, 0), c + Vector2(r, 0), ink, 2.0)
	draw_line(c + Vector2(-26, 26), c, red, 3.0)
	draw_line(c + Vector2(26, 26), c, red, 3.0)
	for i in range(1, 5):
		draw_line(c + Vector2(-8 - i * 2, i * 44), c + Vector2(8 + i * 2, i * 44), red, 2.0)
	draw_circle(c, 1.8, red)


## LPVO: fine crosshair with a thick outer post and an illuminated centre dot.
func _cross(c: Vector2, r: float, ink: Color) -> void:
	draw_line(c + Vector2(-r, 0), c + Vector2(-40, 0), ink, 4.0)
	draw_line(c + Vector2(40, 0), c + Vector2(r, 0), ink, 4.0)
	draw_line(c + Vector2(0, 40), c + Vector2(0, r), ink, 4.0)
	draw_line(c + Vector2(-40, 0), c + Vector2(-6, 0), ink, 1.5)
	draw_line(c + Vector2(6, 0), c + Vector2(40, 0), ink, 1.5)
	draw_line(c + Vector2(0, 6), c + Vector2(0, 40), ink, 1.5)
	draw_circle(c, 2.0, Color(0.95, 0.1, 0.08))
