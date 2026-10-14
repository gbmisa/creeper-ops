class_name RangeRack
extends Node3D
## Wall rack with every gun, rows = lines, columns = tiers. pick() chooses the gun nearest the player's view ray; take() hides it.

const ROW_Y := 0.5
const ROW_STEP := 0.42
const COL_STEP := 1.8
const REACH := 3.2
## Rows are weapon lines, columns are tiers 1..3 (empty cell = no gun at that tier).
const GRID := [["m1911", "glock18", "revolver"], ["mp5", "p90", "vector"], ["ak47", "m4a1", "scarh"],
	["shotgun", "saiga12", "pkm"], ["sks", "garand", "sr25"], ["mosin", "", "sniper"]]

var taken := {}
var _slots := {}  # id -> Node3D


func _init() -> void:
	name = "WeaponRack"
	position = RangeLayout.RACK_POS
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(COL_STEP * 3.0 + 0.2, ROW_STEP * GRID.size() + 0.1, 0.06)
	board.mesh = bm
	board.material_override = RangeLayout.colour(Color(0.25, 0.2, 0.15))
	board.position = Vector3(0, ROW_Y + ROW_STEP * (GRID.size() - 1) * 0.5, 0.1)
	add_child(board)
	for r in GRID.size():
		for c in 3:
			var id: String = GRID[r][c]
			if id != "":
				_add_gun(id, Vector3((c - 1) * COL_STEP, ROW_Y + ROW_STEP * r, 0.0))


func _add_gun(id: String, at: Vector3) -> void:
	var def := WeaponDefs.of(id)
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = 90.0
	add_child(holder)
	var glb := load("res://assets/models/guns/%s.glb" % def["model"]) as PackedScene
	var gun := glb.instantiate() as Node3D
	if def.get("flip", false):
		gun.rotation.y = PI
	holder.add_child(gun)
	add_child(label_for(def, at + Vector3(0, -0.1, -0.05)))
	_slots[id] = holder


## Name + tier on the first line, role below (wrapped).
static func label_text(def: Dictionary) -> String:
	return "%s  [T%d]\n%s" % [def["name"], def["tier"], def["role"]]


static func label_for(def: Dictionary, at: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = label_text(def)
	l.pixel_size = 0.0035
	l.font_size = 20
	l.width = 480.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.rotation_degrees.y = 180.0  # the player looks toward +Z
	l.position = at
	return l


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
