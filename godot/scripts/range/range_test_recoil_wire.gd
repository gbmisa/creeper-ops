class_name RangeTestRecoilWire
## FB-I phase 2 checks: the recoil model wired to the player. The settled residual moves into the view (the
## next hip shot is on the dot), the world aim never jumps while it does, the view follows the muzzle while
## aiming, automatic fire reaches stable mode, and the gun is back on its FB-H ADS pose at rest.

const STEP := TacRecoilDefs.STEP


## Model checks (from RangeTestRecoil, before the range world exists).
static func run(t: RangeTest) -> void:
	_fold_model(t)
	_follow(t)


## Mean hip wander (deg) over 0.5 s after three quick hip shots, 20 seeds (the fitted gun's `hip` stat scales it).
static func hip_wander(g: Gun) -> float:
	var sum := 0.0
	for s in 20:
		var rm := RecoilModel.new()
		rm.set_seed(s + 1)
		for i in 3:
			rm.shoot(g.eff_def())
			rm.update(0.1)
		for i in 30:
			rm.update(STEP)
			sum += rm.hip.offset.length()
	return sum / 600.0


## Model only: one hip shot from rest, then until the residual has gone to the view.
static func _fold_model(t: RangeTest) -> void:
	var worst_jump := 0.0
	var taken := Vector2.ZERO
	var settle := []
	var off := 0.0
	for s in 40:
		var rm := RecoilModel.new()
		rm.set_seed(s + 1)
		rm.shoot(WeaponDefs.of("ak47"))
		var view := Vector2.ZERO
		var first := -1.0
		for i in 300:
			var before := rm.barrel + view
			rm.update(STEP)
			view += rm.view_fold
			if rm.view_fold != Vector2.ZERO:
				if first < 0.0:
					first = (i + 1) * STEP
				worst_jump = maxf(worst_jump, ((rm.barrel + view) - before).length())
				taken += rm.view_fold.abs()
			rm.view_fold = Vector2.ZERO
		settle.append(first)
		off = maxf(off, rm.barrel.length())
	var st := RangeTestRecoil._stats(settle)
	t.check("recoil fold: every hip shot settles and hands its residual to the view (%.2f..%.2f s after the shot)" % [st.x, st.z],
		st.x > 0.0 and taken.length() > 0.0)
	t.check("recoil fold: after the settle the barrel is on the view (worst %.5f deg, limit 0.01)" % off, off < 0.01)
	t.check("recoil fold: the barrel's aim in the world moves smoothly while the view takes it (worst step %.4f deg)" % worst_jump,
		worst_jump < 0.05)


## Aimed, the view rises with the muzzle; from the hip it does not.
static func _follow(t: RangeTest) -> void:
	var peak := [0.0, 0.0]
	var cam := [0.0, 0.0]
	for k in 2:
		var rm := RecoilModel.new()
		rm.set_seed(9)
		rm.aiming = k == 1
		rm.shoot(WeaponDefs.of("ak47"))
		for i in 30:
			rm.update(STEP)
			peak[k] = maxf(peak[k], rm.barrel.x)
			cam[k] = maxf(cam[k], rm.follow.value.x)
	t.check("recoil follow: aimed, the view rises with the muzzle (%.2f of %.2f deg); hip %.3f" % [cam[1], peak[1], cam[0]],
		cam[1] > peak[1] * 0.3 and cam[0] < 0.001)


