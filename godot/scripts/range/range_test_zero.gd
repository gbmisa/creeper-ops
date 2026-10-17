class_name RangeTestZero
## F142: every gun x every optic it accepts, at full ADS (1920x1080): (a) the reticle centre projects within TOL_PX of the
## screen centre, (b) the bullet at the gun's zero distance (launched from the eye along the zeroed bore) lands within
## TOL_PX of the reticle. Magnified optics have no glass quad: their reticle is the lens axis at the eye-side end.

const TOL_PX := 2.0
const SCREEN := Vector2(1920, 1080)
const OPTICS := ["reddot", "holo", "acog3x", "lpvo", "scope8x"]


## Pixels from screen centre for a camera-space point at vertical field of view `fov` (deg).
static func px(c: Vector3, fov: float) -> Vector2:
	var k := SCREEN.y * 0.5 / tan(deg_to_rad(fov) * 0.5)
	return Vector2(c.x, -c.y) / -c.z * k


## [{gun, optic, a, b}] for every setup; `log` receives one line per setup.
static func measure(r: Dictionary) -> Array:
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var cam: Camera3D = (r["player"] as TacticalPlayer).cam
	var out := []
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		for s in OPTICS:
			if AttachmentDefs.why_not(def, s) != "":
				continue
			var g := RangeTestAttach._equip(r, id, [s])
			if g.fit.get("sight", "") != s:
				g.set_fit("sight", s)
			RangeTestAds._snap_ads(w, vm)
			var fov := PlayerWeapons.fov_for(1.0, g.stat("scope"))
			var inv := cam.global_transform.affine_inverse()
			var ret: Vector3
			if vm.rig.glass != null:
				ret = inv * vm.rig.glass.global_position
			else:
				ret = inv * (vm.model.global_transform * AdsPose.points(vm._gun.def, s, vm.half_len)[0])
			var ammo: String = g.loaded_ammo() if g.loaded_ammo() != "" else g.ammo_pick
			var d := g.zero_dist()
			var elev := Ballistics.zero_angle(ammo, d)
			var bullet := Vector3(0, Ballistics.height_at(ammo, elev, d), -(0.3 + d))
			var pa := px(ret, fov)
			out.append({"gun": id, "optic": s, "a": pa.length(), "b": (px(bullet, fov) - pa).length()})
	return out


static func run(t: RangeTest, r: Dictionary) -> void:
	var rows := measure(r)
	var bad := []
	var worst := 0.0
	for row in rows:
		worst = maxf(worst, maxf(row["a"], row["b"]))
		if row["a"] > TOL_PX or row["b"] > TOL_PX:
			bad.append("%s+%s a=%.2f b=%.2f px" % [row["gun"], row["optic"], row["a"], row["b"]])
		if OS.get_environment("ZERO_TABLE") != "":
			print("[zero] %s+%s a=%.2f b=%.2f" % [row["gun"], row["optic"], row["a"], row["b"]])
	t.check("zero: %d gun x optic setups: reticle on screen centre and bullet at zero range on the reticle (worst %.2f px, limit %.0f)" % [rows.size(), worst, TOL_PX],
		bad.is_empty() and rows.size() > 20, str(bad))
