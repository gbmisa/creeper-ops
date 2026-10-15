class_name ScopeOverlay
extends Control
## 6x scope view: black outside a circle plus a mil-dot reticle. Shown while PlayerWeapons.scoped().


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
	draw_line(c + Vector2(-r, 0), c + Vector2(-14, 0), ink, 2.0)
	draw_line(c + Vector2(14, 0), c + Vector2(r, 0), ink, 2.0)
	draw_line(c + Vector2(0, -r), c + Vector2(0, -14), ink, 2.0)
	draw_line(c + Vector2(0, 14), c + Vector2(0, r), ink, 2.0)
	for i in range(1, 6):
		for sgn in [-1.0, 1.0]:
			draw_circle(c + Vector2(sgn * i * 40.0, 0), 3.0, ink)
			draw_circle(c + Vector2(0, sgn * i * 40.0), 3.0, ink)
	draw_circle(c, 1.5, Color(0.9, 0.1, 0.1))
