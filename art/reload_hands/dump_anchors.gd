extends SceneTree
## F102: dumps every reload rig's left-hand anchors (gun-model space, Godot axes) to art/reload_hands/anchors.json
## for build_hands.py. Run: godot --headless --path godot -s ../art/reload_hands/dump_anchors.gd
func _init() -> void:
	var out := {}
	for key in ReloadRigs.RIGS:
		var rig: Dictionary = ReloadRigs.RIGS[key]
		var def := {}
		for id in WeaponDefs.ROWS:
			if str(WeaponDefs.of(id).get("model", id)) == key:
				def = WeaponDefs.of(id)
				break
		var anchors := {}
		var pts := {"mag": rig.get("hold"), "charge": rig.get("charge")}
		for k in rig:
			if str(k).ends_with("_hand"):
				pts[str(k).trim_suffix("_hand")] = rig[k]
		for a in pts:
			if not pts[a] is Vector3:
				continue
			var hd: Dictionary = rig.get("hands", {}).get(a, ReloadAnims.HANDS.get(a, {}))
			if hd.is_empty():
				continue
			anchors[a] = {"p": _v(pts[a]), "f": _v(hd["f"]), "n": _v(hd["n"])}
		var g: Vector3 = def.get("grip_l", Vector3.ZERO)
		var pistol: bool = def.get("class", "") == "pistol"
		out[key] = {"glb": "godot/assets/models/guns/%s.glb" % key, "flip": def.get("flip", false), "plan": rig["plan"],
			"pivot": _v(rig.get("pivot", Vector3.ZERO)), "anchors": anchors,
			"grip": {"p": _v(g), "f": [0, 0, -1], "n": [1, 0, 0] if pistol else [0, 1, 0]}}
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../art/reload_hands/anchors.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	print("dumped ", out.size())
	quit()

func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
