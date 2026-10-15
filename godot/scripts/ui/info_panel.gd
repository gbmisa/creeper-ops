class_name InfoPanel
extends PanelContainer
## Right-side panel for the current selection: stats, supply state, and the CW3 action
## buttons (Move, Supply on/off, Hold fire, Recycle) plus barracks training and Forge upgrades.

var command: CommandMode
var units: UnitManager
var stockpile: Stockpile
var _title: Label
var _hp_row: HBoxContainer
var _hp_lbl: Label
var _hp_bar: ProgressBar
var _body: RichTextLabel
var _actions: HFlowContainer


func setup(cm: CommandMode, um: UnitManager) -> void:
	command = cm
	units = um
	add_theme_stylebox_override("panel", UiKit.style(UiKit.BG, UiKit.EDGE, 1, 10))
	UiKit.brackets(self)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	offset_left = -330
	offset_right = -10
	offset_top = 64
	var v := UiKit.vbox(6)
	add_child(v)
	var head := UiKit.header("", 20, UiKit.TEXT)
	_title = head.get_node("Text")
	v.add_child(head)
	_hp_row = UiKit.hbox(8)
	_hp_lbl = UiKit.mono("", 14)
	_hp_row.add_child(_hp_lbl)
	_hp_bar = UiKit.bar(170, 10, UiKit.GOOD)
	_hp_row.add_child(_hp_bar)
	v.add_child(_hp_row)
	_body = UiKit.rich(15)
	_body.custom_minimum_size.x = 300
	v.add_child(_body)
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("h_separation", 4)
	_actions.add_theme_constant_override("v_separation", 4)
	v.add_child(_actions)
	Bus.selection_changed.connect(_rebuild_actions)
	visible = false


func _btn(text: String, cb: Callable) -> void:
	_actions.add_child(UiKit.button(text, cb, 14))


func _rebuild_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()
	var s := command.selected
	if s == null:
		return
	if (s.type == "beacon" or s.type == "node") and s.is_built() and not s.is_flying():
		_btn("Deploy here [%s]" % Keybinds.short("teleport"), command.deploy.deploy_totem)
	if s.def.get("movable", false):
		_btn("Move [%s]" % Keybinds.short("move"), command.begin_move)
	if s.type != "node":
		_btn("%s [%s]" % ["Deactivate" if s.active else "Activate", Keybinds.short("supply")], command.toggle_supply)
	if s.def.has("fire_rate"):
		_btn("Hold fire %s [%s]" % ["ON" if s.hold_fire else "OFF", Keybinds.short("hold_fire")], command.toggle_hold)
	if s.type == "barracks":
		var mine := units.living_for(s)
		_btn("Select its units (%d)" % mine, func(): CommandSelect.select_units(command, s))
		_btn("Select all units [%s]" % Keybinds.short("select_units"), func(): CommandSelect.select_units(command, null))
		for t in UnitDefs.ORDER:
			var d: Dictionary = UnitDefs.DEFS[t]
			_btn("Train %s (%d) [%s]" % [d.label, d.cost, Keybinds.short(UnitDefs.KEYS[t])], func(): command.train(t))
	if s.type == "forge":
		for id in Upgrades.ORDER:
			var d: Dictionary = Upgrades.DEFS[id]
			var txt := "%s %d/%d: MAX" % [d.label, Upgrades.level(id), d.max] if Upgrades.maxed(id) \
				else "%s %d→%d (%d Æ)" % [d.label, Upgrades.level(id), Upgrades.level(id) + 1, Upgrades.cost(id)]
			_btn(txt, func(): _buy(id))
	if s.type == "node" and stockpile != null:
		ArmouryMenu.add_rows(_actions, stockpile, _rebuild_actions)
	if s.type != "node":
		_btn("Recycle [%s]" % Keybinds.short("recycle"), command.recycle_selected)


func _buy(id: String) -> void:
	var f := command.selected
	var why := Upgrades.buy(id, f != null and f.type == "forge" and f.is_built() and f.connected)
	if why == "":
		Sfx.play("good")
		Bus.say("Forge: %s is now level %d." % [Upgrades.DEFS[id].label, Upgrades.level(id)], "good")
	else:
		Bus.say(why, "warn")
		Sfx.play("deny")
	_rebuild_actions()


