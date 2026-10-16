class_name RangeTestRagdoll
## F77: a ragdoll stays one body. For 3 s after a kill every physical bone keeps its distance from its parent bone
## within RANGE_TOL of the skeleton's rest distance (no limb flying off or stretching). The first SETTLE frames are
## skipped: the bodies are placed from the animated pose and the joints pull that into line.

const RANGE_TOL := 0.05
const SETTLE := 6


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
		print("[range] ragdoll impulse ", impulse, " worst bone-to-parent error ", snappedf(worst, 0.001), " (", who, ")")
		t.check("ragdoll stays connected for 3 s (impulse %s): worst %s %.3f m" % [impulse, who, worst], worst <= RANGE_TOL)
		b.queue_free()
