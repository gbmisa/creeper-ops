class_name WorldItem
extends RigidBody3D
## An inventory item lying in the range: the gun model, or a coloured box sized from the grid footprint.
## `item` is the Inventory dict (it keeps its Gun, rounds, bag contents). Collides with the world only.

const CELL_M := 0.05
const KIND_COLOUR := {"mag": Color(0.2, 0.2, 0.22), "ammo": Color(0.7, 0.55, 0.15), "armor": Color(0.25, 0.3, 0.22),
	"rig": Color(0.35, 0.3, 0.2), "backpack": Color(0.3, 0.35, 0.25), "med": Color(0.7, 0.15, 0.15), "attach": Color(0.15, 0.35, 0.45)}

var item: Dictionary


func setup(it: Dictionary) -> WorldItem:
	item = it
	it["world"] = self
	var d := ItemDefs.def_of(it)
	name = "Item_" + str(it["uid"])
	collision_layer = TacticalConfig.LAYER_ITEM
	collision_mask = TacticalConfig.LAYER_WORLD
	mass = maxf(0.2, d["kg"])
	var size := Vector3(d["w"] * CELL_M, 0.04 + 0.01 * d["h"], d["h"] * CELL_M)
	if d["kind"] == "gun":
		var glb := (load("res://assets/models/guns/%s.glb" % WeaponDefs.of(it["id"])["model"]) as PackedScene).instantiate() as Node3D
		var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var bb := mi.get_aabb()
		size = Vector3(maxf(bb.size.x, 0.05), maxf(bb.size.y, 0.05), maxf(bb.size.z, 0.1))
		var holder := Node3D.new()  # lies on its side, long axis along X
		holder.rotation_degrees.y = 90.0
		if WeaponDefs.of(it["id"]).get("flip", false):
			glb.rotation.y = PI
		glb.position = -bb.get_center()
		holder.add_child(glb)
		add_child(holder)
		size = Vector3(size.z, size.y, size.x)
	else:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		m.mesh = bm
		m.material_override = RangeLayout.colour(KIND_COLOUR[d["kind"]])
		m.position.y = size.y * 0.5
		add_child(m)
		var l := Label3D.new()  # F7: labelled placeholder box (FB-E models replace these later)
		l.text = ItemDefs.label(item)
		l.font_size = 32
		l.pixel_size = 0.0025
		l.outline_size = 6
		l.modulate = Color(0.9, 0.95, 0.9)
		l.position = Vector3(0, size.y + 0.09, 0)
		add_child(l)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position.y = 0.0 if d["kind"] == "gun" else size.y * 0.5
	add_child(cs)
	return self


func label() -> String:
	return ItemDefs.label(item)