func refresh() -> void:
	var s := command.selected
	if s:
		visible = true
		var more: int = command.group.size() - 1
		_title.text = s.def.label if more <= 0 else "%s + %d more selected" % [s.def.label, more]
		_hp_row.visible = true
		var frac := clampf(s.hp / s.def.hp, 0.0, 1.0)
		_hp_bar.value = frac
		UiKit.set_bar_color(_hp_bar, UiKit.BAD if frac < 0.35 else (UiKit.WARN if frac < 0.7 else UiKit.GOOD))
		_hp_lbl.text = "HP %d / %d" % [ceili(s.hp), s.def.hp]
		_body.text = _structure_text(s)
		return
	var ei := EnemyRangeView.info(command)
	if not ei.is_empty():
		visible = true
		_hp_row.visible = true
		_title.text = ei.title
		_hp_bar.value = ei.frac
		UiKit.set_bar_color(_hp_bar, UiKit.BAD)
		_hp_lbl.text = ei.hp
		_body.text = ei.body
		for c in _actions.get_children():
			c.queue_free()
		return
	if not units.selected.is_empty():
		visible = true
		_hp_row.visible = false
		_title.text = "%d unit%s selected" % [units.selected.size(), "" if units.selected.size() == 1 else "s"]
		_body.text = _units_text()
		for c in _actions.get_children():
			c.queue_free()
		return
	visible = false


func _structure_text(s: Structure) -> String:
	var lines := []
	if not s.is_built():
		lines.append("[color=#5fd4ff]Building: %d / %d packets[/color]" % [s.delivered - s.lost, s.def.cost])
	if not s.active:
		lines.append("[color=#ffc857]DEACTIVATED: requests no packets, does nothing [%s][/color]" % Keybinds.short("supply"))
	if s.is_flying():
		lines.append("[color=#ffc857]In flight: no packets, no firing[/color]")
	elif not s.connected:
		lines.append("[color=#ff5a4a]NOT CONNECTED: no packets reach it[/color]")
	if s.has_ammo_store():
		var what := "Supply stock" if s.type == "barracks" else "Ammo"
		lines.append("%s %d / %d%s" % [what, floori(s.ammo), s.ammo_max(), "" if s.active else "  [color=#ffc857](deactivated)[/color]"])
	if AmmoGrades.has_grades(s):
		var gl := AmmoDefs.label(s.grade)
		lines.append("Ammo grade: %s%s  [color=#8899aa](%s switches%s)[/color]" % [gl, "" if s.grade == "std" else " (%d graded)" % roundi(s.grade_ammo),
			"/".join([Keybinds.short("ammo_next"), Keybinds.short("ammo_prev")]), "" if AmmoGrades.unlocked else "; locked"])
	if s.hold_fire:
		lines.append("[color=#ffc857]Holding fire[/color]")
	if s.type == "forge":
		lines.append("[color=#d38cff]Aether: %d[/color]" % Upgrades.aether)
	if s.type == "miner" and command.structures.deposits != null:
		var vein: Dictionary = command.structures.deposits.ore_at(s.x, s.z)
		var left := 0.0 if vein.is_empty() else float(vein.left)
		lines.append("Vein %d left    stored %d / %d" % [int(left), int(s.ore_hold), int(Config.MINER_BUFFER)])
	if s.type == "node" and stockpile != null:
		lines.append("[color=#ffc857]Salvage: %s[/color]" % String.num(stockpile.salvage, 1))
	if s.type == "barracks":
		lines.append("Units %d / %d" % [units.living_for(s), Config.UNITS_PER_BARRACKS])
		for q in s.queue:
			lines.append("  queued %s: %d/%d packets" % [UnitDefs.DEFS[q.type].label, q.delivered, q.cost])
		lines.append("Right-click ground: rally point")
	elif s.def.get("movable", false):
		lines.append("Right-click ground: fly there")
	if s.wet > Config.MIN_DEPTH:
		lines.append("[color=#ff5a4a]Under creeper: %s[/color]" % ("taking damage" if s.is_built() else "losing build progress"))
	lines.append("[color=#8899aa]%s[/color]" % s.def.desc)
	return "\n".join(lines)


func _units_text() -> String:
	var lines := []
	for u in units.selected.slice(0, 8):
		var st := { "idle": "holding", "move": "moving", "resupply": "returning to resupply", "return": "returning to post", "patrol": "patrolling" }
		lines.append("%s  HP %d  Ammo %d/%d  %s" % [u.def.label, ceili(u.hp), roundi(u.ammo), u.def.ammo, st.get(u.state, u.state)])
	lines.append("[color=#8899aa]Right-click to move, [%s] to set a patrol route. Units run dry and walk home to restock.[/color]" % Keybinds.short("patrol"))
	return "\n".join(lines)
