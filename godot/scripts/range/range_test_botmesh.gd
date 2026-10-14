class_name RangeTestBotMesh
## Enemy body checks for `--range-test`: every roster kind builds a skeleton body, its locomotion clip follows speed,
## the hands land on the gun's grips, and death plays the death clip.

static func run(t: RangeTest, house: Node3D, player: TacticalPlayer) -> void:
	RangeTestRoster.t = t
	for kind in BotDefs.ROWS:
		var b := RangeTestRoster.make(house, player, kind, Vector3(0, 0.1, 0))
		await t.get_tree().process_frame
		var m: BotMesh = b.mesh
		t.check("%s builds a skeleton body" % kind, m.body.skel != null and m.body.skel.get_bone_count() == 65)
		var clips := []
		for sp in [0.0, 1.5, 3.0, 5.5]:
			m.walk(0.02, sp)
			clips.append(m.body.clip)
		t.check("%s clip follows speed" % kind, clips == ["idle", "walk", "jog", "sprint"], str(clips))
		m.walk(0.1, 3.0)
		var def: Dictionary = WeaponDefs.of(BotDefs.ROWS[kind]["gun"])
		var gt := m.gun.global_transform
		var err: float = (m.body.arms.hand_pos("r") - gt * (def["grip_r"] as Vector3)).length()
		t.check("%s right hand on the grip" % kind, err < 0.08, "%.3f m" % err)
		m.die()
		m.walk(0.1, 3.0)
		t.check("%s plays death" % kind, m.body.clip == "death")
		b.queue_free()
