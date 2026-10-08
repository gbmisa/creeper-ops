class_name SmokeFpsFeel
## First-person feel (Stage 23): recoil returns to rest, the camera never drifts, the sprayer
## fizzes over creeper and lowers it, particle and effect counts stay capped, hit feedback state.
## Called from SmokeTest.run.


static func run(g) -> void:
	_recoil(g)
	_camera(g)
	_spray(g)
	_effects(g)
	_feedback()


static func _recoil(g) -> void:
	var w: OperativeWeapons = g.fps.weapons
	var ctrl: PlayerController = g.fps.controller
	var m := w.motion
	w.current = "rifle"
	m.update(0.5, ctrl, g.input)  # settle whatever earlier checks left
	w.kick(1.0)
	m.update(1.0 / 60.0, ctrl, g.input)
	var back := w.gun.position.z - ViewmodelMotion.BASE.z
	var pitch := w.gun.rotation.x
	SmokeTest._check("feel: one shot kicks the gun back 4+ cm and up 4+ deg", back >= 0.04 and pitch >= deg_to_rad(4.0),
		"(%.3f m, %.1f deg)" % [back, rad_to_deg(pitch)])
	for i in 24:  # 0.4 s
		m.update(1.0 / 60.0, ctrl, g.input)
	SmokeTest._check("feel: kick offsets return to rest within 0.4 s", m.at_rest()
		and absf(w.gun.position.z - ViewmodelMotion.BASE.z) < 0.01 and absf(w.gun.rotation.x) < 0.02,
		"(k %.4f)" % m.k)


static func _camera(g) -> void:
	var w: OperativeWeapons = g.fps.weapons
	var ctrl: PlayerController = g.fps.controller
	var base := ctrl.pitch
	var peak := 0.0
	for i in 30:
		w.kick(1.0)
		for j in 8:
			ctrl.kick_pitch = w.motion.cam_pitch()
			ctrl._sync()
			peak = maxf(peak, absf(ctrl.camera.rotation.x - base))
			w.motion.update(1.0 / 60.0, ctrl, g.input)
	for j in 60:
		ctrl.kick_pitch = w.motion.cam_pitch()
		w.motion.update(1.0 / 60.0, ctrl, g.input)
	ctrl.kick_pitch = w.motion.cam_pitch()
	ctrl._sync()
	var drift := absf(ctrl.camera.rotation.x - base)
	SmokeTest._check("feel: camera pitch never drifts after 30 shots", drift < 0.001 and ctrl.pitch == base
		and peak <= Config.VM_KICK_MAX * Config.VM_CAM_KICK + 0.001 and peak > 0.003, "(peak %.3f rad, drift %.5f)" % [peak, drift])
	ctrl.kick_pitch = 0.0


static func _spray(g) -> void:
	var w: OperativeWeapons = g.fps.weapons
	var world: World = g.surface
	var grid := world.grid
	var cell := Vector2i(30, 30)
	var feet := grid.cell_ground(cell.x, cell.y)
	w.camera.global_position = feet
	w.camera.rotation = Vector3(0, 0, 0)  # looking along -Z
	var wet: Array[Vector2i] = [Vector2i(30, 26), Vector2i(30, 27), Vector2i(31, 27)]
	for c in wet:
		world.creeper.set_depth(c.x, c.y, 2.0)
	var before := 0.0
	for c in wet:
		before += world.creeper.depth_at(c.x, c.y)
	var kids := world.get_child_count()
	w._spray(0.1, world, feet)
	var after := 0.0
	for c in wet:
		after += world.creeper.depth_at(c.x, c.y)
	SmokeTest._check("feel: spraying over creeper lowers depth", after < before - 0.01, "(%.2f -> %.2f)" % [before, after])
	var live := 0
	for n in world.get_children():
		if n is CPUParticles3D and (n as CPUParticles3D).emitting:
			live += 1
	SmokeTest._check("feel: spraying over creeper spawns fizz", w.spray_fx.fizz_nodes() > 0 and live > 0, "(%d emitters)" % live)
	for i in 400:  # hold the trigger for 20 s
		w._spray(0.05, world, feet)
		for c in wet:
			world.creeper.set_depth(c.x, c.y, 2.0)
	var pool := w.spray_fx.fizz_nodes()
	SmokeTest._check("feel: particle counts capped by config", pool <= Config.FIZZ_POOL and world.get_child_count() <= kids + Config.FIZZ_POOL
		and w.spray_fx.mist.amount == Config.SPRAY_MIST and w.spray_fx.droplets.amount == Config.SPRAY_DROPLETS
		and SprayFx.budget() <= 400, "(%d fizz nodes, budget %d)" % [pool, SprayFx.budget()])
	for c in wet:
		world.creeper.set_depth(c.x, c.y, 0.0)


static func _effects(g) -> void:
	var fx: Effects = g.surface.effects
	for i in 40:
		fx.tracer(Vector3(0, 5, 0), Vector3(50, 5, 0), Color.WHITE)
		fx.smoke(Vector3(0, 5, 0), 1.0, 0.8)
	fx.update(0.5)
	fx.update(0.5)
	fx.update(2.0)
	SmokeTest._check("feel: tracers and smoke expire", fx._items.is_empty(), "(%d left)" % fx._items.size())


static func _feedback() -> void:
	var f := HitFeel.new()
	f.confirm(false)
	var plain := f.marker_t > 0.0 and f.kill_t == 0.0
	f.confirm(true)
	HitFeel.note_source(Vector3(10, 0, 0))
	f.hurt(Config.BIG_HIT + 1.0)
	SmokeTest._check("feel: hit marker, kill confirm, hurt arc and vignette set", plain and f.kill_t > 0.0
		and f.vignette_t > 0.0 and f.arcs.size() == 1)
	f.update(3.0)
	SmokeTest._check("feel: hit feedback fades out", f.marker_t == 0.0 and f.kill_t == 0.0 and f.vignette_t == 0.0 and f.arcs.is_empty())
