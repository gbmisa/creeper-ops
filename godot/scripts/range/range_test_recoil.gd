class_name RangeTestRecoil
## Tarkov recoil checks for `--range-test` (F63, RecoilModel) against the TRP spec's measured stock AKM,
## standing, 40 seeds (docs/tasks/FB_I_trp_recoil_spec.md "Recoil, shot by shot"); `--recoil-probe` prints them.

const STEP := TacRecoilDefs.STEP
const RUNS := 40


static func run(t: RangeTest) -> void:
	_single(t, false)
	_single(t, true)
	_auto(t)
	_hip_rest(t)
	_determinism(t)
	_every_gun(t)
	if OS.get_cmdline_user_args().has("--recoil-probe"):
		probe()


static func _model(seed: int, aimed := false) -> RecoilModel:
	var rm := RecoilModel.new()
	rm.set_seed(seed)
	rm.aiming = aimed
	return rm


## One single shot from rest: [muzzle peak deg, time to it s, kick back m, camera peak deg, muzzle 0.5 s on].
static func single(id: String, seed: int, aimed: bool) -> Array:
	var rm := _model(seed, aimed)
	rm.shoot(WeaponDefs.of(id))
	var out := [0.0, 0.0, 0.0, 0.0, 0.0]
	for i in 60:
		rm.update(STEP)
		var v: Array = rm.stepped()
		if -rm.rot.current.x > out[0]:   # the recoil itself; the hip wander is checked on its own
			out[0] = -rm.rot.current.x
			out[1] = (i + 1) * STEP
		out[2] = maxf(out[2], rm.pos.value().y)   # the position spring (spec: worked back from it)
		out[3] = maxf(out[3], -v[2].x)
		if i == 29:
			out[4] = -v[0].x
	return out


## Held auto fire at the gun's rpm: muzzle height (deg) as each of `n` shots fires (index 0 = shot 1).
static func burst(id: String, seed: int, aimed: bool, n := 10) -> Array:
	var def := WeaponDefs.of(id)
	var rm := _model(seed, aimed)
	for i in 30:   # standing a moment first, as in the recordings (sets the return rate)
		rm.update(STEP)
	rm.auto_fire = true
	var gap: float = 60.0 / def["rpm"]
	var out := []
	var tt := rm._now
	for i in n:
		out.append(-rm.stepped()[0].x)
		rm.shoot(def)
		tt += gap
		while rm._now + 1e-6 < tt:
			rm.update(STEP)
	return out


static func _stats(vals: Array) -> Vector3:   # min, mean, max
	var lo := INF
	var hi := -INF
	var sum := 0.0
	for v in vals:
		lo = minf(lo, v)
		hi = maxf(hi, v)
		sum += v
	return Vector3(lo, sum / maxf(vals.size(), 1), hi)


static func _single(t: RangeTest, aimed: bool) -> void:
	var peak := []
	var when := []
	var back := []
	var cam := []
	for s in RUNS:
		var r := single("ak47", s + 1, aimed)
		peak.append(r[0]); when.append(r[1]); back.append(r[2] * 1000.0); cam.append(r[3])
	var p := _stats(peak)
	var w := _stats(when)
	var b := _stats(back)
	var c := _stats(cam)
	var tag := "aimed" if aimed else "hip"
	var lo := 1.17 if aimed else 1.56
	var hi := 1.51 if aimed else 1.99
	t.check("recoil: AK %s shot muzzle peak %.2f..%.2f (mean %.2f) inside %.2f..%.2f" % [tag, p.x, p.z, p.y, lo, hi],
		p.x >= lo - 0.03 and p.z <= hi + 0.03)
	if aimed:
		return
	t.check("recoil: AK hip peak at %.3f s (spec ~0.14)" % w.y, absf(w.y - 0.14) < 0.03)
	t.check("recoil: AK hip kick back %.1f..%.1f mm (mean %.1f) in 15-25" % [b.x, b.z, b.y], b.x >= 15.0 and b.z <= 25.0)
	t.check("recoil: AK hip camera kick %.2f deg (spec ~0.79)" % c.y, absf(c.y - 0.79) < 0.08)


static func _auto(t: RangeTest) -> void:
	var want := [1.67, 2.62, 3.73, 5.27]
	var cols := [[], [], [], []]
	var held := []
	for s in RUNS:
		var b := burst("ak47", s + 1, false, 12)
		for k in 4:
			cols[k].append(b[k + 1])
		for k in range(6, 10):   # a one-second burst: shots 7-10
			held.append(b[k])
	var ok := true
	var txt := ""
	for k in 4:
		var m := _stats(cols[k]).y
		txt += "%.2f/" % m
		ok = ok and absf(m - want[k]) <= want[k] * 0.1
	t.check("recoil: AK hip auto shots 2-5 at %s (spec 1.67/2.62/3.73/5.27 +-10%%)" % txt, ok)
	var h := _stats(held)
	t.check("recoil: AK held from shot 7 %.1f..%.1f (mean %.1f), spec 5.3..9.5" % [h.x, h.z, h.y],
		h.x >= 5.3 - 0.3 and h.z <= 9.5 + 0.3)


static func _hip_rest(t: RangeTest) -> void:
	var rm := _model(5)
	for i in 120:
		rm.update(STEP)
	t.check("recoil: hip at rest, barrel on the hip dot (%.4f deg)" % rm.barrel.length(), rm.barrel.length() < 0.01)
	var def := WeaponDefs.of("ak47")
	rm.shoot(def)
	for i in 600:
		rm.update(STEP)
	t.check("recoil: hip wander gone 10 s after a hip shot (gain %.3f)" % rm.hip.gain(rm._now), rm.hip.gain(rm._now) == 0.0)


static func _determinism(t: RangeTest) -> void:
	var a := burst("ak47", 7, false, 30)
	var b := burst("ak47", 7, false, 30)
	var c := burst("ak47", 8, false, 30)
	t.check("recoil: same seed gives the same numbers", a == b)
	t.check("recoil: different seed gives a different pattern", a != c)


static func _every_gun(t: RangeTest) -> void:
	var ok := true
	for id in WeaponDefs.ORDER:
		var r := single(id, 3, false)
		ok = ok and r[0] > 0.0 and r[2] > 0.0 and r[3] > 0.0
	t.check("recoil: every gun kicks (muzzle, back, camera)", ok)
	var ak: float = TacRecoilDefs.row("ak47")["force_up"]
	t.check("recoil: M4A1 kicks less than the AK, PKM more", TacRecoilDefs.row("m4a1")["force_up"] < ak and TacRecoilDefs.row("pkm")["force_up"] > ak)


static func probe() -> void:
	for id in ["ak47", "m4a1", "pkm", "glock18"]:
		for aimed in [false, true]:
			var s: Array = []
			for k in 5:
				s.append([])
			for i in RUNS:
				var r := single(id, i + 1, aimed)
				for k in 5:
					s[k].append(r[k])
			var line := ""
			for k in 5:
				line += "%s " % str(_stats(s[k]))
			print("[probe] %s %s single peak/t/back/cam/0.5s: %s" % [id, "aim" if aimed else "hip", line])
			var m := []
			for k in 12:
				m.append([])
			for i in RUNS:
				var b := burst(id, i + 1, aimed, 12)
				for k in 12:
					m[k].append(b[k])
			var row := ""
			for k in 12:
				row += "%.2f " % _stats(m[k]).y
			print("[probe] %s %s auto mean per shot: %s" % [id, "aim" if aimed else "hip", row])
