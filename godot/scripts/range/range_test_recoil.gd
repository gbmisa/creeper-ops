class_name RangeTestRecoil
## Recoil checks for `--range-test` (Tarkov model, Classic untouched) and the `--recoil-probe` spray printer.

const DT := 1.0 / 120.0


static func run(t: RangeTest) -> void:
	var was := RecoilModel.tarkov
	RecoilModel.tarkov = true
	_rise(t)
	_plateau(t)
	_camera_vs_barrel(t)
	_semi_returns(t)
	_aim_basis(t)
	RecoilModel.tarkov = false
	_classic(t)
	if OS.get_cmdline_user_args().has("--recoil-probe"):
		probe()
	RecoilModel.tarkov = was


## Fires `n` shots at `cadence` s apart (-1 = the gun's rpm); returns [pitch, yaw] of the bore at each shot.
static func spray(id: String, n: int, cadence := -1.0) -> Array:
	var def := WeaponDefs.of(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rm := RecoilModel.new()
	var gap: float = cadence if cadence > 0.0 else 60.0 / def["rpm"]
	var out := []
	for i in n:
		out.append(rm.barrel if RecoilModel.tarkov else rm.offset)
		rm.shoot(def, rng)
		var left := gap
		while left > 1e-6:
			var h := minf(DT, left)
			rm.update(h, def["ergo"], def)
			left -= h
	return out


static func _rise(t: RangeTest) -> void:
	var def := WeaponDefs.of("ak47")
	var rm := RecoilModel.new()
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
	t.check("tarkov: AK auto climb plateaus after ~5 shots (%.2f -> %.2f)" % [p5, p30], p5 > 0.75 * p30 and p30 < 1.6 and p30 > 0.8)
	var m4: float = spray("m4a1", 30)[29][0]
	t.check("tarkov: M4A1 plateau calmer than AK (%.2f < %.2f)" % [m4, p30], m4 < 0.75 * p30)
	var pk: float = spray("pkm", 30)[29][0]
	t.check("tarkov: PKM heavy but controllable (%.2f)" % pk, pk > m4 and pk < 2.2)


static func _camera_vs_barrel(t: RangeTest) -> void:
	var ok := true
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		var rm := RecoilModel.new()
		var rng := RandomNumberGenerator.new()
		for i in 5:
			rm.shoot(def, rng)
			for k in 12:
				rm.update(DT, def["ergo"], def)
		ok = ok and rm.offset.length() < rm.barrel.length() * 0.6
	t.check("tarkov: camera moves less than the barrel for all 17 guns", ok)
	var gl := WeaponDefs.of("glock18")
	t.check("tarkov: pistols follow the barrel least, shotguns most", gl["cam_share"] < WeaponDefs.of("ak47")["cam_share"] and WeaponDefs.of("shotgun")["cam_share"] >= 0.5)
	var all_cols := true
	for id in WeaponDefs.ORDER:
		var d := WeaponDefs.of(id)
		all_cols = all_cols and d.has("conv") and d.has("cam_share") and d["angle"] >= 80.0 and d["angle"] <= 100.0
	t.check("tarkov: every gun has conv / cam_share / angle (80-100)", all_cols)


static func _semi_returns(t: RangeTest) -> void:
	for id in ["sks", "garand", "sr25"]:
		var def := WeaponDefs.of(id)
		var rm := RecoilModel.new()
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
	rm.barrel = Vector2(2.0, 0.0)
	rm.offset = Vector2(0.5, 0.0)
	var dir := rm.aim_basis(Basis.IDENTITY) * Vector3(0, 0, -1)
	t.check("tarkov: bullets leave along the bore minus what the camera followed", absf(rad_to_deg(asin(dir.y)) - 1.5) < 0.01)
	RecoilModel.tarkov = false
	t.check("classic: aim basis is the camera basis", rm.aim_basis(Basis.IDENTITY) == Basis.IDENTITY)
	RecoilModel.tarkov = true


static func _classic(t: RangeTest) -> void:
	var def := WeaponDefs.of("ak47")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var rm := RecoilModel.new()
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
			RecoilModel.tarkov = mode
			var s := spray(id, 30)
			var row := ""
			for i in 30:
				row += "%.2f/%.2f " % [s[i][0], s[i][1]]
			print("[probe] %s %s pitch/yaw per shot: %s" % [id, "tarkov" if mode else "classic", row])