## Through PlayerWeapons / PlayerRecoil / TacticalPlayer (range_test.gd, once Ballistics exists).
static func player(t: RangeTest) -> void:
	var r := RangeTestAttach._rig(t)
	var w: PlayerWeapons = r["w"]
	var player: TacticalPlayer = r["player"]
	var vm: TacticalViewmodel = r["vm"]
	await t.get_tree().process_frame
	RangeTestAttach._equip(r, "ak47")
	w.recoil = RecoilModel.new()
	w.recoil.set_seed(4)
	w.rng.seed = 4
	w.ads_amt = 0.0
	player.pitch = 0.0
	player.yaw = 0.0
	var dot := func() -> Vector3: return player.view_basis(player.recoil_off) * Vector3.FORWARD
	var aim := func() -> Vector3: return player.view_basis(w.recoil.barrel) * Vector3.FORWARD
	var first_off := rad_to_deg((aim.call() as Vector3).angle_to(dot.call()))
	RangeTestAttach._fire(w)
	var pitch0 := player.pitch
	var world := []
	for i in 240:   # 4 s
		PlayerRecoil.tick(w, STEP)
		world.append(aim.call())
	var jump := 0.0
	for i in range(60, world.size()):   # from 1 s on: the return and the settle, not the kick itself
		jump = maxf(jump, rad_to_deg((world[i] as Vector3).angle_to(world[i - 1])))
	var next_off := rad_to_deg((aim.call() as Vector3).angle_to(dot.call()))
	t.check("recoil hip: first shot from rest leaves on the hip dot (%.4f deg)" % first_off, first_off < 0.01)
	t.check("recoil hip: after one hip shot settles, the next leaves on the dot (%.4f deg, limit 0.01); view kept %.3f deg"
		% [next_off, rad_to_deg(player.pitch - pitch0)], next_off < 0.01 and player.pitch != pitch0)
	t.check("recoil hip: the bullets' aim never jumps while settling (worst %.4f deg per step from 1 s)" % jump, jump < 0.05)
	# automatic fire through the player wiring reaches stable mode; semi never does
	var gap: float = 60.0 / float(w.gun.def["rpm"])
	for mode in ["auto", "semi"]:
		w.recoil = RecoilModel.new()
		w.recoil.set_seed(5)
		w.gun.mode = mode
		w.trigger_held = true
		var stable := false
		for i in 8:
			RangeTestAttach._fire(w)
			PlayerRecoil.tick(w, gap)
			stable = stable or w.recoil.rot.stable_on
		w.trigger_held = false
		t.check("recoil wiring: held %s fire, shot index %d, stable mode %s" % [mode, w.recoil.shot_index, stable],
			(stable and w.recoil.shot_index == 8) if mode == "auto" else (not stable and w.recoil.shot_index <= 1))
	# aimed shot, then rest: the viewmodel is back on its exact FB-H pose
	w.recoil = RecoilModel.new()
	w.ads_amt = 1.0
	RangeTestAttach._fire(w)
	for i in 300:
		PlayerRecoil.tick(w, STEP)
	var rx := TacticalViewmodel.recoil_xform(w.recoil)
	t.check("recoil ADS: 5 s after an aimed shot the gun is exactly on its ADS pose (recoil transform identity)",
		rx == Transform3D.IDENTITY, str(rx))
	_panel(t, w, player, r["input"])
	for k in ["w", "vm", "player", "input", "rack"]:
		r[k].queue_free()


## The tuning panel: opens on the gun in hand, a slider change reaches the next shot, reset puts it back.
static func _panel(t: RangeTest, w: PlayerWeapons, player: TacticalPlayer, input: InputState) -> void:
	var p := RecoilPanel.new()
	t.add_child(p)
	p.setup(w, player, input)
	p.toggle()
	var before: float = TacRecoilDefs.resolve(w.gun.eff_def())["rot_range"].y
	p._set_row("force_up", 300.0)
	p._set_row("post_v.x", -2.0)
	var row := TacRecoilDefs.row("ak47")
	var after: float = TacRecoilDefs.resolve(w.gun.eff_def())["rot_range"].y
	t.check("recoil panel: opens on the gun in hand (%d sliders), frees the player, a change applies live (%.1f -> %.1f)"
		% [p._list.get_child_count(), before, after], p.visible and not player.enabled and after > before * 2.0
		and row["post_v"] == Vector2(-2.0, 0.0) and Keybinds.keys("t_recoil_panel").has(KEY_F7))
	p._reset()
	p.toggle()
	t.check("recoil panel: reset gun drops the overrides, closing gives the player back",
		not TacRecoilDefs.overrides.has("ak47") and player.enabled and not p.visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	p.queue_free()
