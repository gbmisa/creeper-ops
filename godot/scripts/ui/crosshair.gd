class_name Crosshair
extends Control
## Tactical crosshair: four ticks round a gap and a centre dot, with a dark outline so it reads
## on bright ground. FpsHud sets `color` (red on a hit marker).

var color := UiKit.TEXT:
	set(v):
		if v != color:
			color = v
			queue_redraw()
const GAP := 6.0
const TICK := 9.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)


func _draw() -> void:
	for pass_ in [[Color(0, 0, 0, 0.6), 4.0], [color, 2.0]]:
		for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(d * GAP, d * (GAP + TICK), pass_[0], pass_[1])
		draw_circle(Vector2.ZERO, 1.6 if pass_[1] < 3.0 else 2.6, pass_[0])
