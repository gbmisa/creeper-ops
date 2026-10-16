class_name RangeTestAds
## FB-H: the ADS rule. Every gun x {irons, each sight that fits}: at full ADS (bob, kick and recoil off) the rear and
## front sight points sit on the camera's forward axis and a point straight under the rear sight shows no cant.

const TOL_DEG := 0.02


static func run(t: RangeTest, r: Dictionary) -> void:
	_math(t)
	var w: PlayerWeapons = r["w"]
	var vm: TacticalViewmodel = r["vm"]
	var cam: Camera3D = (r["player"] as TacticalPlayer).cam
	var worst := 0.0
	var bad := []
	var n := 0
	for id in WeaponDefs.ORDER:
		var def := WeaponDefs.of(id)
		var fits: Array = [""]
		for s in ["reddot", "holo", "acog3x", "lpvo", "scope8x"]:
			if AttachmentDefs.why_not(def, s) == "":
				fits.append(s)
		for sid in fits:
			var g := RangeTestAttach._equip(r, id, [] if sid == "" else [sid])
			if sid == "":
				g.clear_fit("sight")  # the P90 ships with a red dot: take it off to test its (missing) irons
			elif g.fit.get("sight", "") != sid:
				g.set_fit("sight", sid)  # the inventory grid refuses sights on pistols; the rule does not care
			_snap_ads(w, vm)
			if AdsPose.points(vm._def, sid, vm.half_len).is_empty():
				t.check("ads: %s has no irons: falls back to ads_pos" % id, not vm._ads_ok and sid == "")
				continue
			var e := _error(vm, cam, sid)
			n += 1
			worst = maxf(worst, e)
			if e > TOL_DEG:
				bad.append("%s+%s %.3f deg" % [id, sid, e])
	t.check("ads: %d gun x sight setups aligned rear/front on the camera axis, no cant (worst %.4f deg, limit %.2f)" % [n, worst, TOL_DEG],
		bad.is_empty() and n > 30, str(bad))
	_clip(t, r)


static func _snap_ads(w: PlayerWeapons, vm: TacticalViewmodel) -> void:
	w.recoil.offset = Vector2.ZERO
	w.recoil.barrel = Vector2.ZERO
	w.trigger_ads = false
	w.ads_amt = 1.0
	w.draw_t = 0.0
	vm._kick = 0.0
	vm._kick_v = 0.0
	vm._check = 0.0
	vm._process(1.0)  # the first call may rebuild the rig for the new fit
	vm._process(1.0)  # delta 1.0 snaps the pose lerps


## Worst angle (deg): rear and front off the camera forward, and the cant of a point 5 cm under the rear sight.
static func _error(vm: TacticalViewmodel, cam: Camera3D, sid: String) -> float:
	var p := AdsPose.points(vm._def, sid, vm.half_len)
	var inv := cam.global_transform.affine_inverse()
	var to_cam := func(q: Vector3) -> Vector3: return inv * (vm.model.global_transform * q)
	var ang := func(c: Vector3) -> float: return rad_to_deg(atan2(Vector2(c.x, c.y).length(), -c.z))
	var rear: Vector3 = to_cam.call(p[0])
	var below: Vector3 = to_cam.call(p[0] + Vector3(0, -0.05, 0))
	var cant := rad_to_deg(atan2(absf(below.x), -below.z))
	return maxf(maxf(ang.call(rear), ang.call(to_cam.call(p[1]))), cant)


static func _math(t: RangeTest) -> void:
	var rear := Vector3(0.01, 0.1, 0.2)
	var front := Vector3(0.012, 0.105, -0.3)
	var x := AdsPose.solve(rear, front, 0.15)
	var d := (x.basis * (front - rear)).normalized()
	t.check("ads math: front - rear maps onto -Z", d.distance_to(Vector3(0, 0, -1)) < 1e-5)
	t.check("ads math: rear lands at (0, 0, -relief)", (x * rear).distance_to(Vector3(0, 0, -0.15)) < 1e-5)
	t.check("ads math: front lands on the axis", Vector2((x * front).x, (x * front).y).length() < 1e-5)
	t.check("ads math: zero roll (the gun's sideways axis stays level)", absf((x.basis * Vector3.RIGHT).y) < 1e-5 and absf(x.basis.get_euler().z) < 1e-5)
	var id := AdsPose.solve(Vector3(0, 0.1, 0.1), Vector3(0, 0.1, -0.4), 0.2)
	t.check("ads math: level sights give no rotation", id.basis.is_equal_approx(Basis.IDENTITY))
	t.check("ads relief: every kind in use has a value", ["pistol", "pistol_optic", "notch", "aperture", "optic", "scope"].all(func(k): return TacticalConfig.ADS_RELIEF.has(k)))
	var mosin := WeaponDefs.of("mosin")  # F58: eye kept clear of the gun (eye_clear.py); only guns that needed it move
	t.check("ads relief: mosin irons keep the eye out of the receiver (relief_min 0.28)", is_equal_approx(AdsPose.relief(mosin, ""), 0.28))
	t.check("ads relief: an optic on the mosin ignores relief_min", is_equal_approx(AdsPose.relief(mosin, "scope8x"), TacticalConfig.ADS_RELIEF["scope"]))
	t.check("ads relief: ak47 irons unchanged by the clearance rule", is_equal_approx(AdsPose.relief(WeaponDefs.of("ak47"), ""), TacticalConfig.ADS_RELIEF["notch"]))


static func _clip(t: RangeTest, r: Dictionary) -> void:
	var vm: TacticalViewmodel = r["vm"]
	RangeTestAttach._equip(r, "m4a1", ["reddot"])
	_snap_ads(r["w"], vm)
	t.check("z-clip: gun materials have z-clip scale on", ViewmodelClip.all_clipped(vm.model.get_child(0)))
	t.check("z-clip: attachment materials have z-clip scale on", ViewmodelClip.all_clipped(vm.rig))
	var arm_meshes := vm.arms.find_children("Arms", "MeshInstance3D", true, false)
	t.check("z-clip: the arms mesh has z-clip scale on", not arm_meshes.is_empty() and arm_meshes.all(func(m): return ViewmodelClip.all_clipped(m)))
	var world := (load("res://assets/models/guns/%s.glb" % WeaponDefs.of("m4a1")["model"]) as PackedScene).instantiate()
	t.check("z-clip: a world copy of the same gun is unaffected", not ViewmodelClip.all_clipped(world))
	world.free()
	t.check("z-clip: camera near stays at its hip value at full ADS", is_equal_approx((r["player"] as TacticalPlayer).cam.near, 0.03))
