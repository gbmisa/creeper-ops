class_name StagingFigure
extends Node3D
## F140: the body shown on a mannequin: BotMesh (the soldier model, grey) holding the preset's primary, plus simple
## boxes for the worn helmet / armor / rig / backpack and the secondary / holster guns. Faces -Z in its own frame; the mannequin turns it toward the room.

const GREY := Color(0.55, 0.56, 0.58)
const GEAR := {   # slot -> [centre on the body (y up, z toward the back), size, colour]
	"helmet": [Vector3(0, 1.71, 0.0), Vector3(0.3, 0.2, 0.34), Color(0.2, 0.26, 0.2)],
	"armor": [Vector3(0, 1.32, -0.02), Vector3(0.42, 0.5, 0.26), Color(0.18, 0.2, 0.28)],
	"rig": [Vector3(0, 1.1, -0.04), Vector3(0.44, 0.22, 0.3), Color(0.32, 0.27, 0.16)],
	"backpack": [Vector3(0, 1.3, 0.24), Vector3(0.36, 0.5, 0.22), Color(0.22, 0.3, 0.18)],
	"headset": [Vector3(0, 1.62, 0.0), Vector3(0.36, 0.08, 0.1), Color(0.08, 0.08, 0.08)],
}
var mesh: BotMesh
var _ticks := 3   # the pose is solved a few frames after entering the tree, then the figure stands still


## `kit` = Inventory.to_dict() of the preset ({} = nothing saved: a bare body).
func setup(kit: Dictionary) -> void:
	var inv := Inventory.from_dict(kit) if not kit.is_empty() else Inventory.new()
	var gun_id := ""
	for s in PlayerWeapons.HAND_SLOTS:
		var it = inv.equipped(s)
		if it != null and it.has("gun"):
			gun_id = it["id"]
			break
	mesh = BotMesh.new({"gun": gun_id if gun_id != "" else "ak47", "uniform": GREY})
	mesh.gun.visible = gun_id != ""
	add_child(mesh)
	for slot in GEAR:
		var it = inv.equipped(slot)
		if it != null:
			_gear(slot, it)
	for slot in ["secondary", "holster"]:   # slung / holstered guns, shown as dark boxes
		var it = inv.equipped(slot)
		if it != null and it.has("gun"):
			var big: bool = slot == "secondary"
			_box(Vector3(-0.1 if big else 0.2, 1.2 if big else 0.9, -0.2 if big else 0.0), Vector3(0.06, 0.06, 0.7) if big else Vector3(0.05, 0.14, 0.1), Color(0.08, 0.08, 0.09))


func _gear(slot: String, it: Dictionary) -> void:
	var g: Array = GEAR[slot]
	var size: Vector3 = g[1]
	var col: Color = g[2]
	if slot == "rig":
		col = col.lightened(0.15) if it["id"] == "rig_assault" else col
	if slot == "backpack" and it["id"] == "pack_big":
		size *= 1.3
	_box(g[0], size, col)


func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = RangeLayout.colour(col)
	mi.position = pos
	add_child(mi)


func _process(dt: float) -> void:
	if _ticks > 0:
		_ticks -= 1
		mesh.walk(dt, 0.0)
