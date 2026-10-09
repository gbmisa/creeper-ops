class_name TopBar
extends PanelContainer
## CW3-style economy readout as a strip of captioned gauges:
##   ENERGY bank bar · ORE · SALVAGE · NET /s (green production over red demand) · status alert
##   ... ÆTHER · CASTLES · PACKETS · FIELD · UNITS · CREEPER · THREAT · NODE hp bar · mission clock.
## Status shows unmet demand (starving), "bank full" when income is wasted, landing and Operative down.

var energy_bar: ProgressBar
var energy_lbl: Label
var ore_lbl: Label
var salvage_lbl: Label
var prod_lbl: Label
var demand_lbl: Label
var status_lbl: Label
var _status_box: PanelContainer
var _chips := {}  # caption -> value Label
var node_bar: ProgressBar
var node_lbl: Label
var time_lbl: Label
var speed_lbl: Label


func _init() -> void:
	var sb := UiTheme.box(UiKit.BG_SOLID, UiKit.EDGE, 0, 0)
	sb.border_width_bottom = 2
	sb.border_color = Color(UiKit.ACCENT, 0.7)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("panel", sb)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(11)
	add_child(row)
	var e := _gauge(row, "Energy")
	var er := UiKit.hbox(8)
	energy_bar = UiKit.bar(150, 12, UiKit.ENERGY)
	energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	er.add_child(energy_bar)
	energy_lbl = UiKit.mono("0/0", 18)
	energy_lbl.custom_minimum_size.x = 82
	er.add_child(energy_lbl)
	e.add_child(er)
	row.add_child(_sep())
	ore_lbl = _value(row, "Ore", UiKit.WARN, 70)
	salvage_lbl = _value(row, "Salvage", UiKit.GOOD, 70)
	row.add_child(_sep())
	var net := _gauge(row, "Net /s")
	var nr := UiKit.hbox(8)
	prod_lbl = UiKit.mono("+0.0", 18, UiKit.GOOD)
	demand_lbl = UiKit.mono("-0.0", 18, UiKit.BAD)
	nr.add_child(prod_lbl)
	nr.add_child(demand_lbl)
	net.add_child(nr)
	_status_box = PanelContainer.new()
	_status_box.add_theme_stylebox_override("panel", UiTheme.box(Color(UiKit.WARN, 0.12), Color(UiKit.WARN, 0.6), 1, 4))
	_status_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_lbl = UiKit.label("", 15, UiKit.WARN)
	status_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_lbl.custom_minimum_size.x = 60
	status_lbl.clip_text = true
	_status_box.add_child(status_lbl)
	var mid := Control.new()  # the status chip floats left in whatever width is left over
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size.x = 80
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.clip_contents = true
	mid.add_child(_status_box)
	row.add_child(mid)
	for c in ["Æther", "Castles", "Packets", "Field", "Units", "Creeper", "Threat"]:
		_chips[c] = _value(row, c, UiKit.TEXT, 0, 16)
	row.add_child(_sep())
	var n := _gauge(row, "Node")
	var nh := UiKit.hbox(6)
	node_bar = UiKit.bar(70, 8, UiKit.GOOD)
	node_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nh.add_child(node_bar)
	node_lbl = UiKit.mono("", 16)
	nh.add_child(node_lbl)
	n.add_child(nh)
	row.add_child(_sep())
	var t := _gauge(row, "Mission")
	var th := UiKit.hbox(6)
	time_lbl = UiKit.mono("00:00", 20, UiKit.ACCENT)
	th.add_child(time_lbl)
	speed_lbl = UiKit.mono("", 14, UiKit.DIM)
	speed_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	th.add_child(speed_lbl)
	t.add_child(th)


func _sep() -> VSeparator:
	var s := VSeparator.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _gauge(row: HBoxContainer, title: String) -> VBoxContainer:
	var v := UiKit.vbox(0)
	v.add_child(UiKit.caption(title))
	row.add_child(v)
	return v


