class_name StagingMannequins
extends Node3D
## F140: the three mannequins (GearPresets.COUNT) and the panel that opens beside one: Save current kit / Equip /
## Rename. Esc closes the panel (StagingScene).

const XS := [-5.0, -3.0, -1.0]

var weapons: PlayerWeapons
var player: TacticalPlayer
var inv_ui: InventoryUI
var figures: Array[StagingMannequin] = []
var panel := StagingPanel.new()


func setup(w: PlayerWeapons, p: TacticalPlayer, u: InventoryUI) -> void:
	weapons = w
	player = p
	inv_ui = u
	name = "Mannequins"
	for i in GearPresets.COUNT:
		var m := StagingMannequin.new()
		add_child(m)
		m.setup(i, Vector3(XS[i], 0.0, StagingRoom.Z_NORTH + 0.9))
		figures.append(m)
	panel.setup(w, p)
	add_child(panel)


func _process(_dt: float) -> void:
	if player == null or not player.enabled or inv_ui.is_open or panel.is_open:
		return
	for m in figures:
		var to := m.global_position - player.global_position
		to.y = 0.0
		if to.length() < StagingMannequin.REACH:
			weapons.prompt = "%s: %s (save / equip / rename)" % [Keybinds.short("t_use"), m.preset_name]
			if player.input.act("t_use"):
				panel.open(m)
			return
