class_name CastleEngineMeshes
## Trebuchet model for CastleEngines: the animated `assets/models/trebuchet.glb`
## (wind-up-and-throw "attack" clip) when present, else a procedural oak A-frame
## on a stone plinth with a tweened throwing arm. `throw` swings the arm toward
## a target (model: plays the attack clip; procedural: a short tween).


## `tint` is the glow colour: enemy engines by default, player blue for the Trebuchet.
static func trebuchet(tint: Color = StrongholdMeshes.ENEMY) -> Node3D:
	var glow := StructureMeshes.glow(tint, 1.8)
	var anim := CreatureAnim.make("trebuchet", 1.0, glow)
	if anim != null:
		anim.name = "Trebuchet"
		anim.set_meta("tint", tint)
		return anim
	var root := Node3D.new()
	root.name = "Trebuchet"
	root.set_meta("tint", tint)
	var oak := StructureMeshes.pal("oak")
	var bronze := StructureMeshes.pal("bronze")
	var stone := StructureMeshes.mat(StrongholdMeshes.DECOR_STONE, 0.0, 0.92)
	StructureMeshes.box(root, Vector3(2.6, 0.4, 2.6), stone, Vector3(0, 0.2, 0))
	for sx in [-0.9, 0.9]:  # two A-frames holding the axle
		ShapeKit.strut(root, Vector3(sx, 0.4, -1.0), Vector3(sx, 3.0, 0), 0.12, oak)
		ShapeKit.strut(root, Vector3(sx, 0.4, 1.0), Vector3(sx, 3.0, 0), 0.12, oak)
	ShapeKit.strut(root, Vector3(-1.0, 3.0, 0), Vector3(1.0, 3.0, 0), 0.1, bronze)
	var arm := Node3D.new()
	arm.name = "Arm"
	arm.position = Vector3(0, 3.0, 0)
	arm.rotation.x = -0.9  # cocked: long end down at the back
	root.add_child(arm)
	ShapeKit.strut(arm, Vector3(0, 0, 1.0), Vector3(0, 0, -3.4), 0.11, oak)
	StructureMeshes.box(arm, Vector3(0.9, 0.9, 0.9), bronze, Vector3(0, -0.5, 1.1))
	StructureMeshes.ball(arm, 0.32, stone, Vector3(0, -0.4, -3.4), 8)
	var glow_ball := StructureMeshes.ball(root, 0.22, glow, Vector3(0, 3.5, 0), 8)
	glow_ball.name = "Glow"
	return root


## Turn toward the target and swing the arm over, then let it settle back.
## Animated .glb (no "Arm" node): plays the wind-up-and-throw "attack" clip.
static func throw(node: Node3D, at: Vector3) -> void:
	var d := at - node.position
	node.rotation.y = atan2(-d.x, -d.z)
	var arm := node.get_node_or_null("Arm") as Node3D
	if arm == null:
		CreatureAnim.attack(node)  # re-trigger safe; no-op on procedural nodes
		return
	if not node.is_inside_tree():
		return
	var tw := node.create_tween()
	tw.tween_property(arm, "rotation:x", 1.1, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(arm, "rotation:x", -0.9, 2.5).set_trans(Tween.TRANS_SINE)
