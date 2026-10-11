class_name SmokeBuildMenu
extends RefCounted
## The build menu's tip line reserves its tallest text, so hovering never resizes the panel.


static func run(g) -> void:
	var m := BuildMenu.new()
	g.add_child(m)
	m.level = g.level.data if "data" in g.level else {}
	m.size = m.get_combined_minimum_size()
	m.notification(Container.NOTIFICATION_SORT_CHILDREN)
	m.get_child(0).notification(Container.NOTIFICATION_SORT_CHILDREN)
	var base := m.get_combined_minimum_size()
	var bad := 0
	var worst := 0.0
	var tip: Label = m._tip
	for t in StructureDefs.TABS:
		for item in StructureDefs.MENU[t]:
			tip.text = m.tip_text(item)
			worst = maxf(worst, tip.get_minimum_size().y)
			if m.get_combined_minimum_size() != base:
				bad += 1
	tip.text = BuildMenu.HINT
	SmokeTest._check("build menu: hover never resizes the panel", bad == 0 and m.get_combined_minimum_size() == base,
		"(%d resized, tip min h %.0f, tallest text %.0f)" % [bad, tip.custom_minimum_size.y, worst])
	m.queue_free()
