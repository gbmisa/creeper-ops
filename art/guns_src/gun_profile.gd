extends SceneTree
## Top profile of each gun in gun space (as TacticalViewmodel loads it): for every 1 cm slice from the butt plate
## forward, the highest vertex within CENTRE m of the bore line. Prints "@@ id half=… back=…" then "d_cm:y_mm(x_mm)".
## godot --headless --path godot -s ../art/guns_src/gun_profile.gd -- id...
const CENTRE := 0.012


func _process(_d):
	for id in OS.get_cmdline_user_args():
		var def := WeaponDefs.of(id)
		var glb := (load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene).instantiate() as Node3D
		root.add_child(glb)
		if def.get("flip", false):
			glb.rotation.y = PI
		var mis := glb.find_children("*", "MeshInstance3D", true, false)
		var half := (mis[0] as MeshInstance3D).get_aabb().size.z * 0.5
		var top := {}
		var back := -INF
		for m in mis:
			var mi := m as MeshInstance3D
			var xf := glb.global_transform.affine_inverse() * mi.global_transform
			if true:
				for v in mi.mesh.get_faces():  # decompressed positions (surface arrays can be compressed)
					var p: Vector3 = xf * v
					back = maxf(back, p.z)
					if absf(p.x) > CENTRE:
						continue
					var b := int(floor(p.z * 100.0))
					if not top.has(b) or top[b].y < p.y:
						top[b] = p
		var line := []
		var ks := top.keys()
		ks.sort()
		ks.reverse()
		for b in ks:
			var p: Vector3 = top[b]
			line.append("%d:%d(%d)" % [roundi((back - p.z) * 100.0), roundi(p.y * 1000.0), roundi(p.x * 1000.0)])
		print("@@ %s half=%.3f back=%.3f iron_y=%.4f" % [id, half, back, AttachmentMounts.iron_y(def)])
		print(" ".join(line))
		glb.free()
	quit()
	return true
