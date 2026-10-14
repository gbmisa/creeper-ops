class_name RangeRack
extends Node3D
## Wall rack with the six guns. pick() chooses the gun nearest the player's view ray; take() hides it.

const TIER_Y := 0.75
const TIER_STEP := 0.3
const REACH := 3.2

var taken := {}
var _slots := {}  # id -> Node3D


func _init() -> void:
	name = "WeaponRack"
	position = RangeLayout.RACK_POS
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 1.9, 0.06)
	board.mesh = bm
	board.material_override = RangeLayout.colour(Color(0.25, 0.2, 0.15))
	board.position = Vector3(0.5, TIER_Y + 0.72, 0.1)
	add_child(board)
	var i := 0
	for id in WeaponDefs.ORDER:
		var holder := Node3D.new()
		holder.position = Vector3(0, TIER_Y + TIER_STEP * i, 0)
		holder.rotation_degrees.y = 90.0
		add_child(holder)
		var glb := load("res://assets/models/guns/%s.glb" % WeaponDefs.of(id)["model"]) as PackedScene
		var gun := glb.instantiate() as Node3D
		if WeaponDefs.of(id).get("flip", false):
			gun.rotation.y = PI
		holder.add_child(gun)
		var l := Label3D.new()
		l.text = "%d %s" % [i + 1, WeaponDefs.of(id)["name"]]
		l.pixel_size = 0.0035
		l.font_size = 48
		l.rotation_degrees.y = 180.0  # the player looks toward +Z
		add_child(l)
		l.position = Vector3(1.15, TIER_Y + TIER_STEP * i, -0.05)
		_slots[id] = holder
		i += 1


func slot_point(id: String) -> Vector3:
	return (_slots[id] as Node3D).global_position


## Id of the untaken gun closest to the view ray, or "" if out of reach / none left.
func pick(eye: Vector3, forward: Vector3) -> String:
	var best := ""
	var best_d := 0.6
	for id in _slots:
		if taken.has(id):
			continue
		var p := slot_point(id)
		if p.distance_to(eye) > REACH:
			continue
		var d := Vector3(p - eye).cross(forward).length()
		if d < best_d and (p - eye).dot(forward) > 0.0:
			best_d = d
			best = id
	return best


func take(id: String) -> void:
	taken[id] = true
	(_slots[id] as Node3D).visible = false


func reset() -> void:
	taken.clear()
	for id in _slots:
		(_slots[id] as Node3D).visible = true
