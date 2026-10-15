class_name CreatureLod
## Level of detail for animated creatures (CreatureAnim models). By distance to the active
## camera, every frame:
##   near and on screen: clips run every frame, casts shadows
##   mid:                clips stepped at CREATURE_LOD_MID_HZ, no shadow
##   far or off screen:  clips stepped at CREATURE_LOD_FAR_HZ, no shadow
## Each model is 6+ surfaces drawn again per shadow cascade, so the shadow cut is most of
## the draw-call saving; the stepped clips save skeleton updates.

const GROUP := "creature_lod"
const SHADOW_ON := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
const SHADOW_OFF := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Called by CreatureAnim.make for every model that has an AnimationPlayer.
static func register(node: Node3D, player: AnimationPlayer) -> void:
	var meshes: Array[GeometryInstance3D] = []
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n := stack.pop_back() as Node
		if n is GeometryInstance3D:
			meshes.append(n)
		stack.append_array(n.get_children())
	node.set_meta("_lod_meshes", meshes)
	node.set_meta("_lod_tier", -1)
	node.set_meta("_lod_acc", 0.0)
	node.add_to_group(GROUP)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


static func tick(tree: SceneTree, cam: Camera3D, dt: float) -> void:
	if cam == null:
		return
	var eye := cam.global_position
	var near2 := Config.CREATURE_LOD_NEAR * Config.CREATURE_LOD_NEAR
	var far2 := Config.CREATURE_LOD_FAR * Config.CREATURE_LOD_FAR
	for n in tree.get_nodes_in_group(GROUP):
		var node := n as Node3D
		if not node.is_visible_in_tree():
			continue
		var pos := node.global_position
		var d2 := eye.distance_squared_to(pos)
		var tier := 2
		if cam.is_position_in_frustum(pos):
			tier = 0 if d2 < near2 else (1 if d2 < far2 else 2)
		_step(node, tier, dt)


static func _step(node: Node3D, tier: int, dt: float) -> void:
	var p := node.get_meta("_anim_player") as AnimationPlayer
	if p == null:
		return
	if tier != int(node.get_meta("_lod_tier")):
		node.set_meta("_lod_tier", tier)
		for m: GeometryInstance3D in node.get_meta("_lod_meshes"):
			if is_instance_valid(m):
				m.cast_shadow = SHADOW_ON if tier == 0 else SHADOW_OFF
	var acc: float = float(node.get_meta("_lod_acc")) + dt
	var period := 0.0
	if tier == 1:
		period = 1.0 / Config.CREATURE_LOD_MID_HZ
	elif tier == 2:
		period = 1.0 / Config.CREATURE_LOD_FAR_HZ
	if acc >= period:
		p.advance(acc)  # speed_scale (walk speed, pause freeze) still applies
		acc = 0.0
	node.set_meta("_lod_acc", acc)
