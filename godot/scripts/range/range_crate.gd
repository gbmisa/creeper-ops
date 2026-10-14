class_name RangeCrate
## Supply crate beside the weapon rack: a crate prop and its spare mags, loose ammo, bags and armor lying in front.

const POS := Vector3(-1.6, 0, 9.9)
const LOOT := [["mag_ak47", {}], ["mag_ak47", {}], ["mag_ak47", {}], ["mag_p90", {}], ["mag_p90", {}], ["mag_sniper", {}],
	["mag_m1911", {}], ["mag_m1911", {}], ["clip_garand", {}], ["clip_garand", {}],
	["762_ps", {"count": 60}], ["762_bp", {"count": 30}], ["12_buck7", {"count": 24}], ["45_fmj", {"count": 35}], ["3006_fmj", {"count": 24}],
	["pack_small", {}], ["pack_big", {}], ["rig_chest", {}], ["vest2", {}], ["plate4", {}], ["helmet3", {}], ["med_ifak", {}], ["med_bandage", {}]]
const COLUMNS := 8


static func build(parent: Node3D, world_items: WorldItems) -> void:
	RangeLayout.box(parent, "supply_crate", POS + Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 0.6), "plywood", 0.05, Color(0.4, 0.3, 0.18))
	var l := Label3D.new()
	l.text = "SUPPLY CRATE"
	l.pixel_size = 0.0035
	l.font_size = 48
	l.rotation_degrees.y = 180.0
	parent.add_child(l)
	l.position = POS + Vector3(0, 0.9, -0.35)
	var i := 0
	for row in LOOT:
		var it := ItemDefs.make(row[0], row[1])
		var x := -3.0 + (i % COLUMNS) * 0.55
		var z := 8.6 - (i / COLUMNS) * 0.5
		world_items.drop(it, Vector3(x, 0.15, z))
		i += 1
