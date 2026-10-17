class_name RangeRagdollShots
## `--range-test --ragdoll-shots=/abs/dir`: kills a standing, a crouched and a running rifleman in the kill house and
## saves a side-camera frame at 0.0 / 0.3 / 0.7 / 1.5 / 3.0 s after each death as <dir>/<stance>_<time>.png, then quits.
## Run windowed under xvfb-run (not --headless).

const TIMES := [0.0, 0.3, 0.7, 1.5, 3.0]


static func run(t: RangeTest, session: RangeSession, house: Node3D, player: TacticalPlayer, dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	t.add_child(cam)
	cam.current = true
	for stance in ["standing", "crouched", "running"]:
		var b := await RangeTestRagdoll.spawn(t, session, house, player, stance)
		var m: BotMesh = b.mesh
		var at := b.global_position
		cam.global_position = Vector3(at.x + 5.0, 1.2, at.z - 0.5)
		cam.look_at(Vector3(at.x, 0.7, at.z - 0.5))
		m.die(Vector3(TacticalConfig.DEATH_IMPULSE, 0, 0), "thorax")
		var tick := 0
		for time in TIMES:
			while tick < int(time * 60.0):
				await t.get_tree().physics_frame
				m.walk(1.0 / 60.0, 0.0)
				tick += 1
			await RenderingServer.frame_post_draw
			var out := "%s/%s_%.1f.png" % [dir, stance, time]
			t.get_viewport().get_texture().get_image().save_png(out)
			print("[ragdoll-shot] ", out)
		b.queue_free()
	t.get_tree().quit()
