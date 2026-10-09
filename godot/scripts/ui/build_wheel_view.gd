class_name BuildWheelView
extends Control
## Radial build-selection wheel (first person). Pure renderer for fps/BuildWheel:
## draws the pie segments with _draw, mirrors center/radius back to the logic so
## hit-testing matches what is on screen. Clicks are read from InputState by the
## logic (mouse_filter IGNORE), so no Control input handling here.

var wheel: BuildWheel

const DIM_BG := Color(0, 0, 0, 0.55)
const SEG := Color(0.05, 0.08, 0.12, 0.92)
const SEG_HOVER := Color(0.14, 0.21, 0.29, 0.97)
const EDGE := Color(0.37, 0.83, 1.0, 0.35)
const EDGE_HOVER := Color(0.37, 0.83, 1.0, 0.9)


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_dt: float) -> void:
	var show := wheel != null and wheel.is_open()
	visible = show
	if not show:
		return
	wheel.center = size * 0.5
	wheel.radius = minf(BuildWheel.RADIUS, minf(size.x, size.y) * 0.5 - 70.0)
	queue_redraw()


func _draw() -> void:
	if wheel == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), DIM_BG)
	var n := wheel.segment_count()
	if n <= 0:
		return
	var c := wheel.center
	var r := wheel.radius
	for i in n:
		var a0 := -PI * 0.5 + TAU * i / n
		var a1 := -PI * 0.5 + TAU * (i + 1) / n
		var pts := PackedVector2Array([c])
		var steps := 24
		for s in steps + 1:
			var a := lerpf(a0, a1, float(s) / steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		var hov := i == wheel.hover
		draw_colored_polygon(pts, SEG_HOVER if hov else SEG)
		draw_arc(c, r, a0, a1, 24, EDGE_HOVER if hov else EDGE, 2.0 if hov else 1.0, true)
		# separator spokes
		var sp := c + Vector2(cos(a0), sin(a0)) * r
		draw_line(c + Vector2(cos(a0), sin(a0)) * BuildWheel.INNER, sp, EDGE, 1.0)
		_draw_label(font, c, r, i, n, hov)
	# inner disc + title
	draw_circle(c, BuildWheel.INNER, Color(0.04, 0.06, 0.09, 0.95))
	draw_arc(c, BuildWheel.INNER, 0, TAU, 48, EDGE, 1.0, true)
	var title := "BUILD"
	if wheel.items_open and wheel.tab < StructureDefs.TABS.size():
		title = String(StructureDefs.TABS[wheel.tab]).to_upper()
	_center_text(font, title, c + Vector2(0, -8), 18, UiKit.TEXT)
	_center_text(font, "click to pick", c + Vector2(0, 14), 12, UiKit.DIM)
	_center_text(font, "Esc / right-click closes", Vector2(size.x * 0.5, size.y - 28), 13, UiKit.DIM)


func _seg_label(i: int) -> String:
	if not wheel.items_open:
		return String(StructureDefs.TABS[i])
	var list := wheel.item_list()
	if i < list.size():
		return "%s\n%s" % [wheel.item_label(String(list[i])), wheel.item_cost(String(list[i]))]
	return ""


func _draw_label(font: Font, c: Vector2, r: float, i: int, n: int, hov: bool) -> void:
	var mid := -PI * 0.5 + TAU * (i + 0.5) / n
	var pos := c + Vector2(cos(mid), sin(mid)) * (r * 0.62)
	var lines := _seg_label(i).split("\n")
	var y := pos.y - (lines.size() - 1) * 9.0
	for li in lines.size():
		var col := UiKit.TEXT if li == 0 else UiKit.WARN
		if hov and li == 0:
			col = Color("eaf6ff")
		_center_text(font, lines[li], Vector2(pos.x, y + li * 18.0), 15 if li == 0 else 13, col)


func _center_text(font: Font, text: String, pos: Vector2, px: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(font, pos + Vector2(-w * 0.5, px * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
