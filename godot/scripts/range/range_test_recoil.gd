class_name RangeTestRecoil
## Recoil checks for `--range-test` (Tarkov model, Classic untouched) and the `--recoil-probe` spray printer.
## FB-H: two-channel model — bore spring + compensation, separate camera channel with permanent climb.

const DT := 1.0 / 120.0


static func run(t: RangeTest) -> void:
	_rise(t)
	_plateau(t)
	_plateau_m4_exact(t)
	_determinism(t)
	_camera_vs_barrel(t)
	_compensation(t)
	_dispersion_bounds(t)
	_settle_time(t)
	_climb(t)
	_burst_reset(t)
	_no_self_drag(t)
	_semi_returns(t)
	_semi_returns_exact(t)
	_aim_basis(t)
	_classic(t)
	if OS.get_cmdline_user_args().has("--recoil-probe"):
		probe()


## Fires `n` shots at `cadence` s apart (-1 = the gun's rpm); returns [pitch, yaw] of the bore at each shot.
static func spray(id: String, n: int, cadence := -1.0, tarkov := true, seed := 7) -> Array:
	var def := WeaponDefs.of(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rm := RecoilModel.new()
	rm.tarkov = tarkov
	var gap: float = cadence if cadence > 0.0 else 60.0 / def["rpm"]
	var out := []
	for i in n:
		out.append(rm.barrel if rm.tarkov else rm.offset)
		rm.shoot(def, rng)
		var left := gap
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
	return out


## Barrel displacement added by each shot (post-shot minus pre-shot bore).
static func _per_shot_kicks(id: String, n: int, seed := 7, cadence := -1.0) -> Array:
	var def := WeaponDefs.of(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rm := RecoilModel.new()
	rm.tarkov = true
	var gap: float = cadence if cadence > 0.0 else 60.0 / def["rpm"]
	var out := []
	for i in n:
		var before: Vector2 = rm.barrel
		rm.shoot(def, rng)
		var left := gap
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
		out.append((rm.barrel - before).length())
	return out


static func _rise(t: RangeTest) -> void:
	var def := WeaponDefs.of("ak47")
	var rm := RecoilModel.new()
	rm.tarkov = true
	var rng := RandomNumberGenerator.new()
	rm.shoot(def, rng)
	t.check("tarkov: a shot does not jump the barrel instantly", rm.barrel.length() == 0.0)
	var peak := 0.0
	var t90 := -1.0
	var tt := 0.0
	var samples := []
	while tt < 0.3:
		rm.update(DT, def["ergo"], def)
		tt += DT
		samples.append(rm.barrel.x)
		peak = maxf(peak, rm.barrel.x)
	for i in samples.size():
		if samples[i] >= peak * 0.9:
			t90 = (i + 1) * DT
			break
	t.check("tarkov: barrel rise time to 90%% of peak is 40-100 ms (%.0f ms)" % (t90 * 1000.0), t90 >= 0.04 and t90 <= 0.1)


static func _plateau(t: RangeTest) -> void:
	var s := spray("ak47", 30)
	var p5: float = s[5][0]
	var p30: float = s[29][0]
	t.check("tarkov: AK auto climb plateaus after ~5 shots (%.2f -> %.2f)" % [p5, p30], p5 > 0.6 * p30 and p30 < 1.2 and p30 > 0.4)
	var m4: float = spray("m4a1", 30)[29][0]
	t.check("tarkov: M4A1 plateau calmer than AK (%.2f < %.2f)" % [m4, p30], m4 < 0.75 * p30)
	var pk: float = spray("pkm", 30)[29][0]
	t.check("tarkov: PKM heavy but controllable (%.2f)" % pk, pk > m4 and pk < 2.0)


static func _camera_vs_barrel(t: RangeTest) -> void:
	var all_cols := true
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		all_cols = all_cols and d.has("conv") and d.has("cam_up") and d.has("cam_snap") and d.has("disp") \
			and d["angle"] >= 80.0 and d["angle"] <= 100.0
	t.check("tarkov: every gun has conv / cam_up / cam_snap / disp / angle (80-100)", all_cols)
	var gl := WeaponDefs.of("glock18")
	t.check("tarkov: pistols kick the camera least, shotguns most",
		gl["cam_up"] < WeaponDefs.of("ak47")["cam_up"] and WeaponDefs.of("shotgun")["cam_up"] >= 1.2)
	# Camera kick scales with cam_up by construction: same def, doubled cam_up -> ~doubled offset.
	var def := WeaponDefs.of("ak47")
	var o1 := _offset_after(def, 3)
	var def2 := def.duplicate()
	def2["cam_up"] = def["cam_up"] * 2.0
	var o2 := _offset_after(def2, 3)
	t.check("tarkov: camera kick scales with cam_up (%.2f vs %.2f)" % [o1, o2], o2 > o1 * 1.8 and o2 < o1 * 2.2)


static func _offset_after(def: Dictionary, n: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rm := RecoilModel.new()
	rm.tarkov = true
	for i in n:
		rm.shoot(def, rng)
		for k in 12:
			rm.update(DT, def["ergo"], def)
	return rm.offset.length()


static func _compensation(t: RangeTest) -> void:
	# FB-H: automatic recoil compensation — sustained fire self-limits vertically.
	for id in ["ak47", "m4a1"]:
		var kicks := _per_shot_kicks(id, 30)
		var early := 0.0
		for i in 5:
			early += kicks[i]
		var late := 0.0
		for i in range(5, 30):
			late += kicks[i]
		early /= 5.0
		late /= 25.0
		t.check("tarkov: %s auto-compensates, shots 6-30 kick less than 1-5 (%.3f < %.3f)" % [id, late, early],
			late < early * 0.8)


static func _dispersion_bounds(t: RangeTest) -> void:
	# FB-H: horizontal is per-shot pseudo-random bounce inside the dispersion budget. We measure the
	# peak yaw reached in each inter-shot interval (pre-shot samples are fully decayed on slow guns).
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var rm := RecoilModel.new()
		rm.tarkov = true
		var gap: float = 60.0 / def["rpm"]
		var bound: float = def["side"] * float(def["disp"]) * 6.0
		var ok := true
		var peak_y := 0.0
		for i in 30:
			rm.shoot(def, rng)
			var left := gap
			while left > 1e-6:
				var h := minf(DT, left)
				rm.update(h, def["ergo"], def)
				left -= h
				peak_y = maxf(peak_y, absf(rm.barrel.y))
			ok = ok and peak_y <= bound
		t.check("tarkov: %s horizontal stays within dispersion bounds and varies" % id, ok and peak_y > 0.01)


static func _settle_time(t: RangeTest) -> void:
	var tak := _settle("ak47")
	var tsk := _settle("sks")
	t.check("tarkov: higher conv settles faster (sks %.2fs < ak47 %.2fs)" % [tsk, tak], tsk < tak)
	t.check("tarkov: ak47 settles within 1.5 s (%.2fs)" % tak, tak < 1.5)


static func _settle(id: String) -> float:
	var def := WeaponDefs.of(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rm := RecoilModel.new()
	rm.tarkov = true
	var gap: float = 60.0 / def["rpm"]
	for i in 10:
		rm.shoot(def, rng)
		var left := gap
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
	var peak := rm.barrel.length()
	var tt := 0.0
	while tt < 5.0:
		rm.update(DT, def["ergo"], def)
		tt += DT
		if rm.barrel.length() < 0.1 * peak:
			break
	return tt


static func _climb(t: RangeTest) -> void:
	# FB-H: the camera does not fully recenter — part of every impulse becomes permanent climb (capped).
	var def := WeaponDefs.of("ak47")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rm := RecoilModel.new()
	rm.tarkov = true
	var gap: float = 60.0 / def["rpm"]
	for i in 200:
		rm.shoot(def, rng)
		var left := gap
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
	t.check("tarkov: permanent climb is capped (%.2f <= %.2f)" % [rm.climb().length(), TacticalConfig.RECOIL_T_CLIMB_MAX],
		rm.climb().length() <= TacticalConfig.RECOIL_T_CLIMB_MAX + 0.001)
	var tt := 0.0
	while tt < 2.0:
		rm.update(DT, def["ergo"], def)
		tt += DT
	t.check("tarkov: camera keeps its climb after the bore settles (cam %.2f, bore %.3f)" % [rm.offset.length(), rm.barrel.length()],
		rm.offset.length() > 0.2 and rm.barrel.length() < 0.05)


static func _burst_reset(t: RangeTest) -> void:
	# FB-H: shots spaced wider than BURST_GAP don't engage compensation — tapping re-triggers full
	# kick. We compare each tap's PEAK pitch (net displacement conflates the inter-tap residual).
	var def := WeaponDefs.of("ak47")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rm := RecoilModel.new()
	rm.tarkov = true
	var peaks := []
	for i in 6:
		rm.shoot(def, rng)
		var peak := 0.0
		var left := 0.5
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
			peak = maxf(peak, rm.barrel.x)
		peaks.append(peak)
	var early: float = (peaks[0] + peaks[1] + peaks[2]) / 3.0
	var late: float = (peaks[3] + peaks[4] + peaks[5]) / 3.0
	t.check("tarkov: slow taps don't engage compensation (%.3f ~= %.3f)" % [late, early],
		late > early * 0.85 and late < early * 1.15)


static func _no_self_drag(t: RangeTest) -> void:
	# FB-H: compensation only scales added impulse — the model never pushes pitch below zero.
	for id in ["ak47", "m4a1", "pkm", "glock18"]:
		var s := spray(id, 30)
		var ok := true
		for i in 30:
			ok = ok and (s[i] as Vector2).x >= -0.001
		t.check("tarkov: %s model never pushes pitch below zero" % id, ok)


static func _semi_returns(t: RangeTest) -> void:
	for id in ["sks", "garand", "sr25"]:
		var def := WeaponDefs.of(id)
		var rm := RecoilModel.new()
		rm.tarkov = true
		var rng := RandomNumberGenerator.new()
		var peak := 0.0
		var worst_back := 0.0
		for i in 6:
			rm.shoot(def, rng)
			for k in 40:   # 1/3 s at 120 Hz
				rm.update(DT, def["ergo"], def)
				peak = maxf(peak, rm.barrel.length())
			worst_back = maxf(worst_back, rm.barrel.length())
		t.check("tarkov: %s is back on the aim point 1/3 s after each shot (%.3f of %.2f)" % [id, worst_back, peak], worst_back < 0.1 * peak)


static func _aim_basis(t: RangeTest) -> void:
	var rm := RecoilModel.new()
	rm.tarkov = true
	rm.barrel = Vector2(2.0, 0.0)
	rm.offset = Vector2(0.5, 0.0)
	var dir := rm.aim_basis(Basis.IDENTITY) * Vector3(0, 0, -1)
	t.check("tarkov: bullets leave along the bore minus what the camera followed", absf(rad_to_deg(asin(dir.y)) - 1.5) < 0.01)
	rm.tarkov = false
	t.check("classic: aim basis is the camera basis", rm.aim_basis(Basis.IDENTITY) == Basis.IDENTITY)
	rm.tarkov = true


static func _classic(t: RangeTest) -> void:
	var def := WeaponDefs.of("ak47")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var rm := RecoilModel.new()
	rm.tarkov = false
	var cap: float = def["up"] * TacticalConfig.RECOIL_CAP_SHOTS
	var ref := Vector2.ZERO   # the old formula, inline
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 3
	for i in 40:
		rm.shoot(def, rng)
		ref.x += def["up"] * clampf(1.0 - ref.x / cap, 0.0, 1.0)
		ref.y = clampf(ref.y + rng2.randf_range(-def["side"], def["side"]), -def["side"] * 10.0, def["side"] * 10.0)
		rm.update(0.02, def["ergo"], def)
		ref *= exp(-lerpf(2.0, 6.0, def["ergo"] / 100.0) * 0.02)
	t.check("classic: recoil identical to the old model", rm.offset.is_equal_approx(ref) and rm.barrel == Vector2.ZERO)


static func probe() -> void:
	for id in ["ak47", "m4a1", "vector", "pkm"]:
		for mode in [false, true]:
			var s := spray(id, 30, -1.0, mode)
			var row := ""
			for i in 30:
				row += "%.2f/%.2f " % [s[i][0], s[i][1]]
			print("[probe] %s %s pitch/yaw per shot: %s" % [id, "tarkov" if mode else "classic", row])

static func _plateau_m4_exact(t: RangeTest) -> void:
	# Brief: 30-shot M4A1 burst plateaus — climb of shots 20-30 < 10% of climb of shots 1-10.
	var s := spray("m4a1", 31)
	var early: float = s[10][0] - s[0][0]
	var late: float = s[30][0] - s[19][0]
	t.check("tarkov: M4A1 shots 20-30 climb < 10%% of shots 1-10 (%.3f vs %.3f)" % [late, early],
		early > 0.0 and late < 0.1 * early)


static func _determinism(t: RangeTest) -> void:
	# Same seed -> the same learnable pattern; a different seed -> a different one.
	var a := spray("ak47", 30, -1.0, true, 7)
	var b := spray("ak47", 30, -1.0, true, 7)
	var same := true
	for i in 30:
		same = same and (a[i] as Vector2).is_equal_approx(b[i])
	t.check("tarkov: same seed gives the same recoil pattern", same)
	var c := spray("ak47", 30, -1.0, true, 8)
	var diff := false
	for i in 30:
		diff = diff or not (a[i] as Vector2).is_equal_approx(c[i])
	t.check("tarkov: different seed gives a different pattern", diff)


static func _semi_returns_exact(t: RangeTest) -> void:
	# Brief: semi at 2 shots/s (0.5 s apart) returns within 0.1 deg of the start before each shot.
	var def := WeaponDefs.of("sks")
	var rm := RecoilModel.new()
	rm.tarkov = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ok := true
	for i in 6:
		if i > 0:
			ok = ok and rm.barrel.length() < 0.1
		rm.shoot(def, rng)
		var left := 0.5
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
	t.check("tarkov: SKS at 2 shots/s is within 0.1 deg of aim before every shot", ok)
