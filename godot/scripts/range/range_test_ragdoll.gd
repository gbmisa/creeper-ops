class_name RangeTestRagdoll
## F77: a ragdoll stays one body. For 3 s after a kill every physical bone keeps its distance from its parent bone
## within RANGE_TOL of the skeleton's rest distance (no limb flying off or stretching). The first SETTLE frames are
## skipped: the bodies are placed from the animated pose and the joints pull that into line.

const RANGE_TOL := 0.05
const SETTLE := 6
const TORSO_R := 0.10  # the spine capsules' radius (BotRagdoll.RAGDOLL)
const JOG_SPEED := 3.0
const RUN_TIME := 0.5
const LIMBS := ["upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r", "thigh_l", "thigh_r", "calf_l", "calf_r", "foot_l", "foot_r"]


static func run(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer) -> void:
	for impulse in [Vector3(TacticalConfig.DEATH_IMPULSE, 0, 0), Vector3(0, 40, -150), Vector3.ZERO]:
		var b := RangeTestRoster.make(session, house, player, "rifleman", Vector3(0, 0.1, 0))
		await t.get_tree().process_frame
		var m: BotMesh = b.mesh
		var sk := m.body.skel
		var rest := {}  # bone -> [parent bone, rest distance]
		for bn in m.body.ragdoll_bones():
			var pi := sk.get_bone_parent(sk.find_bone(bn))
			while pi >= 0 and not m.body.ragdoll_bones().has(sk.get_bone_name(pi)):
				pi = sk.get_bone_parent(pi)
			if pi >= 0:
				rest[bn] = [sk.get_bone_name(pi), sk.get_bone_global_rest(sk.find_bone(bn)).origin.distance_to(sk.get_bone_global_rest(pi).origin)]
		m.die(impulse, "thorax")
		var worst := 0.0
		var who := ""
		for i in 180:
			await t.get_tree().physics_frame
			m.walk(1.0 / 60.0, 0.0)
			if i < SETTLE:
				continue
			for bn in rest:
				var e: float = absf(m.body.bone_pos(bn).distance_to(m.body.bone_pos(rest[bn][0])) - rest[bn][1])
				if e > worst:
					worst = e
					who = bn
		var high := 0.0
		for bn in m.body.ragdoll_bones():
			high = maxf(high, m.body.bone_pos(bn).y - m.body.bone_pos("pelvis").y)
		t.check("ragdoll lies down: no bone more than 0.5 m above the pelvis 3 s after death (impulse %s): %.2f m" % [impulse, high], high <= 0.5)
		print("[range] ragdoll impulse ", impulse, " worst bone-to-parent error ", snappedf(worst, 0.001), " (", who, ")")
		t.check("ragdoll stays connected for 3 s (impulse %s): worst %s %.3f m" % [impulse, who, worst], worst <= RANGE_TOL)
		b.queue_free()
	for stance in ["standing", "crouched", "running"]:
		await _limbs(t, session, house, player, stance)


## Spawns a rifleman in `stance` (running = jogging along -Z at JOG_SPEED for RUN_TIME), settled for a few frames.
static func spawn(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer, stance: String) -> ScavBot:
	RangeTestRoster.t = t
	var b := RangeTestRoster.make(session, house, player, "rifleman", Vector3(0, 0.1, 0))
	await t.get_tree().process_frame
	var m: BotMesh = b.mesh
	m.crouch = stance == "crouched"
	var speed := JOG_SPEED if stance == "running" else 0.0
	for i in int(RUN_TIME * 60.0) if stance == "running" else 10:
		await t.get_tree().physics_frame
		b.global_position += Vector3(0, 0, -speed / 60.0)
		m.walk(1.0 / 60.0, speed)
	return b


## F144: 3 s after a kill (thorax hit) no limb capsule centre is inside the torso (spine_01 .. neck_01 chain).
static func _limbs(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer, stance: String) -> void:
	var b := await spawn(t, session, house, player, stance)
	var m: BotMesh = b.mesh
	m.die(Vector3(TacticalConfig.DEATH_IMPULSE, 0, 0), "thorax")
	for i in 180:
		await t.get_tree().physics_frame
		m.walk(1.0 / 60.0, 0.0)
	var worst := 9.0
	var who := ""
	var top: Vector3 = m.body.bone_pos("neck_01")
	for bn in LIMBS:
		var c: Vector3 = m.body.capsule_center(bn)
		var d := 9.0
		for seg in [["spine_01", "spine_02"], ["spine_02", "spine_03"], ["spine_03", "neck_01"]]:
			d = minf(d, BotRagdoll.segment_dist(c, c, m.body.bone_pos(seg[0]), m.body.bone_pos(seg[1])))
		if d < worst:
			worst = d
			who = bn
	print("[range] ragdoll ", stance, " closest limb centre to the torso axis ", snappedf(worst, 0.001), " (", who, ")")
	t.check("ragdoll limbs stay out of the torso 3 s after death (%s): %s %.3f m (torso r %.2f)" % [stance, who, worst, TORSO_R], worst >= TORSO_R)
	b.queue_free()
