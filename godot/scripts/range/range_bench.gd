class_name RangeBench
extends Node3D
## Two booth stations. Ammo bench (on the bench): use cycles the held gun's ammo type and refills its mags.
## Armor station: use cycles the dummy armor loadout and resets every target. Prompts go through weapons.prompt.

const AMMO_POS := Vector3(5.0, 0.0, 8.0)
const ARMOR_POS := Vector3(1.5, 0.0, 9.4)
const REACH := 2.2

var weapons: PlayerWeapons
var player: TacticalPlayer
var targets: RangeTargets
var log: RangeHitLog
var _armor_lbl: Label3D
var _ammo_lbl: Label3D


func setup(w: PlayerWeapons, p: TacticalPlayer, t: RangeTargets, l: RangeHitLog) -> void:
	weapons = w
	player = p
	targets = t
	log = l
	_ammo_lbl = _station(AMMO_POS + Vector3(0, 1.0, 0.6), "AMMO BENCH", Color(0.5, 0.36, 0.2), Vector3(0, 0.01, 0))
	_armor_lbl = _station(ARMOR_POS + Vector3(0, 1.7, 0), "", Color(0.25, 0.3, 0.25), Vector3.ZERO)
	_refresh_armor()
	RangeLayout.box(self, "armor_stand", ARMOR_POS + Vector3(0, 0.9, 0.2), Vector3(0.9, 1.8, 0.15), "wood_plank", 0.15, Color(0.3, 0.32, 0.3))


func _station(pos: Vector3, text: String, _col: Color, _o: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 56
	l.pixel_size = 0.004
	l.outline_size = 10
	l.rotation_degrees.y = 0.0
	l.position = pos
	l.modulate = Color(0.85, 1.0, 0.8)
	add_child(l)
	return l


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
		var next := TacAmmoDefs.next_grade(weapons.gun.ammo_pick)
		weapons.prompt = "%s: load %s and refill mags" % [Keybinds.short("t_use"), TacAmmoDefs.of(next)["name"]]
		if player.enabled and player.input.act("t_use"):
			cycle_ammo(weapons.gun)
			weapons.message.emit("Loaded %s, mags refilled" % TacAmmoDefs.of(weapons.gun.ammo_pick)["name"])
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
