class_name RangeTestBotMesh
## Enemy body checks for `--range-test`: every roster kind builds a skeleton body, its locomotion clip follows speed,
## the hands land on the gun's grips, and death starts the ragdoll simulation.

static func run(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer) -> void:
	RangeTestRoster.t = t
	for kind in BotDefs.ROWS:
		var b := RangeTestRoster.make(session, house, player, kind, Vector3(0, 0.1, 0))
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
		t.check("%s ragdoll simulating" % kind, m.body.sim.is_simulating_physics())
		b.queue_free()
	await _death_physics(t, session, house, player)


## Killing shot with a +X impulse: the pelvis is thrown +X, comes to rest low, and no bone ends
## up below the ground. A bleed-out death (no impulse) also falls.
static func _death_physics(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer) -> void:
	var b := RangeTestRoster.make(session, house, player, "rifleman", Vector3(0, 0.1, 0))
	await t.get_tree().process_frame
	var m: BotMesh = b.mesh
	var p0: Vector3 = m.body.bone_pos("pelvis")
	m.die(Vector3(TacticalConfig.DEATH_IMPULSE, 0, 0), "thorax")
	for i in 120:
		await t.get_tree().physics_frame
	var p1: Vector3 = m.body.bone_pos("pelvis")
	t.check("shot death throws pelvis +X", p1.x > p0.x + 0.2, "dx=%.2f m" % (p1.x - p0.x))
	t.check("shot death pelvis rests low", p1.y < 0.6, "y=%.2f m" % p1.y)
	var below := ""
	for bn in m.body.ragdoll_bones():
		if m.body.bone_pos(bn).y < -0.05:
			below += " " + str(bn)
	t.check("shot death: no bone below ground", below == "", below)
	b.queue_free()
	var b2 := RangeTestRoster.make(session, house, player, "rifleman", Vector3(0, 0.1, 0))
	await t.get_tree().process_frame
	var m2: BotMesh = b2.mesh
	m2.die()
	for i in 120:
		await t.get_tree().physics_frame
	t.check("bleed-out death falls", m2.body.bone_pos("pelvis").y < 0.6, "y=%.2f m" % m2.body.bone_pos("pelvis").y)
	b2.queue_free()
