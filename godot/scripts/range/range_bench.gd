class_name RangeBench
extends Node3D
## Two booth stations. Ammo bench (on the bench): use refills the held gun's mags (F116: no ammo types).
## Armor station: use cycles the dummy armor loadout and resets every target. Prompts go through weapons.prompt.

const AMMO_POS := Vector3(5.0, 0.0, 9.5)  # F9: against the back wall with the bench prop
const ARMOR_POS := Vector3(1.5, 0.0, 9.4)
const REACH := 2.2

var weapons: PlayerWeapons
var player: TacticalPlayer
var targets: RangeTargets
var log: RangeHitLog
var _armor_lbl: Label3D


func setup(w: PlayerWeapons, p: TacticalPlayer, t: RangeTargets, l: RangeHitLog) -> void:
	weapons = w
	player = p
	targets = t
	log = l
	RangeStationProps.ammo_bench(self, AMMO_POS)
	RangeStationProps.armor_rack(self, ARMOR_POS)
	_armor_lbl = RangeStationProps.sign_board(self, ARMOR_POS + Vector3(0, 2.3, 0.25), "", 1.7)
	_refresh_armor()


func _refresh_armor() -> void:
	_armor_lbl.text = "ARMOR STATION\n%s" % ArmorDefs.LOADOUT_NAMES[targets.loadout]


func _near(p: Vector3) -> bool:
	var to := p - player.eye_pos()
	to.y = 0.0
	return to.length() < REACH and to.normalized().dot(-player.cam.global_basis.z.slide(Vector3.UP).normalized()) > 0.3


func _process(_dt: float) -> void:
	if player == null:
		return
	if _near(AMMO_POS) and weapons.gun != null:
		var tube: bool = weapons.gun.def["action"] == "tube"  # F22: UI says tube/shells, never magazine
		weapons.prompt = "%s: refill %s" % [Keybinds.short("t_use"), "shells" if tube else "mags"]
		if player.enabled and player.input.act("t_use"):  # F116: refill only, no ammo types to cycle
			weapons.reload_cancel()
			weapons.gun.refill()
			weapons.refill_mags()
			weapons.message.emit("%s refilled" % ("Tube shells" if tube else "Mags"))
	elif _near(ARMOR_POS):
		var n: int = (targets.loadout + 1) % ArmorDefs.LOADOUTS.size()
		weapons.prompt = "%s: dummy armor -> %s (resets targets)" % [Keybinds.short("t_use"), ArmorDefs.LOADOUT_NAMES[n]]
		if player.enabled and player.input.act("t_use"):
			cycle_armor(targets, n)
			log.clear()
			_refresh_armor()


static func cycle_ammo(g: Gun) -> void:
	g.ammo_pick = TacAmmoDefs.next_grade(g.ammo_pick)
	g.refill()


static func cycle_armor(t: RangeTargets, idx: int) -> void:
	t.set_loadout(idx)
	t.reset_all()
