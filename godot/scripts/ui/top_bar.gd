class_name TopBar
extends PanelContainer
## Compact left-docked economy/status cluster. All numeric readouts live here, on the
## left side of the screen. Percentages are bars, not numbers; every metric has its own
## color so the panel reads at a glance. Must fit 1280x720 and up.

const CREEP := Color(0.35, 0.62, 1.0)   # creeper coverage: blue
const PRESS := Color(1.0, 0.45, 0.25)   # nest pressure: orange-red
const AETHER := Color(0.83, 0.55, 1.0)  # aether: purple
const RADIO := Color(0.62, 0.83, 1.0)   # packets: pale blue

var energy_bar: ProgressBar
var energy_lbl: Label
var ore_lbl: Label
var salvage_lbl: Label
var aether_lbl: Label
var status_lbl: Label
var node_bar: ProgressBar
var creep_bar: ProgressBar
var press_bar: ProgressBar
var nest_lbl: Label
var prod_lbl: Label
var demand_lbl: Label
var misc_lbl: Label
var time_lbl: Label


func _sep() -> VSeparator:
	var s := VSeparator.new()
	s.add_theme_color_override("separator_color", Color(1, 1, 1, 0.14))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## Caption + bar (+ optional value label) column for one metric.
func _meter(row: HBoxContainer, caption: String, bar_w: float, color: Color, with_value := true) -> Array:
	var v := UiKit.vbox(1)
	v.add_child(UiKit.label(caption, 10, UiKit.DIM))
	var h := UiKit.hbox(6)
	var b := UiKit.bar(bar_w, 10, color)
	h.add_child(b)
	var val: Label = null
	if with_value:
		val = UiKit.label("", 13)
		h.add_child(val)
	v.add_child(h)
	row.add_child(v)
	return [b, val]


func _init() -> void:
	add_theme_stylebox_override("panel", UiKit.style(UiKit.BG, UiKit.EDGE, 0, 6))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(10, 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiKit.vbox(4)
	add_child(v)
	# Row 1: stockpiles + status message.
	var r1 := UiKit.hbox(12)
	v.add_child(r1)
	var em := _meter(r1, "ENERGY", 130, UiKit.ENERGY)
	energy_bar = em[0]
	energy_lbl = em[1]
	r1.add_child(_sep())
	ore_lbl = UiKit.label("", 13, UiKit.WARN)
	r1.add_child(ore_lbl)
	salvage_lbl = UiKit.label("", 13, UiKit.GOOD)
	r1.add_child(salvage_lbl)
	aether_lbl = UiKit.label("", 13, AETHER)
	r1.add_child(aether_lbl)
	r1.add_child(_sep())
	status_lbl = UiKit.label("", 13, UiKit.WARN)
	r1.add_child(status_lbl)
	# Row 2: bars for the percentages + compact counts + clock.
	var r2 := UiKit.hbox(12)
	v.add_child(r2)
	node_bar = _meter(r2, "NODE", 90, UiKit.GOOD, false)[0]
	creep_bar = _meter(r2, "CREEPER", 90, CREEP, false)[0]
	press_bar = _meter(r2, "PRESSURE", 90, PRESS, false)[0]
	nest_lbl = UiKit.label("", 13)
	r2.add_child(nest_lbl)
	r2.add_child(_sep())
	prod_lbl = UiKit.label("", 13, UiKit.GOOD)
	r2.add_child(prod_lbl)
	demand_lbl = UiKit.label("", 13, UiKit.BAD)
	r2.add_child(demand_lbl)
	r2.add_child(_sep())
	misc_lbl = UiKit.label("", 13, UiKit.TEXT)
	r2.add_child(misc_lbl)
	time_lbl = UiKit.label("", 13, UiKit.TEXT)
	r2.add_child(time_lbl)


func _num(amount: float, rate: float) -> String:
	var tail := "" if absf(rate) < 0.05 else " (%+.1f)" % rate
	return "%s%s" % [String.num(amount, 1), tail]


func refresh(g) -> void:
	var eco: Economy = g.economy
	var pk: Packets = g.structures.packets
	energy_bar.value = eco.energy / eco.max_energy
	energy_bar.tooltip_text = "Energy %d / %d" % [floori(eco.energy), eco.max_energy]
	energy_lbl.text = "%d / %d" % [floori(eco.energy), eco.max_energy]
	ore_lbl.text = "Ore %s" % _num(g.stockpile.ore, g.stockpile.ore_rate)
	salvage_lbl.text = "Salvage %s" % _num(g.stockpile.salvage, g.stockpile.salvage_rate)
	aether_lbl.text = "Æther %d" % Upgrades.aether
	if g.landing:
		status_lbl.text = "Choose a landing site for the Command Node"
		status_lbl.add_theme_color_override("font_color", UiKit.ENERGY)
	elif g.deploy.down:
		status_lbl.text = "Operative down — %s" % g.deploy.status_text()
		status_lbl.add_theme_color_override("font_color", UiKit.BAD)
	elif pk.unmet_rate > 0.15:
		status_lbl.text = "STARVING: %.1f/s of requests unpaid" % pk.unmet_rate
		status_lbl.add_theme_color_override("font_color", UiKit.BAD)
	elif eco.wasted > 0.1:
		status_lbl.text = "Bank full: %.1f/s wasted. Build or store more." % eco.wasted
		status_lbl.add_theme_color_override("font_color", UiKit.WARN)
	else:
		status_lbl.text = ""
	var node: Structure = g.structures.command_node()
	var frac := 0.0
	if node:
		frac = clampf(node.hp / node.def.hp, 0.0, 1.0)
	node_bar.value = frac
	UiKit.set_bar_color(node_bar, UiKit.BAD if frac < 0.35 else (UiKit.WARN if frac < 0.7 else UiKit.GOOD))
	node_bar.tooltip_text = "Command Node HP %d%%" % roundi(frac * 100.0) if node or not g.landing else "Node: in orbit"
	var cov := clampf(g.surface.creeper.coverage(), 0.0, 1.0)
	creep_bar.value = cov
	creep_bar.tooltip_text = "Creeper coverage %d%%" % roundi(cov * 100.0)
	var nests: SporeNests = g.hazards.nests
	var pr := clampf(nests.pressure(), 0.0, 1.0)
	press_bar.value = pr
	press_bar.tooltip_text = "Nest pressure %d%%" % roundi(pr * 100.0)
	nest_lbl.text = ("Nests: %s" % RaiderDefs.newest(nests.pressure()).name if nests.alive_count() > 0 else "Nests: none") \
		+ ("  AIR %d" % nests.flyers.count() if nests.flyers.count() > 0 else "")
	prod_lbl.text = "+%.1f/s" % eco.income
	demand_lbl.text = "-%.1f/s" % pk.demand_rate
	misc_lbl.text = "Packets %d · Field %d · Units %d · %d %s" % [pk.count(), eco.field_cells,
		g.units.list.size(), g.castles.held(), "castle" if g.castles.held() == 1 else "castles"]
	var t: float = g.time
	var spd := "PAUSED" if g.paused else "%dx" % g.speed
	time_lbl.text = "%02d:%02d · %s" % [floori(t / 60.0), floori(fmod(t, 60.0)), spd]
