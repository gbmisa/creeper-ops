class_name SmokeAmmo
## Stage 9b P3 (design 5.3): improved ammo is locked until its milestone, Ctrl + wheel switches
## grade without colliding with another bind, AP ignores a Warden's aura and hits armour harder,
## incendiary scorches the impact cell, Salvage is charged per packet / per round / per rocket.


static func run(g) -> void:
	_locked(g)
	_keys(g)
	_effects(g)
	_costs(g)
	_structures(g)


static func _locked(g) -> void:
	AmmoGrades.reset(g.level)
	SmokeTest._check("ammo: level 1 names its unlock objective", AmmoGrades.unlock_id == "e1")
	SmokeTest._check("ammo: locked before the milestone", not AmmoGrades.unlocked and AmmoGrades.cycle_op("rifle", 1) == "std"
		and AmmoGrades.op.rifle == "std")
	var sn: Structure = g.structures.place("sniper", 30, 80, true)
	SmokeTest._check("ammo: a locked Sniper refuses a grade", AmmoGrades.cycle_structure(sn, 1) == "std")
	g.structures.remove(sn)
	Bus.objective_done.emit("e1")
	SmokeTest._check("ammo: unlocks when the objective completes", AmmoGrades.unlocked)
	SmokeTest._check("ammo: the rifle cycles standard, AP, incendiary", AmmoGrades.cycle_op("rifle", 1) == "ap"
		and AmmoGrades.cycle_op("rifle", 1) == "inc" and AmmoGrades.cycle_op("rifle", 1) == "std")
	SmokeTest._check("ammo: rockets cycle standard and cluster only", AmmoGrades.cycle_op("rocket", 1) == "cluster"
		and AmmoGrades.cycle_op("rocket", 1) == "std")
	AmmoGrades.cycle_op("rifle", -1)
	SmokeTest._check("ammo: the previous grade wraps to incendiary", AmmoGrades.op.rifle == "inc")
	AmmoGrades.op.rifle = "std"


static func _keys(g) -> void:
	var next: Array = Keybinds.DEFAULTS.ammo_next[2]
	var prev: Array = Keybinds.DEFAULTS.ammo_prev[2]
	var clash := false
	for id in Keybinds.DEFAULTS:
		if id == "ammo_next" or id == "ammo_prev":
			continue
		for k in Keybinds.DEFAULTS[id][2]:
			clash = clash or next.has(k) or prev.has(k)
	SmokeTest._check("ammo: keybind defaults do not collide", not clash and next != prev and Keybinds.matches("ammo_next", Keybinds.CTRL_WHEEL_DOWN))
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_UP
	ev.pressed = true
	ev.ctrl_pressed = true
	g.input._unhandled_input(ev)
	SmokeTest._check("ammo: Ctrl + wheel presses the action and does not zoom", g.input.act("ammo_prev") and g.input.wheel == 0.0)
	g.input.end_frame()
	var plain := InputEventMouseButton.new()
	plain.button_index = MOUSE_BUTTON_WHEEL_UP
	plain.pressed = true
	g.input._unhandled_input(plain)
	SmokeTest._check("ammo: a plain wheel still zooms", g.input.wheel < 0.0 and not g.input.act("ammo_prev"))
	g.input.end_frame()
	SmokeTest._check("ammo: the chord has a readable name", Keybinds.short("ammo_next") == "Ctrl+Wheel Down")


static func _spawn(g, tier: String, at: Vector3) -> Dictionary:
	var nests: SporeNests = g.hazards.nests
	var hive: Dictionary = nests.nests[0]
	nests.raiders.spawn(hive, RaiderDefs.named(tier), true)
	var r: Dictionary = nests.raiders.list.back()
	(r.node as Node3D).position = at
	return r


static func _effects(g) -> void:
	var raiders: Raiders = g.hazards.nests.raiders
	for r in raiders.list.duplicate():
		raiders.kill(r)
	var at: Vector3 = g.level.grid.cell_ground(60, 76)
	var brute := _spawn(g, "Brute", at)
	var warden := _spawn(g, "Warden", at + Vector3(2, 0, 0))
	var hp0: float = brute.hp
	AmmoGrades.shoot(brute.enemy, 1.0, "std", g.surface, at)
	var std_d: float = hp0 - brute.hp
	hp0 = brute.hp
	AmmoGrades.shoot(brute.enemy, 1.0, "ap", g.surface, at)
	var ap_d: float = hp0 - brute.hp
	SmokeTest._check("ammo: a Warden's aura halves standard rounds", is_equal_approx(std_d, 0.5), str(std_d))
	SmokeTest._check("ammo: AP ignores the Warden shield and hits armour +60%", is_equal_approx(ap_d, 1.6), str(ap_d))
	var sk := _spawn(g, "Skitter", at + Vector3(30, 0, 0))
	hp0 = sk.hp
	AmmoGrades.shoot(sk.enemy, 0.0, "ap", g.surface, at)
	SmokeTest._check("ammo: AP has no bonus on light targets", is_equal_approx(sk.hp, hp0))
	raiders.kill(warden)
	hp0 = brute.hp
	AmmoGrades.shoot(brute.enemy, 1.0, "inc", g.surface, at)
	for i in 70:
		AmmoGrades.tick(0.05)
	SmokeTest._check("ammo: incendiary burns 2 dps for 3 s", absf((hp0 - brute.hp) - 7.0) < 0.2 or absf((hp0 - brute.hp) - 7.0) < 0.5, str(hp0 - brute.hp))
	for r in raiders.list.duplicate():
		raiders.kill(r)
	var cell := Vector2i(50, 77)
	g.surface.creeper.set_depth(cell.x, cell.y, 2.5)
	AmmoGrades.impact(g.surface, g.level.grid.cell_ground(cell.x, cell.y), "inc")
	SmokeTest._check("ammo: incendiary removes creeper at the impact cell", is_equal_approx(g.surface.creeper.depth_at(cell.x, cell.y), 1.5),
		str(g.surface.creeper.depth_at(cell.x, cell.y)))
	g.surface.creeper.set_depth(cell.x, cell.y, 0.0)


