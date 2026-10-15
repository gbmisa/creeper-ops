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
		l.add_theme_constant_override("outline_size", 2)
		var plate := UiTheme.box(Color(0.03, 0.035, 0.025, 0.62), Color.WHITE, 0, 0)  # tag plate, edge = marker colour
		plate.border_width_left = 3
		plate.content_margin_left = 6
		plate.content_margin_right = 5
		plate.content_margin_top = 1
		plate.content_margin_bottom = 1
		l.add_theme_stylebox_override("normal", plate)
		add_child(l)
		_labels.append(l)
	return _labels[i]


func refresh(world: World, cam: Camera3D, fps: bool) -> void:
	var size := get_viewport_rect().size
	var n := 0
	for m in world.markers:
		if not m.visible.call():
			continue
		var p: Vector3 = m.pos.call() if m.pos is Callable else m.pos
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
		# Theme and text writes re-lay the label out, so only touch what changed (PT4 perf:
		# this loop cost 6.7 ms a frame in first person with every edge arrow rewritten).
		var shown: String = "%s  %dm" % [text, roundi(dist)] if fps else text
		var font := 14 if m.get("minor", false) else 16
		var style := [m.color, font]
		if l.get_meta("style", []) != style:
			l.set_meta("style", style)
			l.add_theme_color_override("font_color", m.color)
			l.add_theme_font_size_override("font_size", font)
			(l.get_theme_stylebox("normal") as StyleBoxFlat).border_color = m.color
			l.text = ""
		if l.text != shown:
			l.text = shown
			l.reset_size()
		var at := sp - Vector2(l.size.x * 0.5, l.size.y)  # keep the whole tag on screen, below the top bar
		l.position = Vector2(clampf(at.x, 4.0, size.x - l.size.x - 4.0), clampf(at.y, 46.0, size.y - l.size.y - 4.0))
	for i in range(n, _labels.size()):
		_labels[i].visible = false


static func _arrow(d: Vector2) -> String:
	var a := atan2(d.y, d.x)
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[posmod(roundi(a / (PI / 4.0)), 8)]
