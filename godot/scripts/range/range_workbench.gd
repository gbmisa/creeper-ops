class_name RangeWorkbench
extends Node3D
## F11: weapon customization station. Placeholder bench mesh + label; F opens the
## inventory UI, where all attachment fitting happens (drag a part onto a gun).
## Uses the existing attachment data; the viewmodel's AttachmentRig shows the result.

const POS := Vector3(3.2, 0.0, 9.55)
const REACH := 2.2

var weapons: PlayerWeapons
var player: TacticalPlayer
var inv_ui: InventoryUI


func setup(w: PlayerWeapons, p: TacticalPlayer, u: InventoryUI) -> void:
	weapons = w
	player = p
	inv_ui = u
	RangeLayout.box(self, "workbench_top", POS + Vector3(0, 0.85, 0), Vector3(1.6, 0.1, 0.7), "wood_plank", 0.1, Color(0.45, 0.33, 0.2))
	for sx in [-0.7, 0.7]:
		RangeLayout.box(self, "workbench_leg", POS + Vector3(sx, 0.4, 0), Vector3(0.12, 0.8, 0.6), "wood_plank", 0.12, Color(0.4, 0.3, 0.18))
	var l := Label3D.new()
	l.text = "WORKBENCH"
	l.font_size = 56
	l.pixel_size = 0.004
	l.outline_size = 10
	l.rotation_degrees.y = 180.0
	l.position = POS + Vector3(0, 1.5, 0)
	l.modulate = Color(0.85, 1.0, 0.8)
	add_child(l)


func _process(_dt: float) -> void:
	if player == null or not player.enabled or inv_ui == null:
		return
	var to := POS - player.global_position
	to.y = 0.0
	if to.length() > REACH:
		return
	weapons.prompt = "%s: customize weapons" % Keybinds.short("t_use")
	if player.input.act("t_use") and not inv_ui.is_open:
		inv_ui.open()