static func _costs(g) -> void:
	var stock: Stockpile = g.stockpile
	stock.salvage = 10.0
	AmmoGrades.op.rifle = "ap"
	var gr := AmmoGrades.op_shot("rifle", stock)
	SmokeTest._check("ammo: an AP round costs 12 per 30 (0.4)", gr == "ap" and is_equal_approx(stock.salvage, 9.6), str(stock.salvage))
	stock.salvage = 0.1
	SmokeTest._check("ammo: broke, the rifle falls back to standard", AmmoGrades.op_shot("rifle", stock) == "std" and is_equal_approx(stock.salvage, 0.1))
	AmmoGrades.op.rifle = "std"
	AmmoGrades.op.rocket = "cluster"
	stock.salvage = 10.0
	SmokeTest._check("ammo: a cluster rocket costs 15 per 3 (5)", AmmoGrades.op_rocket(stock) and is_equal_approx(stock.salvage, 5.0))
	AmmoGrades.op.rocket = "std"
	var w: World = g.surface
	var centre := Vector2i(44, 80)
	for c in w.grid.cells_in_radius(centre.x, centre.y, 8.0):
		w.creeper.set_depth(c.x, c.y, 3.0)
	var rl := RocketLauncher.new()
	rl._explode(w, w.grid.cell_ground(centre.x, centre.y), true)
	var sub_hits := 0
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var c := centre + Vector2i(roundi(cos(a) * 1.4), roundi(sin(a) * 1.4))
		if w.creeper.depth_at(c.x, c.y) < 2.9:
			sub_hits += 1
	SmokeTest._check("ammo: a cluster rocket bursts in 4 sub-blasts", sub_hits == 4, str(sub_hits))
	for c in w.grid.cells_in_radius(centre.x, centre.y, 8.0):
		w.creeper.set_depth(c.x, c.y, 0.0)
	stock.salvage = 0.0


static func _structures(g) -> void:
	var sm: StructureManager = g.structures
	var node := sm.command_node()
	g.economy.energy = 90.0
	g.stockpile.salvage = 10.0
	var sn: Structure = sm.place("sniper", node.x + 3, node.z + 3, true)
	sn.ammo = 0.0
	AmmoGrades.cycle_structure(sn, 1)
	SmokeTest._check("ammo: command mode selects AP on a Sniper", sn.grade == "ap")
	SmokeTest._sim(g, 6.0)
	var spent: float = 10.0 - g.stockpile.salvage
	var pp: float = sn.def.ammo.per_packet  # rounds per packet: the surcharge is per packet, not per round
	SmokeTest._check("ammo: the surcharge is charged per packet", sn.grade_ammo > 0.0 and spent > 0.0
		and absf(spent - 0.5 * sn.grade_ammo / pp) < 0.01, "(%.1f Salvage for %.0f graded rounds)" % [spent, sn.grade_ammo])
	var taken := AmmoGrades.take_shot(sn)
	SmokeTest._check("ammo: a shot fires the graded round and uses it up", taken == "ap" and sn.grade_ammo < spent * 2.0 * pp)
	AmmoGrades.cycle_structure(sn, 1)
	SmokeTest._check("ammo: a magazine holds one grade (switching drops the rest)", sn.grade == "inc" and sn.grade_ammo == 0.0)
	AmmoGrades.cycle_structure(sn, 1)
	g.stockpile.salvage = 10.0
	sn.ammo = 0.0
	SmokeTest._sim(g, 4.0)
	SmokeTest._check("ammo: standard grade charges nothing", is_equal_approx(g.stockpile.salvage, 10.0) and sn.ammo > 0.0)
	sm.remove(sn)
	var b: Structure = sm.place("barracks", node.x + 5, node.z + 4, true)
	b.grade = "inc"
	b.grade_ammo = 10.0
	var u: Unit = g.units.spawn("soldier", b.pos.x + 2.0, b.pos.z)
	u.ammo = 8.0  # as after the dock handed over 8 rounds
	UnitSupply._take_grade(u, b, 8.0)
	SmokeTest._check("ammo: a docking unit draws graded rounds from the barracks", u.grade == "inc" and is_equal_approx(u.grade_ammo, 8.0)
		and is_equal_approx(b.grade_ammo, 2.0))
	SmokeTest._check("ammo: a unit fires them one by one", UnitSupply._grade_round(u) == "inc" and is_equal_approx(u.grade_ammo, 7.0))
	g.units.kill(u)
	sm.remove(b)
	AmmoGrades.reset(g.level)
	Bus.objective_done.emit("e1")
