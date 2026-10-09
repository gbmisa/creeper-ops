class_name ArmModels
## The Operative's arms: an olive combat sleeve with a dark armour bracer, a black glove on the
## grip, and (for two-handed weapons) the off hand on the foregrip. Built into each weapon's
## model node, so the arms kick, sway and hide with the weapon. Model units: the gun node is
## scaled 0.4, so the far ends of the sleeves sit off the bottom of the screen.

## id -> { grip: right hand, fore: left hand (INF.x = none) }
const POSES := {
	"rifle": { "grip": Vector3(0, -0.1, 0.13), "fore": Vector3(0, -0.075, -0.15) },
	"crossbow": { "grip": Vector3(0, -0.1, 0.15), "fore": Vector3(0, -0.035, -0.1) },
	"sprayer": { "grip": Vector3(0, -0.1, 0.1), "fore": Vector3(0.01, 0.02, -0.12) },
	"rocket": { "grip": Vector3(0, -0.1, 0.06), "fore": Vector3(0, -0.06, -0.12) },
}
const RIGHT_ELBOW := Vector3(0.28, -0.62, 1.35)
const LEFT_ELBOW := Vector3(-0.9, -0.55, 1.2)


static func add(model: Node3D, id: String) -> void:
	var pose: Dictionary = POSES[id]
	var arms := Node3D.new()
	arms.name = "arms"
	model.add_child(arms)
	_arm(arms, pose.grip, RIGHT_ELBOW, true, "hand_r")
	_arm(arms, pose.fore, LEFT_ELBOW, false, "hand_l")


static func _arm(parent: Node3D, hand: Vector3, elbow: Vector3, grips: bool, hand_id: String) -> void:
	var cloth := StructureMeshes.mat(Color("3b4126"), 0.0, 0.85)
	var leather := StructureMeshes.mat(Color("1d1e1a"), 0.0, 0.6)
	var bronze := StructureMeshes.mat(Color("3a3f2c"), 0.3, 0.5)  # armour bracer
	var dir := (elbow - hand).normalized()
	var wrist := hand + dir * 0.06
	ShapeKit.taper(parent, wrist, elbow, 0.04, 0.095, cloth, 8)
	ShapeKit.taper(parent, wrist, wrist + dir * 0.15, 0.044, 0.05, bronze, 8)  # bracer
	var cuff := ShapeKit.taper(parent, wrist + dir * 0.15, wrist + dir * 0.17, 0.056, 0.056, bronze, 8)
	cuff.name = "cuff"
	# Glove: palm block, fingers wrapped over the grip, thumb. Wrapped in a named node so
	# CrossbowFx can animate the off hand drawing the string during a reload.
	var hn := Node3D.new()
	hn.name = hand_id
	hn.position = hand
	parent.add_child(hn)
	StructureMeshes.box(hn, Vector3(0.07, 0.055, 0.085), leather, Vector3.ZERO)
	var f := StructureMeshes.box(hn, Vector3(0.075, 0.02, 0.07), leather, Vector3(0, 0.0, -0.05))
	f.rotation.x = 0.15 if grips else 0.0
	var thumb := StructureMeshes.box(hn, Vector3(0.022, 0.02, 0.06), leather, Vector3(0.0, 0.04, -0.01))
	thumb.rotation.x = -0.3
