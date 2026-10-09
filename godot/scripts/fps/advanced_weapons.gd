class_name AdvancedWeapons
extends RefCounted
## Operative slots 4/5/6. Usable only after OperativeUpgrades unlocks them. Each shot or
## second of fire spends Salvage from the shared Stockpile. Numbers live in WEAPONS.

const WEAPONS := {
	"railgun": { "name": "Railgun", "key": "adv_railgun", "salvage": 2.0, "charge": 1.5, "damage": 30.0 },
	"plasma": { "name": "Plasma Thrower", "key": "adv_plasma", "salvage": 1.0, "dps": 6.0, "rate_mult": 3.0 },
	"demo": { "name": "Demolition Charge", "key": "adv_demo", "salvage": 8.0, "range": 20.0,
		"speed": 18.5, "loft": 0.61, "fuse": 2.0, "damage": 120.0, "radius": 2.0 },
}
const IDS := ["railgun", "plasma", "demo"]

var weapons: OperativeWeapons
var stockpile: Stockpile
var charge := 0.0
var need := ""
var _need_for := ""  # weapon held when the unlock hint appeared; switching clears it
var firing := false
var showcase := false  # debug: hold the trigger for a firing screenshot
var demo: DemoCharge
var _moaned := false


func _init(host: OperativeWeapons) -> void:
	weapons = host
	demo = DemoCharge.new(WEAPONS.demo)


func handles(id: String) -> bool:
	return WEAPONS.has(id)


func label() -> String:
	var d: Dictionary = WEAPONS[weapons.current]
	# Railgun charge progress shows on the HUD fill bar (charge_ratio), never as a %.
	return "[%s] %s" % [Keybinds.short(d.key), d.name]


func salvage_line() -> String:
	if stockpile == null or not handles(weapons.current):
		return ""
	return "Salvage %s" % String.num(stockpile.salvage, 1)


## 0..1 while the railgun is out, else -1 (HUD hides the bar).
func charge_ratio() -> float:
	if weapons.current != "railgun":
		return -1.0
	return clampf(charge / float(WEAPONS.railgun.charge), 0.0, 1.0)


func hud_need() -> String:
	if need != "":
		return need
	if not handles(weapons.current) or stockpile == null:
		return ""
	var cost := float(WEAPONS[weapons.current].salvage)
	var free: bool = weapons.current == "demo" and Config.DEMO_CHARGE_FREE
	var short := not free and stockpile.salvage <= 0.0001 if weapons.current == "plasma" else not stockpile.can_afford("salvage", cost)
	return "Need %d Salvage" % int(cost) if short else ""


func update(dt: float, input: InputState, world: World, feet: Vector3) -> void:
	var before := need
	_pick(input)
	if need != before and need.begins_with("Unlock"):
		_need_for = weapons.current
	elif need.begins_with("Unlock") and weapons.current != _need_for:
		need = ""
	demo.update(dt)
	if not handles(weapons.current) or not OperativeUpgrades.unlocked(weapons.current):
		charge = 0.0
		firing = false
		return
	var trigger := showcase or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not trigger:
		_moaned = false
		if weapons.current == "railgun":
			charge = 0.0
	need = ""
	firing = false
	match weapons.current:
		"railgun":
			_rail(dt, trigger, world)
		"plasma":
			_plasma(dt, trigger, world, feet)
		"demo":
			if trigger and not _moaned:
				_throw(world)
				_moaned = true  # one charge per click


func _pick(input: InputState) -> void:
	for id in IDS:
		var d: Dictionary = WEAPONS[id]
		if not input.act(d.key):
			continue
		if OperativeUpgrades.unlocked(id):
			weapons.current = id
			need = ""
			charge = 0.0
			_moaned = false
		else:
			need = "Unlock the %s (%d Salvage) at the Armoury: stand at the Command Node and press %s, or select the Node in command mode" % [d.name, OperativeUpgrades.cost("unlock_" + id), Keybinds.short("use")]
			Sfx.play("deny")


func _deny(id: String) -> void:
	need = "Need %d Salvage" % int(WEAPONS[id].salvage)
	if not _moaned:
		_moaned = true
		Sfx.play("deny")


func _pay(id: String) -> bool:
	var cost := float(WEAPONS[id].salvage)
	if id == "demo" and Config.DEMO_CHARGE_FREE:
		return true
	if stockpile != null and stockpile.spend("salvage", cost):
		return true
	_deny(id)
	return false


