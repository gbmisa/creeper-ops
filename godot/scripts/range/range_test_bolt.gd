class_name RangeTestBolt
## FB-F: the Mosin's bolt cycle. Fire -> needs_cycle -> cycle, then the bolt/handle bone poses and the right hand are
## sampled through a full BoltCycle; the AXMC (baked clip / no Bolt bone) gets none.

static func _glb(id: String) -> Node3D:
	return (load("res://assets/models/guns/%s.glb" % WeaponDefs.of(id)["model"]) as PackedScene).instantiate() as Node3D


static func run(t: RangeTest) -> void:
	var def := WeaponDefs.of("mosin")
	var g := Gun.new("mosin")
	g.durability = 1.0
	g.ammo_pick = TacAmmoDefs.grades(def["cal"])[0]
	var rng := RandomNumberGenerator.new()
	g.fire(rng)
	t.check("bolt: mosin fire sets needs_cycle", g.needs_cycle)
	g.fire_cd = 0.0
	g.release()
	g.update(0.01)
	t.check("bolt: released trigger starts the cycle (busy kind cycle, %.1f s)" % def["cycle"], g.busy_kind == "cycle" and g.busy_t > float(def["cycle"]) - 0.05 and g.eff_def().has("bolt_knob"))
	var cam := Node3D.new()
	t.add_child(cam)
	var arms := FpArms.new()
	cam.add_child(arms)
	var gun := Node3D.new()
	cam.add_child(gun)
	var glb := _glb("mosin")
	gun.add_child(glb)
	var bc := BoltCycle.make(glb, def)
	t.check("bolt: mosin model gets a BoltCycle", bc != null)
	if bc == null:
		cam.free()
		return
	arms.set_gun(def)
	arms.bolt = bc
	var half := (glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_aabb().size.z * 0.5
	gun.position = TacticalViewmodel.base_pos(def, half, 0.0)
	var rest_b := bc.skel.get_bone_pose_position(bc.bolt)
	var rest_hq := bc.skel.get_bone_pose_rotation(bc.handle)
	bc.start(def["cycle"])
	var max_z := 0.0
	var max_ang := 0.0
	var mid_err := 1.0
	var mid_t := 0.0
	var secs: float = def["cycle"]
	var steps := int(secs * 60.0) + 2
	for i in steps:
		bc.update(1.0 / 60.0)
		arms.update(gun, 1.0 / 60.0)
		var z := bc.skel.get_bone_pose_position(bc.bolt).z - rest_b.z
		max_z = maxf(max_z, z)
		max_ang = maxf(max_ang, rad_to_deg(rest_hq.angle_to(bc.skel.get_bone_pose_rotation(bc.handle))))
		var err := arms.hand_pos("r").distance_to(gun.global_transform * bc.knob_now())
		if absf(bc.t - 0.5) < absf(mid_t - 0.5) or i == 0:
			mid_t = bc.t
			mid_err = err
	var end_b := (bc.skel.get_bone_pose_position(bc.bolt) - rest_b).length()
	t.check("bolt: bolt slides back >= 7 cm (%.3f m)" % max_z, max_z >= 0.07)
	t.check("bolt: bolt back at rest by the end (%.5f m)" % end_b, end_b < 0.001)
	t.check("bolt: handle lifts >= 70 deg (%.0f)" % max_ang, max_ang >= 70.0)
	t.check("bolt: handle back at rest by the end", rest_hq.angle_to(bc.skel.get_bone_pose_rotation(bc.handle)) < 0.001)
	t.check("bolt: right hand within 3 cm of the knob mid-stroke (%.1f cm)" % (mid_err * 100.0), mid_err < 0.03)
	var grip_err := arms.hand_pos("r").distance_to(arms.target["r"])
	var back := arms.hand_pos("r").distance_to(gun.global_transform * (def["grip_r"] as Vector3))
	t.check("bolt: right hand back within 2 cm of grip_r after (%.1f cm, solve %.1f)" % [back * 100.0, grip_err * 100.0], back < 0.02)
	t.check("bolt: roll is zero when idle", bc.roll() == 0.0 and not bc.playing())
	cam.free()
	var ax := _glb("sniper")
	t.check("bolt: AXMC gets no procedural cycle", BoltCycle.make(ax, WeaponDefs.of("sniper")) == null)
	ax.free()
