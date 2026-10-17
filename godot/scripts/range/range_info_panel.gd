class_name RangeInfoPanel
extends CanvasLayer
## F115: the range's reference text in one screen panel instead of floating labels: every rack gun (name, tier,
## role; rows as on the rack) and the penetration wall panels left to right. Shown beside the inventory while it
## was opened at the workbench (RangeWorkbench).

const WIDTH := 380.0


func _init() -> void:
	layer = 9
	visible = false
	var p := UiKit.panel()
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = -WIDTH - 16.0
	p.offset_right = -16.0
	p.offset_top = 16.0
	p.offset_bottom = -16.0
	add_child(p)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	sc.add_child(box)
	box.add_child(UiKit.header("WEAPON RACK"))
	for row in RangeRack.GRID:
		for id in row:
			if id != "":
				_gun(box, WeaponDefs.of(id))
	box.add_child(UiKit.header("PENETRATION WALL (left to right)"))
	for w in RangeTargets.WALL:
		box.add_child(UiKit.mono("%s  %d cm" % [String(w[0]).replace("_", " "), roundi(float(w[1]) * 100.0)], 14))


static func _gun(box: VBoxContainer, def: Dictionary) -> void:
	box.add_child(UiKit.label("%s  [T%d]" % [def["name"], def["tier"]], 16, UiKit.ACCENT_HI))
	var role := UiKit.label(def["role"], 13, UiKit.DIM)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role.custom_minimum_size.x = WIDTH - 40.0
	box.add_child(role)
