class_name HitOverlay
extends Control
## Draws HitFeel on the HUD: diagonal hit ticks round the crosshair (white, or a bigger red
## cross for a kill), red arcs on a ring toward whatever hurt you, and a red edge vignette.

var feel: HitFeel
var _vig: TextureRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 0.0, 0.0, 0.0))
	g.set_color(1, Color(0.9, 0.0, 0.0, 0.7))
	g.add_point(0.8, Color(0.9, 0.0, 0.0, 0.0))
	tex.gradient = g
	_vig = TextureRect.new()
	_vig.texture = tex
	_vig.stretch_mode = TextureRect.STRETCH_SCALE
	_vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vig.modulate.a = 0.0
	add_child(_vig)


func _process(_dt: float) -> void:
	if feel != null:
		_vig.modulate.a = clampf(feel.vignette_t / Config.VIGNETTE_TIME, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	if feel == null:
		return
	var c := size * 0.5
	if feel.marker_t > 0.0 or feel.kill_t > 0.0:
		var kill := feel.kill_t > 0.0
		var a := clampf((feel.kill_t / Config.KILL_MARKER_TIME) if kill else (feel.marker_t / Config.HIT_MARKER_TIME), 0.0, 1.0)
		var col := Color(1.0, 0.15, 0.1, 0.4 + 0.6 * a) if kill else Color(1, 1, 1, 0.4 + 0.6 * a)
		var near := 8.0 + (1.0 - a) * (6.0 if kill else 3.0)
		var far := near + (16.0 if kill else 9.0)
		for s in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(c + s * near, c + s * far, col, 3.5 if kill else 2.5, true)
	var radius := minf(size.x, size.y) * 0.22
	for arc in feel.arcs:
		var ang := feel.arc_angle(arc.src) - PI * 0.5  # draw angle: 0 = +x, so rotate "ahead" to up
		var k: float = clampf(arc.t / Config.HURT_ARC_TIME, 0.0, 1.0)
		draw_arc(c, radius, ang - 0.32, ang + 0.32, 16, Color(1.0, 0.1, 0.05, 0.9 * k), 9.0, true)
