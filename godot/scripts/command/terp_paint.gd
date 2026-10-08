class_name TerpPaint
extends RefCounted
## Command paint for the Terp. Drag a rectangle of target levels (whole levels, 0..MAX_LEVEL).
## The target starts at the first cell; terp_up / terp_down change it; hold terp_erase to clear.
## Painted cells are a hatched tint on the terrain shader (raise and lower are different colours).

var world: World
var level := 0
var pinned := false
var dragging := false
var anchor := Vector2i(-1, -1)
var _img: Image
var _tex: ImageTexture
var _bytes := PackedByteArray()


static func attach(w: World) -> TerpPaint:
	var p := TerpPaint.new()
	p.world = w
	var n := w.grid.w * w.grid.h
	p._bytes.resize(n * 2)
	p._img = Image.create_from_data(w.grid.w, w.grid.h, false, Image.FORMAT_RG8, p._bytes)
	p._tex = ImageTexture.create_from_image(p._img)
	w.terrain_mat.set_shader_parameter("terp_tex", p._tex)
	w.set_meta("terp_tint", p)
	Bus.terrain_changed.connect(p._on_terrain)
	return p


func _on_terrain(w: World, _cells: Array) -> void:
	if w == world:
		sync()


func cancel() -> void:
	dragging = false
	pinned = false


func begin(cm: CommandMode) -> void:
	anchor = cm.hover.cell
	dragging = true
	if not pinned:
		level = _ground(cm.world.grid, anchor)


func nudge(cm: CommandMode, dir: int) -> void:
	if not pinned:
		var cell: Vector2i = anchor if dragging else (cm.hover.cell if not cm.hover.is_empty() else anchor)
		if cm.world.grid.in_bounds(cell.x, cell.y):
			level = _ground(cm.world.grid, cell)
	pinned = true
	level = clampi(level + dir, 0, Config.MAX_LEVEL)


## Writes the rectangle from anchor to `to`. Returns the first refusal, if any.
func commit(cm: CommandMode, to: Vector2i, erase: bool) -> String:
	dragging = false
	var why := _fill(anchor, to, erase)
	pinned = false
	return why


func shown_level(cm: CommandMode) -> int:
	if pinned or dragging:
		return level
	if cm.hover.is_empty():
		return level
	return _ground(cm.world.grid, cm.hover.cell)


func hover_text(cm: CommandMode) -> String:
	var text := "Terp target level %d (%s / %s, hold %s to erase)" % [shown_level(cm),
		Keybinds.short("terp_up"), Keybinds.short("terp_down"), Keybinds.short("terp_erase")]
	if cm.hover.is_empty():
		return text
	var why := cell_reason(cm.world.grid, cm.hover.cell)
	return text if why == "" else "%s — %s" % [text, why]


static func pointer(cm: CommandMode, input: InputState) -> void:
	var paint: TerpPaint = cm.overlay.paint
	if input.left_pressed and not cm.hover.is_empty():
		paint.begin(cm)
	if paint.dragging and input.left:
		cm.drag_rect = Rect2(input.down_pos, input.mouse - input.down_pos).abs()
	else:
		cm.drag_rect = Rect2()
	if input.left_released and paint.dragging:
		var to: Vector2i = cm.hover.cell if not cm.hover.is_empty() else paint.anchor
		paint.commit(cm, to, input.held("terp_erase"))
		cm.drag_rect = Rect2()


static func debug_scene(g, args: Dictionary) -> void:
	var paint: TerpPaint = g.surface.get_meta("terp_tint")
	if args.has("paint"):
		var p := str(args.paint).split(",")
		if p.size() >= 5:
			paint.level = clampi(int(p[4]), 0, Config.MAX_LEVEL)
			paint.pinned = true
			paint.anchor = Vector2i(int(p[0]), int(p[1]))
			paint.commit(g.command, Vector2i(int(p[2]), int(p[3])), false)
	if args.has("terp"):
		var t := str(args.terp).split(",")
		if t.size() >= 2:
			g.economy.energy = maxf(g.economy.energy, 500.0)
			g.structures.place("terp", int(t[0]), int(t[1]), true)


## Why this cell cannot be painted, or "". Occupied cells are allowed; the Terp skips them.
static func cell_reason(g: Grid, c: Vector2i) -> String:
	if not g.in_bounds(c.x, c.y):
		return "Out of bounds"
	var i := g.idx(c.x, c.y)
	if g.material[i] == Grid.Mat.SPIRE:
		return "Spire: indestructible, the Terp can't paint it"
	if g.gate[i] != Grid.Faction.NONE:
		return "Gate: the Terp can't reshape a gate"
	if g.material[i] == Grid.Mat.STONE or g.material[i] == Grid.Mat.PLATED:
		return "Castle stone: the Terp can't reshape it"
	if g.zone[i] == Grid.Zone.BLIGHT:
		return "Blight zone: the Terp can't paint here"
	return ""


func sync() -> void:
	var g := world.grid
	_bytes.fill(0)
	for z in g.h:
		for x in g.w:
			var i := g.idx(x, z)
			var target := g.terp_target[i]
			if target < 0.0:
				continue
			var o := i * 2
			if target > g.height[i] + 0.001:
				_bytes[o] = 255
			elif target < g.height[i] - 0.001:
				_bytes[o + 1] = 255
	_img.set_data(g.w, g.h, false, Image.FORMAT_RG8, _bytes)
	_tex.update(_img)


func _fill(a: Vector2i, b: Vector2i, erase: bool) -> String:
	var g := world.grid
	var why := ""
	var x0 := mini(a.x, b.x)
	var x1 := maxi(a.x, b.x)
	var z0 := mini(a.y, b.y)
	var z1 := maxi(a.y, b.y)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var c := Vector2i(x, z)
			if erase:
				if g.in_bounds(x, z):
					var i := g.idx(x, z)
					g.terp_target[i] = -1.0
					g.terp_mat[i] = 0
				continue
			var reason := cell_reason(g, c)
			if reason != "":
				if why == "":
					why = reason
				continue
			var i := g.idx(x, z)
			g.terp_target[i] = float(level)
			g.terp_mat[i] = Grid.Mat.EARTH  # 11b: the paint tool picks Metal here
	if why != "" and not erase:
		Bus.say(why, "warn")
	sync()
	return why


static func _ground(g: Grid, c: Vector2i) -> int:
	if not g.in_bounds(c.x, c.y):
		return 0
	return clampi(int(round(g.height_at(c.x, c.y))), 0, Config.MAX_LEVEL)
