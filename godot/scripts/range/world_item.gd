class_name WorldItem
extends RigidBody3D
## Physics pickup for inventory items dropped in the range. F picks it up via first_fit.
## data = {"items": [item dicts]}; guns drop together with their inserted mag.

const REACH := 2.0


static func make_node(data: Dictionary) -> WorldItem:
	var w := WorldItem.new()
	w.data = data
	return w


var data := {"items": []}
var _label: Label3D


func _ready() -> void:
	var items: Array = data.get("items", [])
	var first: Dictionary = items[0] if not items.is_empty() else {}
	var idef := ItemDefs.of(first.get("id", "med_bandage"))
	contact_monitor = false
	var mi: MeshInstance3D
	if idef["kind"] == "gun":
		var glb := load("res://assets/models/guns/%s.glb" % WeaponDefs.of(idef["weapon"])["model"]) as PackedScene
		mi = MeshInstance3D.new()
		if glb != null:
			var n := glb.instantiate() as Node3D
			n.rotation.y = PI / 2.0
			mi.add_child(n)
		else:
			mi.mesh = BoxMesh.new()
	else:
		mi = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16 * idef["w"], 0.12, 0.16 * idef["h"])
		bm.material = _mat(Color(0.45, 0.36, 0.22))
		mi.mesh = bm
	add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 0.25, 0.9) if idef["kind"] == "gun" else Vector3(0.3, 0.25, 0.3)
	cs.shape = shape
	add_child(cs)
	mass = 1.0
	var l := Label3D.new()
	l.text = title_text()
	l.pixel_size = 0.004
	l.font_size = 42
	l.position = Vector3(0, 0.45, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	_label = l


func title_text() -> String:
	var names: Array = []
	for it in data.get("items", []):
		names.append(ItemDefs.of((it as Dictionary)["id"])["name"])
	return "\n".join(names)


func refresh_label() -> void:
	if _label != null:
		_label.text = title_text()


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m


## Remove a gun and its inserted mag from the inventory into drop data. gun may be null
## (then the mag item's stored rounds are used as-is).
static func pack_gun(inv: Inventory, gun_uid: int, gun: Gun) -> Dictionary:
	var out: Array = []
	var mid := inv.mag_in_gun(gun_uid)
	if mid != -1:
		var mi: Dictionary = inv.items[mid]
		if gun != null:
			mi["rounds"] = gun.mag.count() + (1 if gun.chamber != "" else 0)
			if gun.mag.count() > 0:
				mi["ammo"] = gun.mag.top()
			elif gun.chamber != "":
				mi["ammo"] = gun.chamber
		inv.remove(mid)
		out.append(mi)
	if inv.items.has(gun_uid):
		out.append(inv.remove(gun_uid))
	return {"items": out}


## Put dropped items back into the inventory. Returns uids that found room.
## A mag whose gun did not fit becomes a loose mag.
static func unpack(inv: Inventory, data: Dictionary) -> Array:
	var placed: Array = []
	var sorted: Array = (data.get("items", []) as Array).duplicate()
	sorted.sort_custom(func(a, b): return (ItemDefs.of((a as Dictionary)["id"])["kind"] == "gun") and not (ItemDefs.of((b as Dictionary)["id"])["kind"] == "gun"))
	var gun_placed := {}
	for it in sorted:
		var item: Dictionary = it
		inv.items[item["uid"]] = item
		if ItemDefs.of(item["id"])["kind"] == "gun":
			if inv.first_fit(item):
				placed.append(item["uid"])
				gun_placed[item["uid"]] = true
			else:
				inv.items.erase(item["uid"])
		elif bool(item.get("in_gun", false)) and gun_placed.has(item["gun_uid"]):
			inv.loc[item["uid"]] = {"c": Inventory.GUN_HOME, "x": -1, "y": -1}
			placed.append(item["uid"])
		else:
			item["in_gun"] = false
			if inv.first_fit(item):
				placed.append(item["uid"])
			else:
				inv.items.erase(item["uid"])
	return placed
