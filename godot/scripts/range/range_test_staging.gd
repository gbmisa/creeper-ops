class_name RangeTestStaging
## F139/F140 checks for `--range-test`: a kit saved to a mannequin comes back on equip; the deploy board launches the
## chosen map. Presets use a temp file, never user://presets.cfg.

const TMP := "user://test_presets.cfg"


static func _ids(inv: Inventory) -> Array:
	var out := []
	for it in inv.all_items():
		out.append(it["id"])
	out.sort()
	return out


static func run(t: RangeTest) -> void:
	GearPresets.path = TMP
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	var session := RangeSession.new(77)
	var ps := session.add_player(1, true)
	var input := InputState.new()
	t.add_child(input)
	var player := TacticalPlayer.new()
	player.input = input
	player.session = session
	ps.node = player
	t.add_child(player)
	var weapons := PlayerWeapons.new()
	t.add_child(weapons)
	var rack := RangeRack.new()
	t.add_child(rack)
	var saved := RangeSession._carried.duplicate(true)
	session.clear_kit()
	weapons.setup(player, input, t.bal, rack, session)
	var before := _ids(weapons.inv)
	var m := StagingMannequin.new()
	t.add_child(m)
	m.setup(1, Vector3.ZERO)
	t.check("F140 empty mannequin has no preset and cannot equip", not m.has_preset() and not m.equip(weapons))
	m.save_from(weapons.inv)
	t.check("F140 mannequin saves the kit and shows a body", m.has_preset() and m.figure != null and m.figure.mesh != null)
	t.check("F140 preset is on disk (a new mannequin reads it)", GearPresets.load_slot(1)["kit"] == m.kit and not (GearPresets.load_slot(0)["kit"] as Dictionary).size() > 0)
	for it in weapons.inv.all_items():
		weapons.inv.remove(it)
	t.check("F140 kit cleared", _ids(weapons.inv).is_empty())
	t.check("F140 equip returns the preset", m.equip(weapons))
	t.check("F140 same items come back", _ids(weapons.inv) == before)
	m.rename("Night raid")
	t.check("F140 rename persists", GearPresets.load_slot(1)["name"] == "Night raid")
	var board := StagingBoard.new()
	t.add_child(board)
	var went := []
	board.setup(weapons, player, func(map: String): went.append(map))
	var first := board.target
	board.deploy()
	board.cycle()
	board.deploy()
	t.check("F139 deploy board launches the chosen map", went == [first, "skirmish_large" if first == "skirmish" else "skirmish"] and first in StagingBoard.MAPS)
	RangeMaps.staging_target = "skirmish_large"
	var b2 := StagingBoard.new()
	t.add_child(b2)
	b2.setup(weapons, player, func(_m: String): pass)
	t.check("F139 board starts on the preselected map", b2.target == "skirmish_large")
	RangeMaps.staging_target = "skirmish"
	t.check("F139 staging is a known map scene", RangeMaps.SCENES.has("staging"))
	RangeSession._carried = saved
	GearPresets.path = "user://presets.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	m.queue_free()
	board.queue_free()
	b2.queue_free()
	player.queue_free()
	weapons.queue_free()
