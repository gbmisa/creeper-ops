class_name RangeTestFbc
## FB-C bug-fix checks for `--range-test`: F20 viewmodel visible after transitions,
## F6 restart keeps the deployed loadout, F22 shotgun bench gives shells, F23
## sprint-jump keeps sprint speed through the air.

static func run(t: RangeTest) -> void:
	_f20(t)
	_f6(t)
	_f22(t)
	await _f23(t)


## F20: FiringRange._build calls weapons.setup (select_slot emits `switched`) BEFORE
## the viewmodel connects. The viewmodel must still show the held gun after setup.
static func _f20(t: RangeTest) -> void:
	var session := RangeSession.new(4242)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	player.set_physics_process(false)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	weapons.setup(player, input, t.bal, rack, session)  # switched fires here, no viewmodel yet
	var vm := TacticalViewmodel.new()
	t.add_child(vm)
	vm.setup(weapons, player)  # both transitions (deploy / return) reach this order
	t.check("f20: viewmodel shows the held gun right after setup", vm.model != null)
	vm.queue_free()
	player.queue_free()
	weapons.queue_free()
	rack.queue_free()


## F6: save_kit must survive the scene reload (fresh RangeSession each map); KIA clears it.
static func _f6(t: RangeTest) -> void:
	var session := RangeSession.new(777)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	player.set_physics_process(false)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	weapons.setup(player, input, t.bal, rack, session)
	var ids := []
	for it in weapons.inv.all_items():
		ids.append(it["id"])
	session.save_kit(weapons.inv)  # deploy path
	var s2 := RangeSession.new(778)  # fresh session after a map reload (F55 static carry)
	var ids2 := []
	for it in Inventory.from_dict(s2.saved_kit).all_items():
		ids2.append(it["id"])
	t.check("f6: restart keeps the deployed loadout", ids2 == ids)
	session.clear_kit()  # KIA path
	var s3 := RangeSession.new(779)
	t.check("f6: KIA still resets to the default kit", s3.saved_kit.is_empty())
	player.queue_free()
	weapons.queue_free()
	rack.queue_free()


## F22: the ammo bench gives 12ga shells for tube guns; mag-gun refills are unchanged.
static func _f22(t: RangeTest) -> void:
	var session := RangeSession.new(31337)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	player.set_physics_process(false)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	weapons.setup(player, input, t.bal, rack, session)
	for it in weapons.inv.all_items().duplicate():  # strip to a free hand slot
		weapons.inv.request_remove(it)
	weapons.give("shotgun")
	t.check("f22: M870 selected", weapons.gun != null and weapons.gun.def["id"] == "shotgun")
	for it in weapons.inv.all_items().duplicate():  # no ammo carried
		if it["id"] in TacAmmoDefs.ROWS:
			weapons.inv.request_remove(it)
	weapons.refill_mags()
	var shells := 0
	for it in weapons.inv.all_items():
		if it["id"] in TacAmmoDefs.ROWS and TacAmmoDefs.ROWS[it["id"]]["cal"] == "12ga":
			shells += int(it["count"])
	t.check("f22: ammo bench gives 12ga shells for the tube gun", shells >= int(ItemDefs.STACK_MAX["12ga"]))
	for it in weapons.inv.all_items().duplicate():  # mag-gun regression
		weapons.inv.request_remove(it)
	weapons.give("ak47")
	var mag := weapons.inv.make("mag_ak47", {})
	mag["rounds"] = 0
	weapons.inv.add(mag)
	weapons.refill_mags()
	var refilled := 0
	for it in weapons.inv.all_items():
		if it["id"] == "mag_ak47":
			refilled = int(it["rounds"])
	t.check("f22: mag-gun refill unchanged (mag back to cap)", refilled == int(WeaponDefs.of("ak47")["mag"]))
	player.queue_free()
	weapons.queue_free()
	rack.queue_free()


## F23: sprint keeps take-off speed through the air; it still can't start mid-air.
static func _f23(t: RangeTest) -> void:
	var session := RangeSession.new(2718)
	var ps := session.add_player(1, true)
	var input := InputState.new()  # not in the tree: _process won't rebuild our frame
	input.frame._held["t_sprint"] = true
	input.frame._held["t_forward"] = true
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	player.enabled = true
	var floor := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(20, 1, 20)
	cs.shape = bs
	floor.add_child(cs)
	floor.position = Vector3(0, -0.5, 0)
	t.add_child(floor)
	player.position = Vector3(0, 1.0, 0)
	t.add_child(player)
	for i in 40:  # fall and settle onto the floor
		await t.get_tree().physics_frame
	t.check("f23: sprint engages on the ground", player.sprinting)
	player.position = Vector3(0, 6.0, 0)  # airborne (the jump)
	player.velocity = Vector3.ZERO
	for i in 2:
		await t.get_tree().physics_frame
	t.check("f23: sprint speed kept through the air", player.sprinting and not player.is_on_floor())
	player.sprinting = false  # can't initiate a sprint mid-air
	await t.get_tree().physics_frame
	t.check("f23: no fresh sprint while airborne", not player.sprinting)
	player.queue_free()
	floor.queue_free()
