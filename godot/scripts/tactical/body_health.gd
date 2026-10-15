class_name BodyHealth
extends RefCounted
## Zone health, armor, blackout spill, bleeds, fractures, death. No scene dependencies.

const ZONES := ["head", "thorax", "stomach", "larm", "rarm", "lleg", "rleg"]
const MAX := {"head": 35.0, "thorax": 85.0, "stomach": 70.0, "larm": 60.0, "rarm": 60.0, "lleg": 65.0, "rleg": 65.0}
## Spill multiplier by the blacked-out zone that took the damage.
const SPILL := {"larm": 0.7, "rarm": 0.7, "lleg": 1.0, "rleg": 1.0, "stomach": 1.5}
const LIMBS := ["larm", "rarm", "lleg", "rleg"]

var hp := {}
var max_mult := {}  # zone -> max HP multiplier (surgery restores a blacked limb lower)
var armor := {}  # zone -> {"id", "dur"}
var bleeds: Array = []  # {"zone", "rate"}
var fractured := {}
var dead := false
var rng := RandomNumberGenerator.new()


func _init() -> void:
	reset()


func reset() -> void:
	for z in ZONES:
		hp[z] = MAX[z]
		max_mult[z] = 1.0
	bleeds.clear()
	fractured.clear()
	dead = false


func alive() -> bool:
	return not dead


func equip(armor_id: String) -> void:
	var a := ArmorDefs.of(armor_id)
	for z in a["zones"]:
		armor[z] = {"id": armor_id, "dur": a["max_dur"]}


func clear_armor() -> void:
	armor.clear()


func total_frac() -> float:
	var cur := 0.0
	var mx := 0.0
	for z in ZONES:
		cur += hp[z]
		mx += MAX[z]
	return cur / mx


func move_mult() -> float:
	return TacticalConfig.LEG_FRACTURE_SPEED if (fractured.has("lleg") or fractured.has("rleg")) else 1.0


func sway_add() -> float:
	return TacticalConfig.ARM_FRACTURE_SWAY if (fractured.has("larm") or fractured.has("rarm")) else 0.0


## A bullet reaching `zone`: armor first, then frag / bleeds, then hit(). shot: dmg, pen,
## armor_dmg, frag (ammo dict), lbleed, hbleed, glance. Returns hit()'s result plus result text.
func shoot(zone: String, shot: Dictionary) -> Dictionary:
	var dmg: float = shot["dmg"]
	var verdict := "PEN"
	var penetrated := true
	var armor_left := -1.0
	if armor.has(zone):
		var slot: Dictionary = armor[zone]
		var def := ArmorDefs.of(slot["id"])
		var r := Penetration.armor_hit(def, slot["dur"], shot, rng.randf(), rng.randf())
		slot["dur"] = maxf(0.0, slot["dur"] - r["dur_loss"])
		armor_left = slot["dur"]
		dmg = r["dmg"]
		if r["ricochet"]:
			verdict = "RICOCHET"
			penetrated = false
		elif not r["pen"]:
			verdict = "BLOCKED"
			penetrated = false
	var info := {}
	if penetrated:
		dmg *= Penetration.frag_mult(shot.get("ammo", {"frag": 0.0}), shot["pen"], rng.randf())
		if rng.randf() < shot.get("hbleed", 0.05):
			info["bleed"] = "heavy"
		elif rng.randf() < shot.get("lbleed", 0.15):
			info["bleed"] = "light"
	var res := hit(zone, dmg, info)
	res["result"] = verdict
	res["armor_dur"] = armor_left
	return res


## Direct damage. info: bleed ("light"/"heavy"), fracture (bool to force). Returns what happened.
func hit(zone: String, dmg: float, info: Dictionary = {}) -> Dictionary:
	var res := {"zone": zone, "dmg": dmg, "blacked": false, "spill": {}, "killed": false, "fracture": false}
	if dead:
		return res
	var was: float = hp[zone]
	_damage(zone, dmg, res["spill"])
	res["blacked"] = was > 0.0 and hp[zone] <= 0.0
	var bleed: String = info.get("bleed", "")
	if bleed != "" and hp[zone] > 0.0:
		var rate: float = TacticalConfig.HEAVY_BLEED_DPS if bleed == "heavy" else TacticalConfig.LIGHT_BLEED_DPS
		bleeds.append({"zone": zone, "rate": rate})
	if zone in LIMBS and not fractured.has(zone):
		var frac: bool = info.get("fracture", dmg > TacticalConfig.FRACTURE_MIN_DMG and rng.randf() < TacticalConfig.FRACTURE_CHANCE)
		if frac:
			fractured[zone] = true
			res["fracture"] = true
	res["killed"] = _check_death()
	return res


## Field medical: stops bleeds and restores `frac` of each living zone's max HP (blacked-out zones stay down).
func heal(frac: float) -> void:
	if dead:
		return
	bleeds.clear()
	for z in ZONES:
		if hp[z] > 0.0:
			hp[z] = minf(zone_max(z), hp[z] + MAX[z] * frac)


func zone_max(zone: String) -> float:
	return MAX[zone] * float(max_mult.get(zone, 1.0))


## HP pool: heals the worst (most damaged, living) zone first until the pool is spent.
func heal_pool(amount: float) -> void:
	if dead:
		return
	var left: float = amount
	while left > 0.0:
		var worst := ""
		var worst_missing := 0.0
		for z in ZONES:
			if hp[z] > 0.0:
				var missing: float = zone_max(z) - hp[z]
				if missing > worst_missing:
					worst_missing = missing
					worst = z
		if worst == "":
			return
		var give: float = minf(left, worst_missing)
		hp[worst] += give
		left -= give


## Stop bleeds. kind: "" = all, "light", "heavy". zone "" = every zone. Returns stopped count.
func stop_bleed(zone: String = "", kind: String = "") -> int:
	var n := 0
	var kept: Array = []
	for b in bleeds:
		var heavy: bool = float(b["rate"]) >= TacticalConfig.HEAVY_BLEED_DPS
		var match_kind: bool = kind == "" or (kind == "heavy") == heavy
		if (zone == "" or b["zone"] == zone) and match_kind:
			n += 1
		else:
			kept.append(b)
	bleeds = kept
	return n


## Surgery (CMS kit): restore a blacked-out limb at 60 % max HP. Returns false if nothing to fix.
func surgery(zone: String) -> bool:
	if dead or not zone in LIMBS or hp[zone] > 0.0:
		return false
	max_mult[zone] = 0.6
	hp[zone] = MAX[zone] * 0.6
	fractured.erase(zone)
	stop_bleed(zone)
	return true


func tick(dt: float) -> void:
	if dead:
		return
	for b in bleeds:
		_damage(b["zone"], b["rate"] * dt, {})
	_check_death()


func _damage(zone: String, dmg: float, spill_out: Dictionary) -> void:
	var take := minf(dmg, hp[zone])
	hp[zone] -= take
	var excess := dmg - take
	if excess > 0.0 and SPILL.has(zone):
		for z in ZONES:
			if z != zone and hp[z] > 0.0:
				var amt: float = excess * SPILL[zone]
				var t := minf(amt, hp[z])
				hp[z] -= t
				spill_out[z] = spill_out.get(z, 0.0) + t


func _check_death() -> bool:
	if not dead and (hp["head"] <= 0.0 or hp["thorax"] <= 0.0):
		dead = true
		bleeds.clear()
		return true
	return false