func _rail(dt: float, trigger: bool, world: World) -> void:
	if not trigger:
		return
	var need_t := float(WEAPONS.railgun.charge)
	if charge <= 0.0 and (stockpile == null or not stockpile.can_afford("salvage", WEAPONS.railgun.salvage)):
		_deny("railgun")
		return
	charge = minf(need_t, charge + dt)
	if charge < need_t:
		return
	charge = 0.0
	if not _pay("railgun"):
		return
	_pierce(world, float(WEAPONS.railgun.damage))
	weapons.kick("railgun")
	weapons.muzzle.flash(Color("e8fbff"), 0.4, 0.1, 4.0)
	Sfx.play("railshot")


## Every target sphere on the ray, out to the rifle's range or the first ground hit.
func _pierce(world: World, dmg: float) -> void:
	var cam := weapons.camera
	var origin: Vector3 = cam.global_position
	var dir := -cam.global_transform.basis.z
	var reach: float = Config.RIFLE.range
	var ground = world.grid.raycast(origin, dir, reach)
	var gd: float = origin.distance_to(ground) if ground != null else INF
	var hits: Array[Dictionary] = []
	for t in world.targets:
		if not t.alive.call():
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		var dist := RifleFire.ray_sphere(origin, dir, c, t.radius)
		if dist < reach and dist < gd:
			hits.append({ "t": t, "dist": dist })
	hits.sort_custom(func(a, b): return float(a.dist) < float(b.dist))
	var end := origin + dir * (gd if ground != null else reach)
	var any := false
	for h in hits:
		var at: Vector3 = origin + dir * float(h.dist)
		(h.t as Dictionary).on_hit.call(dmg, at)
		end = at
		any = true
	if any:
		weapons.confirm(hits.any(func(h): return not (h.t as Dictionary).alive.call()))
	world.effects.beam(weapons.gun.global_position, end, Color("e8fbff"), 0.08, 0.045)
	if not any:
		Sfx.play("beam")


func _plasma(dt: float, trigger: bool, world: World, feet: Vector3) -> void:
	if not trigger:
		return
	var bill := float(WEAPONS.plasma.salvage) * dt
	if stockpile == null or not stockpile.can_afford("salvage", bill):
		_deny("plasma")
		return
	stockpile.spend("salvage", bill)
	firing = true
	_plasma_cone(dt, world, feet)
	weapons.kick("plasma")  # buzzes the gun while it burns
	if not weapons.muzzle.active():
		weapons.muzzle.flash(Color("c45bff"), 0.32, 0.08, 2.5)
	Sfx.play("spray")


## Creeper leaves at 3x the rocket's centre power per second. Targets in the cone take dps.
func _plasma_cone(dt: float, world: World, feet: Vector3) -> void:
	var g := world.grid
	var fwd := -weapons.camera.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.0001:
		return
	fwd = fwd.normalized()
	var here := g.world_to_cell(feet.x, feet.z)
	var range_m: float = Config.SPRAYER.range
	var range_cells := range_m / Config.CELL
	var cos_a := cos(Config.SPRAYER.half_angle)
	var rate := Config.ROCKET.power * float(WEAPONS.plasma.rate_mult)
	for c in g.cells_in_radius(here.x, here.y, range_cells):
		if not _in_cone(feet, fwd, g.cell_center(c.x, c.y), range_m, cos_a):
			continue
		var dist := Vector2(c.x - here.x, c.y - here.y).length()
		world.creeper.remove(c.x, c.y, rate * dt * (1.0 - 0.5 * dist / range_cells))
	var tick := float(WEAPONS.plasma.dps) * dt
	for t in world.targets:
		if t.alive.call() and _in_cone(feet, fwd, (t.node as Node3D).global_position, range_m, cos_a):
			t.on_hit.call(tick, (t.node as Node3D).global_position)


func _in_cone(feet: Vector3, fwd: Vector3, p: Vector3, range_m: float, cos_a: float) -> bool:
	var dx := p.x - feet.x
	var dz := p.z - feet.z
	var len := Vector2(dx, dz).length()
	if len > range_m:
		return false
	return len < Config.CELL * 0.9 or (dx * fwd.x + dz * fwd.z) / len >= cos_a


func _throw(world: World) -> void:
	if _pay("demo"):
		var dir := -weapons.camera.global_transform.basis.z
		demo.launch(world, weapons.gun.global_position, dir)
		weapons.kick("demo")
		weapons.muzzle.flash(Color("ff8844"), 0.3, 0.08, 2.0)
