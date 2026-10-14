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
	var head := p.find_child("Head", true, false) as MeshInstance3D
	t.check("body: Head is not in the camera cull mask", head != null and (p.cam.cull_mask & head.layers) == 0 and head.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	p.queue_free()
