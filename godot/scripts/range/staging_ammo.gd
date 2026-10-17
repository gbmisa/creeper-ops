class_name StagingAmmo
extends Node3D
## F139: the ammo bench of the loadout room. Use opens the inventory with the SUPPLY panel (its top button is the old refill), no dummy armor rack.

var weapons: PlayerWeapons
var player: TacticalPlayer
var inv_ui: InventoryUI


func setup(w: PlayerWeapons, p: TacticalPlayer, ui: InventoryUI) -> void:
	weapons = w
	player = p
	inv_ui = ui
	RangeStationProps.ammo_bench(self, RangeBench.AMMO_POS)


func _process(_dt: float) -> void:
	if player == null or weapons.ui_open:
		return
	var to := RangeBench.AMMO_POS - player.eye_pos()
	to.y = 0.0
	if to.length() < RangeBench.REACH and to.normalized().dot(-player.cam.global_basis.z.slide(Vector3.UP).normalized()) > 0.3:
		weapons.prompt = "%s: supply and refill" % Keybinds.short("t_use")
		if player.enabled and player.input.act("t_use"):
			inv_ui.open_supply()
