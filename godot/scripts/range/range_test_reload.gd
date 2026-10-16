class_name RangeTestReload
## FB-R: procedural reloads (ReloadTimeline). Per gun with a ReloadAnims rig, plain / fast / empty: the timeline
## lasts the logic's reload time, the Mag node leaves the gun and comes back seated, the marks fire, the left wrist
## stays on its target (within IK reach) every frame, the bolt/slide starts home and the mag never teleports, and at the end both hands are on their grips and the bolt or
## slide (bone or region-cut part) is home. The split leaves the gun mesh's AABB as the glb had it.

const IDS := ["ak47", "m1911", "glock18", "mp5", "p90"]
const STEP := 1.0 / 60.0


static func run(t: RangeTest) -> void:
	for id in IDS:
		for v in [["plain", false, false], ["fast", true, false], ["empty", false, true]]:
			_one(t, id, v[0], v[1], v[2])


static func _one(t: RangeTest, id: String, label: String, fast: bool, empty: bool) -> void:
	var def := WeaponDefs.of(id)
	var g := Gun.new(id)
	var secs := g.stat("reload_fast") if fast else g.stat("reload")
	if empty:
		secs += TacticalConfig.CHAMBER_TIME
	var cam := Node3D.new()
	t.add_child(cam)
	var arms := FpArms.new()
	cam.add_child(arms)
	var gun := Node3D.new()
	cam.add_child(gun)
	var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
	var aabb0 := (glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_aabb()
	gun.add_child(glb)
	if def.get("flip", false):
		glb.rotation.y = PI
	var tl := ReloadTimeline.make(glb, def)
	var n := "reload %s %s" % [id, label]
	t.check(n + ": gets a timeline + Mag node", tl != null)
	if tl == null:
		cam.free()
		return
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	t.check(n + ": gun AABB unchanged by the split", mi.get_aabb().is_equal_approx(aabb0))
	arms.set_gun(def)
	arms.reload_tl = tl
	gun.position = TacticalViewmodel.base_pos(def, aabb0.size.z * 0.5, 0.0)
	var seat := tl.mag.transform
	var bone_rest := tl.skel.get_bone_global_pose(tl.bone) if tl.bone >= 0 else Transform3D.IDENTITY
	var part_rest := tl.part.transform if tl.part != null else Transform3D.IDENTITY
	if ReloadAnims.rig(def).has("bolt_box"):
		t.check(n + ": slide cut out as its own part", tl.part != null)
	var marks: Array[String] = []
	tl.mark.connect(func(m: String): marks.append(m))
	tl.start(secs, empty, fast)
	t.check(n + ": lasts the logic's %.2f s (%.3f)" % [secs, tl.len], absf(tl.len - secs) < 0.001)
	t.check(n + ": bolt / slide starts home, no pop (%.3f)" % tl.bolt, tl.bolt < 0.001)
	var jump := 0.0  # largest one-frame step of the mag (a dropped or swapped mag must travel, not teleport)
	var last := tl.mag_xf.origin
	var far := 0.0
	var err := 0.0
	var steps := 0
	while tl.playing() and steps < 1000:
		tl.update(STEP)
		arms.update(gun, STEP)
		far = maxf(far, (tl.mag_xf.origin).length())
		jump = maxf(jump, tl.mag_xf.origin.distance_to(last))
		last = tl.mag_xf.origin
		if tl.playing():
			err = maxf(err, arms.hand_pos("l").distance_to(arms.target["l"]))
		steps += 1
	arms.update(gun, STEP)
	t.check(n + ": the mag leaves the gun (%.2f m)" % far, far >= 0.08)
	t.check(n + ": the mag never teleports: < 10 cm a frame, a dropped one falls ~3-4 m/s (%.3f m)" % jump, jump < 0.10)
	t.check(n + ": left wrist on its target every frame (worst %.3f m)" % err, err < 0.02)
	var need := ["mag_out", "mag_in"] + (["charged"] if empty else [])
	t.check(n + ": marks %s" % [marks], need.all(func(m): return m in marks))
	t.check(n + ": mag back seated", tl.mag.transform.is_equal_approx(seat))
	if tl.bone >= 0:
		t.check(n + ": bolt / slide home", tl.skel.get_bone_global_pose(tl.bone).origin.distance_to(bone_rest.origin) < 0.0001)
	if tl.part != null:
		t.check(n + ": slide part home", tl.part.transform.is_equal_approx(part_rest))
	var gt := gun.global_transform
	var dl: float = arms.target["l"].distance_to(gt * (def["grip_l"] as Vector3))
	var dr: float = arms.target["r"].distance_to(gt * (def["grip_r"] as Vector3))
	t.check(n + ": hands back on their grips (%.4f / %.4f m)" % [dl, dr], dl < 0.001 and dr < 0.001)
	cam.free()
