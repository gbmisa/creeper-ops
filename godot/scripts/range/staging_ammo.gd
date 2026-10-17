class_name StagingAmmo
extends Node3D
## F139: the ammo bench of the loadout room. Same refill as the Firing Range's bench (RangeBench), no dummy armor rack.

var weapons: PlayerWeapons
var player: TacticalPlayer


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	RangeStationProps.ammo_bench(self, RangeBench.AMMO_POS)


func _process(_dt: float) -> void:
	if player == null or weapons.gun == null:
		return
	var to := RangeBench.AMMO_POS - player.eye_pos()
	to.y = 0.0
	if to.length() < RangeBench.REACH and to.normalized().dot(-player.cam.global_basis.z.slide(Vector3.UP).normalized()) > 0.3:
		var tube: bool = weapons.gun.def["action"] == "tube"
		weapons.prompt = "%s: refill %s" % [Keybinds.short("t_use"), "shells" if tube else "mags"]
		if player.enabled and player.input.act("t_use"):
			weapons.reload_cancel()
			weapons.gun.refill()
			weapons.refill_mags()
			weapons.message.emit("%s refilled" % ("Tube shells" if tube else "Mags"))
