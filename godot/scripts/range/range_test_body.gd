class_name RangeTestBody
## The player's own body: exists, clip follows state, head hidden from the player's camera.

static func run(t: RangeTest) -> void:
	var p := TacticalPlayer.new()
	p.input = InputState.new()
	p.add_child(p.input)
	t.add_child(p)
	p.set_process(false)
	p.set_physics_process(false)
	var b := FpBody.new()
	p.add_child(b)
	b.setup(p)
	b.auto = false
	await t.get_tree().process_frame
	t.check("body: model exists under the player", b.anim != null and b.get_child_count() > 0)
	b.step(0.1, Vector3.ZERO, false, true)
	t.check("body: idle when still", b.clip == "idle", b.clip)
	b.step(0.1, Vector3(0, 0, -1.5), false, true)
	t.check("body: walk when moving slowly", b.clip == "walk", b.clip)
	b.step(0.1, Vector3(0, 0, -3.2), false, true)
	t.check("body: faster clip at walking speed, rate follows speed", b.clip == "jog" and absf(b.anim.speed_scale - 3.2 / 3.35) < 0.01, b.clip)
	b.step(0.1, Vector3(0, 0, 3.2), false, true)
	t.check("body: backward plays reversed", b.anim.speed_scale < 0.0)
	b.step(0.1, Vector3.ZERO, true, true)
	t.check("body: crouch idle when crouched still", b.clip == "crouch_idle", b.clip)
	b.step(0.1, Vector3(0, 0, -1.7), true, true)
	t.check("body: crouch walk when crouched and moving", b.clip == "crouch_walk", b.clip)
	b.step(0.1, Vector3(0, 0, 0), false, false)
	t.check("body: jump clip airborne", b.clip == "jump", b.clip)
	# F45: the sprint lean must not bring the headless neck under the camera
	var worst := 9.0
	for i in 40:
		b.step(0.05, Vector3(0, 0, -5.5), false, true)
		b.anim.advance(0.05)
		var neck := b.to_local(b._skel.to_global(b._skel.get_bone_global_pose(b._neck).origin))
		if i > 20:
			worst = minf(worst, neck.z)
	t.check("body: sprinting keeps the neck >= 0.2 m behind the camera", b.clip == "sprint" and worst >= 0.2, "%.2f m" % worst)
	for i in 40:
		b.step(0.05, Vector3.ZERO, false, true)
	t.check("body: standing still restores the idle offset", absf(b._yaw_node.position.z - FpBody.BACK) < 0.001)
	var head := p.find_child("Head", true, false) as MeshInstance3D
	t.check("body: Head is not in the camera cull mask", head != null and (p.cam.cull_mask & head.layers) == 0 and head.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	p.queue_free()
	arms(t)


## Viewmodel arms: present for every weapon, hand bones on the grip targets at hip and ADS.
static func arms(t: RangeTest) -> void:
	var cam := Node3D.new()
	t.add_child(cam)
	var arms := FpArms.new()
	cam.add_child(arms)
	var gun := Node3D.new()
	cam.add_child(gun)
	t.check("arms: skeleton with both hands", arms.skel != null and arms.skel.find_bone("hand_l") >= 0 and arms.skel.find_bone("hand_r") >= 0)
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
		var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var half := mi.get_aabb().size.z * 0.5
		t.check("arms: %s has grip_r, grip_l, mag_l, butt data" % id, def.has("grip_r") and def.has("grip_l") and def.has("mag_l") and def.has("butt"))
		glb.free()
		arms.set_gun(def)
		for ads in [0.0, 1.0]:
			gun.position = TacticalViewmodel.base_pos(def, half, ads)
			arms.update(gun, 0.016)
			var worst := 0.0
			for side in ["r", "l"]:
				worst = maxf(worst, arms.hand_pos(side).distance_to(arms.target[side]))
			t.check("arms: %s hands within 2 cm of the grips (%s)" % [id, "ADS" if ads > 0.5 else "hip"], worst < 0.02, "%.1f cm" % (worst * 100.0))
	cam.free()
