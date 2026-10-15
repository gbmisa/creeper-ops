class_name RangeCrate
extends StaticBody3D
## Supply crate next to the weapon rack. F takes the next stocked item via first_fit.
## Stock: spare mags, loose ammo, rigs, backpacks, armor, meds.

const REACH := 3.0


static func default_stock() -> Array:
	var s: Array = []
	for i in 4:
		s.append("mag_762x39")
	for i in 2:
		s.append("mag_45acp")
	for i in 2:
		s.append("ammo_762x39")
	for i in 2:
		s.append("ammo_45acp")
	for i in 2:
		s.append("ammo_12ga")
	s.append_array(["rig_std", "pack_small", "pack_big", "armor_vest"])
	for i in 2:
		s.append("med_bandage")
	s.append("med_ifak")
	return s


var stock: Array = []


func _init() -> void:
	stock = default_stock()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 0.8, 0.8)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.36, 0.24)
	m.roughness = 0.9
	bm.material = m
	mi.mesh = bm
	mi.position.y = 0.4
	add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 0.8, 0.8)
	cs.shape = shape
	cs.position.y = 0.4
	add_child(cs)
	var l := Label3D.new()
	l.text = "SUPPLY"
	l.pixel_size = 0.005
	l.font_size = 48
	l.position = Vector3(0, 1.15, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)


## Next item id if the player is close enough, else "".
func pick(eye: Vector3) -> String:
	if stock.is_empty() or eye.distance_to(global_position) > REACH:
		return ""
	return stock[0]


func take_next() -> String:
	if stock.is_empty():
		return ""
	return stock.pop_front()
