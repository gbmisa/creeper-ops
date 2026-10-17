class_name StagingMannequin
extends Node3D
## F140: one mannequin on the north wall showing gear preset `index`. Save / equip / rename act on that preset
## (GearPresets). Equip replaces the kit with the preset's items as saved (the room's stash is unlimited, like the range).

const REACH := 2.2

var index := 0
var preset_name := ""
var kit := {}
var figure: StagingFigure
var _lbl: Label3D


func setup(i: int, at: Vector3) -> void:
	index = i
	name = "Mannequin%d" % (i + 1)
	position = at
	RangeLayout.box(self, "plinth", Vector3(0, 0.06, 0), Vector3(1.0, 0.12, 1.0), "concrete", 0.1, Color(0.25, 0.25, 0.26))
	_lbl = Label3D.new()
	_lbl.font_size = 40
	_lbl.pixel_size = 0.0045
	_lbl.outline_size = 8
	_lbl.modulate = Color(0.85, 1.0, 0.8)
	_lbl.position = Vector3(0, 2.2, -0.1)
	add_child(_lbl)
	reload()


func has_preset() -> bool:
	return not kit.is_empty()


## Re-read the preset from GearPresets and rebuild the body.
func reload() -> void:
	var p := GearPresets.load_slot(index)
	preset_name = p["name"]
	kit = p["kit"]
	if figure != null:
		figure.queue_free()
	figure = StagingFigure.new()
	figure.position = Vector3(0, 0.12, 0)
	figure.rotation.y = PI   # faces +Z, toward the room
	add_child(figure)
	figure.setup(kit)
	_lbl.text = "%s\n%s" % [preset_name.to_upper(), "" if has_preset() else "(empty)"]


func save_from(inv: Inventory) -> void:
	GearPresets.save_slot(index, preset_name, inv.to_dict())
	reload()


func rename(new_name: String) -> void:
	preset_name = new_name.strip_edges() if new_name.strip_edges() != "" else GearPresets.default_name(index)
	GearPresets.rename_slot(index, preset_name)
	reload()


## Replaces the kit with this preset. False when nothing is saved here.
func equip(w: PlayerWeapons) -> bool:
	if not has_preset():
		return false
	w.reload_cancel()
	w.inv.load_dict(kit)
	w.gun_item = {}
	w.gun = null
	w.sync()
	if w.gun == null:
		w.switched.emit(null)
	return true
