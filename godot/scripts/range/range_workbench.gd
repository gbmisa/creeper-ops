class_name RangeWorkbench
extends Node3D
## F11/F141: weapon customization station. Bench props + sign; F opens the gunsmith screen (GunsmithUI), where parts
## are fitted (same inventory rules as the drag in the inventory UI).
## Uses the existing attachment data; the viewmodel's AttachmentRig shows the result. F115: also shows RangeInfoPanel.

const POS := Vector3(3.2, 0.0, 9.55)
const REACH := 2.2

var weapons: PlayerWeapons
var player: TacticalPlayer
var inv_ui: InventoryUI
var smith := GunsmithUI.new()  # F141: the gunsmith screen
var info := RangeInfoPanel.new()  # F115: gun + wall reference, shown from the gunsmith "Gun info" button


func setup(w: PlayerWeapons, p: TacticalPlayer, u: InventoryUI) -> void:
	weapons = w
	player = p
	inv_ui = u
	RangeStationProps.workbench(self, POS)
	smith.setup(w, p, u)
	smith.info_toggle = func(): info.visible = not info.visible  # F115 reference stays reachable from the gunsmith
	add_child(smith)
	add_child(info)


func _process(_dt: float) -> void:
	if info.visible and not smith.is_open:
		info.visible = false
	if player == null or not player.enabled or inv_ui == null:
		return
	var to := POS - player.global_position
	to.y = 0.0
	if to.length() > REACH:
		return
	weapons.prompt = "%s: gunsmith (fit attachments)" % Keybinds.short("t_use")
	if player.input.act("t_use") and not inv_ui.is_open and not smith.is_open:
		smith.open()