func _value(row: HBoxContainer, title: String, color: Color, min_w := 0, size := 18) -> Label:
	var l := UiKit.mono("0", size, color)
	l.custom_minimum_size.x = min_w
	_gauge(row, title).add_child(l)
	return l


func _pile(amount: float, rate: float) -> String:
	var tail := "" if absf(rate) < 0.05 else " %+.1f" % rate
	return "%s%s" % [String.num(amount, 1), tail]


func _status(text: String, color: Color) -> void:
	status_lbl.text = text
	status_lbl.add_theme_color_override("font_color", color)
	(_status_box.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(color, 0.13)
	(_status_box.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(color, 0.6)
	_status_box.visible = text != ""
	var mid := _status_box.get_parent() as Control
	var w := status_lbl.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 14.0
	_status_box.position = Vector2(0, maxf(0.0, (mid.size.y - _status_box.get_combined_minimum_size().y) * 0.5))
	_status_box.size = Vector2(minf(w, mid.size.x), _status_box.get_combined_minimum_size().y)


func refresh(g) -> void:
	var eco: Economy = g.economy
	var pk: Packets = g.structures.packets
	energy_bar.value = eco.energy / eco.max_energy
	energy_lbl.text = "%d/%d" % [floori(eco.energy), eco.max_energy]
	ore_lbl.text = _pile(g.stockpile.ore, g.stockpile.ore_rate)
	salvage_lbl.text = _pile(g.stockpile.salvage, g.stockpile.salvage_rate)
	prod_lbl.text = "+%.1f" % eco.income
	demand_lbl.text = "-%.1f" % pk.demand_rate
	if g.landing:
		_status("Choose a landing site for the Command Node", UiKit.ENERGY)
	elif g.deploy.down:
		_status("Operative down: %s" % g.deploy.status_text(), UiKit.BAD)
	elif pk.unmet_rate > 0.15:
		_status("STARVING  %.1f/s of requests unpaid" % pk.unmet_rate, UiKit.BAD)
	elif eco.wasted > 0.1:
		_status("BANK FULL  %.1f/s wasted. Build or store more." % eco.wasted, UiKit.WARN)
	else:
		_status("", UiKit.WARN)
	var nests: SporeNests = g.hazards.nests
	var pressure := roundi(nests.pressure() * 100.0)
	var air := "  AIR %d" % nests.flyers.count() if nests.flyers.count() > 0 else ""
	_chips["Æther"].text = str(Upgrades.aether)
	_chips["Castles"].text = str(g.castles.held())
	_chips["Packets"].text = str(pk.count())
	_chips["Field"].text = str(eco.field_cells)
	_chips["Units"].text = str(g.units.list.size())
	_chips["Creeper"].text = "%d%%" % roundi(g.surface.creeper.coverage() * 100.0)
	_chips["Threat"].text = ("%s %d%%%s" % [RaiderDefs.newest(nests.pressure()).name, pressure, air]) if nests.alive_count() > 0 else "clear"
	_chips["Threat"].add_theme_color_override("font_color", UiKit.BAD if pressure >= 70 else (UiKit.WARN if pressure >= 35 else UiKit.TEXT))
	var node: Structure = g.structures.command_node()
	var hp: float = node.hp / node.def.hp if node else 0.0
	node_bar.value = maxf(0.0, hp)
	UiKit.set_bar_color(node_bar, UiKit.BAD if hp < 0.35 else (UiKit.WARN if hp < 0.7 else UiKit.GOOD))
	node_lbl.text = "%d%%" % roundi(maxf(0.0, hp) * 100.0) if node or not g.landing else "orbit"
	node_lbl.add_theme_color_override("font_color", UiKit.BAD if hp < 0.35 else (UiKit.WARN if hp < 0.7 else UiKit.TEXT))
	var t: float = g.time
	time_lbl.text = "%02d:%02d" % [floori(t / 60.0), floori(fmod(t, 60.0))]
	speed_lbl.text = "PAUSED" if g.paused else "%dx" % g.speed
	speed_lbl.add_theme_color_override("font_color", UiKit.WARN if g.paused else UiKit.DIM)
