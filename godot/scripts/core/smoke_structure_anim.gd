class_name SmokeStructureAnim
## ART3 track A4 checks: player weapons (cannon/mortar/sniper/beam, 3 parts each),
## collector and relay use the animated .glb models when the files exist, with all
## 5 clips; Turret/Arm/Muzzle keep their procedural transforms; CreatureAnim.disabled
## falls back to procedural meshes. Called from SmokeTest.run.


static func run(g) -> void:
	_model_presence()
	_weapon_pivots()
	_disabled_fallback()


## Each of the 6 structures gets its model(s) exactly when the .glb files exist,
## and every part carries all 5 clips (idle, walk, attack, hit, die).
static func _model_presence() -> void:
	var ids := {
		"cannon": ["cannon_base", "cannon_turret", "cannon_arm"],
		"mortar": ["mortar_base", "mortar_turret", "mortar_arm"],
		"sniper": ["sniper_base", "sniper_turret", "sniper_arm"],
		"beam": ["beam_base", "beam_turret", "beam_arm"],
		"collector": ["collector"],
		"relay": ["relay"],
	}
	for type in ids:
		var want := true
		for mid in ids[type]:
			if not ResourceLoader.exists(CreatureAnim.MODEL_DIR + mid + ".glb"):
				want = false
		var root := StructureMeshes.make(type)
		var parts: Array = root.get_meta("_anim_parts", [])
		var want_n: int = ids[type].size() if want else 0
		var ok: bool = parts.size() == want_n
		if want:
			for part in parts:
				var p := _find_player(part)
				if p == null:
					ok = false
					continue
				for clip in ["idle", "walk", "attack", "hit", "die"]:
					if not p.has_animation(clip):
						ok = false
		SmokeTest._check("structure anim: " + type + " models match .glb presence", ok)
		root.queue_free()


## A weapon with models still has Turret, Arm and Muzzle at the procedural
## positions (within 1 cm), so WeaponLogic aims them unchanged.
static func _weapon_pivots() -> void:
	var ok := true
	for type in ["cannon", "mortar", "sniper", "beam"]:
		var proc := Node3D.new()
		WeaponMeshes.build(type, proc)
		var with_models := StructureMeshes.make(type)
		for part_name in ["Turret", "Arm", "Muzzle"]:
			var a := proc.find_child(part_name, true, false) as Node3D
			var b := with_models.find_child(part_name, true, false) as Node3D
			if a == null or b == null or a.position.distance_to(b.position) > 0.01:
				ok = false
		proc.queue_free()
		with_models.queue_free()
	SmokeTest._check("structure anim: weapon pivots match procedural within 1 cm", ok)


## With CreatureAnim.disabled, the procedural meshes are used (no model swap).
static func _disabled_fallback() -> void:
	CreatureAnim.disabled = true
	var ok := true
	for type in ["cannon", "collector", "relay"]:
		var root := StructureMeshes.make(type)
		var has_mesh := not root.find_children("*", "MeshInstance3D", true, false).is_empty()
		if root.has_meta("_anim_parts") or not has_mesh:
			ok = false
		root.queue_free()
	CreatureAnim.disabled = false
	SmokeTest._check("structure anim: disabled falls back to procedural", ok)


static func _find_player(n: Node) -> AnimationPlayer:
	var found := n.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if not found.is_empty() else null
