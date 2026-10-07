class_name TopBar
extends PanelContainer
## CW3-style economy readout. Energy bank bar, then the numbers that matter:
##   green  = production (energy/packets generated per second)
##   red    = demand (packets structures are asking for per second)
##   unmet  = demand the bank couldn't pay (starving), or "bank full" when income is wasted
## plus packets in the air, claimed field, units, creeper cover, Node health, clock, speed.

var energy_bar: ProgressBar
var energy_lbl: Label
var ore_lbl: Label
var salvage_lbl: Label
var prod_lbl: Label
var demand_lbl: Label
var status_lbl: Label
var stats_lbl: Label
var node_lbl: Label
var time_lbl: Label


func _init() -> void:
	add_theme_stylebox_override("panel", UiKit.style(UiKit.BG, UiKit.EDGE, 0, 6))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(18)
	add_child(row)
	var e := UiKit.vbox(2)
	e.add_child(UiKit.label("ENERGY", 11, UiKit.DIM))
	energy_bar = UiKit.bar(220, 14, UiKit.ENERGY)
	e.add_child(energy_bar)
	row.add_child(e)
	energy_lbl = UiKit.label("0 / 0", 18)
	energy_lbl.custom_minimum_size.x = 90
	row.add_child(energy_lbl)
	ore_lbl = UiKit.label("Ore 0", 16, UiKit.WARN)
	row.add_child(ore_lbl)
	salvage_lbl = UiKit.label("Salvage 0", 16, UiKit.GOOD)
	row.add_child(salvage_lbl)
	prod_lbl = _stat(row, "PRODUCTION /s", UiKit.GOOD)
	demand_lbl = _stat(row, "DEMAND /s", UiKit.BAD)
	status_lbl = UiKit.label("", 14, UiKit.WARN)
	status_lbl.custom_minimum_size.x = 260
	row.add_child(status_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	stats_lbl = UiKit.label("", 14, UiKit.TEXT)
	row.add_child(stats_lbl)
	node_lbl = UiKit.label("", 16)
	row.add_child(node_lbl)
	time_lbl = UiKit.label("", 16)
	row.add_child(time_lbl)


func _stat(row: HBoxContainer, title: String, color: Color) -> Label:
	var v := UiKit.vbox(0)
	v.add_child(UiKit.label(title, 11, UiKit.DIM))
	var l := UiKit.label("0.0", 18, color)
	v.add_child(l)
	row.add_child(v)
	return l


func refresh(g) -> void:
	var eco: Economy = g.economy
	var pk: Packets = g.structures.packets
	energy_bar.value = eco.energy / eco.max_energy
	energy_lbl.text = "%d / %d" % [floori(eco.energy), eco.max_energy]
	ore_lbl.text = "Ore %s" % String.num(g.stockpile.ore, 1)
	salvage_lbl.text = "Salvage %s" % String.num(g.stockpile.salvage, 1)
	prod_lbl.text = "+%.1f" % eco.income
	demand_lbl.text = "-%.1f" % pk.demand_rate
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
	var held: int = g.towers.reduce(func(a, t): return a + t.held(), 0)
	var nests: SporeNests = g.hazards.nests
	var threat := "Nests: %s" % Config.RAIDER_TIERS[nests.tier].name if nests.alive_count() > 0 else "Nests: none"
	stats_lbl.text = "Æther %d (%d towers)   Packets %d   Field %d   Units %d   Creeper %d%%   %s" % [Upgrades.aether, held,
		pk.count(), eco.field_cells, g.units.list.size(), roundi(g.surface.creeper.coverage() * 100.0), threat]
	var node: Structure = g.structures.command_node()
	var hp: float = node.hp / node.def.hp if node else 0.0
	node_lbl.text = "Node %d%%" % roundi(maxf(0.0, hp) * 100.0) if node or not g.landing else "Node: in orbit"
	node_lbl.add_theme_color_override("font_color", UiKit.BAD if hp < 0.35 else (UiKit.WARN if hp < 0.7 else UiKit.TEXT))
	var t: float = g.time
	var spd := "PAUSED" if g.paused else "%dx" % g.speed
	time_lbl.text = "%02d:%02d  %s" % [floori(t / 60.0), floori(fmod(t, 60.0)), spd]
