class_name Markers
extends Control
## On-screen objective markers: each world.markers entry is projected to the screen as a
## label. Off-screen markers clamp to the edge with an arrow (FPS mode) so you always know
## which way to go. Minor markers only show when near.

var _labels: Array[Label] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _label(i: int) -> Label:
	while _labels.size() <= i:
		var l := UiKit.label("", 16)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		add_child(l)
		_labels.append(l)
	return _labels[i]


func refresh(world: World, cam: Camera3D, fps: bool) -> void:
	var size := get_viewport_rect().size
	var n := 0
	for m in world.markers:
		if not m.visible.call():
			continue
		var p: Vector3 = m.pos
		var dist := cam.global_position.distance_to(p)
		if m.get("minor", false) and dist > (40.0 if fps else 120.0):
			continue
		var depth := (p - cam.global_position).dot(-cam.global_transform.basis.z)
		if absf(depth) < 0.2:
			continue  # on the camera plane: can't project
		var behind := depth < 0.0
		var sp := cam.unproject_position(p)
		var on_screen := not behind and Rect2(Vector2.ZERO, size).has_point(sp)
		if not on_screen and not fps:
			continue
		if not fps and sp.y < 70.0:
			continue  # would sit under the top bar
		var text: String = m.label.call() if m.label is Callable else m.label
		if not on_screen:
			var c := size * 0.5
			var d := (sp - c) * (-1.0 if behind else 1.0)
			if d.length() < 1.0:
				d = Vector2(0, -1)
			var k := minf((size.x * 0.5 - 90.0) / maxf(absf(d.x), 0.001), (size.y * 0.5 - 40.0) / maxf(absf(d.y), 0.001))
			sp = c + d * k
			text = "%s %s" % [_arrow(d), text]
		var l := _label(n)
		n += 1
		l.visible = true
		l.text = "%s  %dm" % [text, roundi(dist)] if fps else text
		l.add_theme_color_override("font_color", m.color)
		l.position = sp - Vector2(l.size.x * 0.5, l.size.y)
	for i in range(n, _labels.size()):
		_labels[i].visible = false


static func _arrow(d: Vector2) -> String:
	var a := atan2(d.y, d.x)
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[posmod(roundi(a / (PI / 4.0)), 8)]
