class_name BodyHealth
extends RefCounted
## Zone health, armor, blackout spill, bleeds, death. No scene dependencies. No fractures (Gregory 2026-10-16).

const ZONES := ["head", "thorax", "stomach", "larm", "rarm", "lleg", "rleg"]
const MAX := {"head": 35.0, "thorax": 85.0, "stomach": 70.0, "larm": 60.0, "rarm": 60.0, "lleg": 65.0, "rleg": 65.0}
## Spill multiplier by the blacked-out zone that took the damage.
const SPILL := {"larm": 0.7, "rarm": 0.7, "lleg": 1.0, "rleg": 1.0, "stomach": 1.5}
const LIMBS := ["larm", "rarm", "lleg", "rleg"]

var hp := {}
var armor := {}  # zone -> {"id", "dur"}
var bleeds: Array = []  # {"zone", "rate"}
var dead := false
var rng := RandomNumberGenerator.new()


func _init() -> void:
	reset()


func reset() -> void:
	for z in ZONES:
		hp[z] = MAX[z]
	bleeds.clear()
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


## Walk speed multiplier from injuries. 1.0: nothing slows you since fractures were removed (CHANGES P10 is the
## open question of whether leg damage should).
func move_mult() -> float:
	return 1.0


## P9: how many arms are blacked out (0 HP), 0..2.
func arms_down() -> int:
	return int(hp["larm"] <= 0.0) + int(hp["rarm"] <= 0.0)


## P9: the arm-loss multiplier for "sway", "reload", "ads" or "recoil" (1.0 with both arms working).
func arm_loss(stat: String) -> float:
	var n := arms_down()
	return 1.0 if n == 0 else float(TacticalConfig.ARM_LOSS[n][stat])


func can_hold_breath() -> bool:
	var n := arms_down()
	return n == 0 or bool(TacticalConfig.ARM_LOSS[n]["breath"])


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


## Direct damage. info: bleed ("light"/"heavy"). Returns what happened.
func hit(zone: String, dmg: float, info: Dictionary = {}) -> Dictionary:
	var res := {"zone": zone, "dmg": dmg, "blacked": false, "spill": {}, "killed": false}
	if dead:
		return res
	var was: float = hp[zone]
	_damage(zone, dmg, res["spill"])
	res["blacked"] = was > 0.0 and hp[zone] <= 0.0
	var bleed: String = info.get("bleed", "")
	if bleed != "" and hp[zone] > 0.0:
		var rate: float = TacticalConfig.HEAVY_BLEED_DPS if bleed == "heavy" else TacticalConfig.LIGHT_BLEED_DPS
		bleeds.append({"zone": zone, "rate": rate})
	res["killed"] = _check_death()
	return res


## Field medical: stops bleeds and restores `frac` of each living zone's max HP (blacked-out zones stay down),
## spending at most `budget` HP in all. Returns the HP restored.
func heal(frac: float, budget := INF) -> float:
	if dead:
		return 0.0
	bleeds.clear()
	var used := 0.0
	for z in ZONES:
		if hp[z] > 0.0:
			var add := minf(minf(MAX[z] - hp[z], MAX[z] * frac), budget - used)
			hp[z] += add
			used += add
	return used


## Every living zone at max HP (blacked-out zones can't be healed, so they don't count).
func full_health() -> bool:
	for z in ZONES:
		if hp[z] > 0.0 and hp[z] < MAX[z]:
			return false
	return true


## Bandage: stops every bleed, heals nothing.
func stop_bleeds() -> void:
	bleeds.clear()


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


## Plain-data snapshot (MULTIPLAYER.md rule 6). Rng state is not serialized.
func to_dict() -> Dictionary:
	return {
		"hp": hp.duplicate(),
		"armor": armor.duplicate(true),
		"bleeds": bleeds.duplicate(true),
		"dead": dead,
	}


static func from_dict(d: Dictionary) -> BodyHealth:
	var b := BodyHealth.new()
	b.hp = (d.get("hp", {}) as Dictionary).duplicate()
	for z in ZONES:
		if not b.hp.has(z):
			b.hp[z] = MAX[z]
	b.armor = (d.get("armor", {}) as Dictionary).duplicate(true)
	b.bleeds = (d.get("bleeds", []) as Array).duplicate(true)
	b.dead = bool(d.get("dead", false))
	return b
