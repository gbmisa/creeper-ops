class_name AmmoGrades
extends RefCounted
## Improved ammo rules (design 5.3): unlock milestone, the Operative's grade per weapon, network
## weapon and barracks grades, Salvage costs, and how a grade changes a hit. Static state like
## Upgrades: reset() at the start of each level.
## Level data: "ammo_unlock": "<objective id>" (unlocks when that objective completes).

static var unlocked := true
static var unlock_id := ""
static var op := { "rifle": "std", "rocket": "std" }
static var piercing := false  # set while an armour-piercing hit resolves (RaiderBurrow.filter reads it)
static var _hooked := false
static var _burns: Array[Dictionary] = []
static var _last_deny := -99999


static func reset(level: Dictionary) -> void:
	unlock_id = str(level.get("ammo_unlock", ""))
	unlocked = unlock_id == ""
	op = { "rifle": "std", "rocket": "std" }
	piercing = false
	_burns.clear()
	if not _hooked:
		_hooked = true
		Bus.objective_done.connect(func(id: String) -> void:
			if unlock_id != "" and id == unlock_id and not unlocked:
				unlocked = true
				Bus.say("Improved ammo unlocked: Armour-piercing, Incendiary and Cluster. %s switches grade." % _keys(), "good"))


static func _keys() -> String:
	return "%s / %s" % [Keybinds.short("ammo_next"), Keybinds.short("ammo_prev")]


static func grades_for(weapon: String) -> Array:
	return AmmoDefs.WEAPONS.get(weapon, ["std"])


static func _deny(text: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_deny > 1500:
		_last_deny = now
		Bus.say(text, "warn")
		Sfx.play("deny")


## Next / previous grade in `list` after `cur` (wraps). Locked ammo refuses.
static func _step(list: Array, cur: String, dir: int) -> String:
	if not unlocked:
		_deny("Improved ammo is locked until objective '%s' is complete." % unlock_id)
		return "std"
	var i := list.find(cur)
	return str(list[posmod(maxi(i, 0) + dir, list.size())])


## Operative: cycle the grade of weapon "rifle" or "rocket". Returns the new grade.
static func cycle_op(weapon: String, dir: int) -> String:
	if not op.has(weapon):
		return "std"
	op[weapon] = _step(grades_for(weapon), str(op[weapon]), dir)
	if op[weapon] != "std":
		Sfx.play("good")
	return str(op[weapon])


static func op_tag(weapon: String) -> String:
	var g := str(op.get(weapon, "std"))
	return "" if g == "std" else " [%s]" % AmmoDefs.short(g)


## The grade this crossbow round fires, paying Salvage per round; standard when broke.
static func op_shot(weapon: String, stock: Stockpile) -> String:
	var g := str(op.get(weapon, "std"))
	if g == "std" or not unlocked or stock == null:
		return "std"
	var cost := float(AmmoDefs.GRADES[g].get("op_round", 0.0))
	if not stock.spend("salvage", cost):
		_deny("Not enough Salvage for %s rounds: firing standard." % AmmoDefs.label(g))
		return "std"
	return g


## Rocket: true when this shot is a cluster rocket (15 Salvage per 3 rockets).
static func op_rocket(stock: Stockpile) -> bool:
	if str(op.get("rocket", "std")) != "cluster" or not unlocked or stock == null:
		return false
	if not stock.spend("salvage", float(AmmoDefs.GRADES.cluster.op_rocket)):
		_deny("Not enough Salvage for a cluster rocket.")
		return false
	return true


# ---- network weapons and barracks ---------------------------------------------------------

static func has_grades(s: Structure) -> bool:
	return bool(s.def.get("grades", false))


## Command mode: Ctrl + wheel on the selected Sniper or Barracks. Switching drops graded rounds.
static func cycle_structure(s: Structure, dir: int) -> String:
	if s == null or not has_grades(s):
		return ""
	var key := "barracks" if s.type == "barracks" else "sniper"
	var next := _step(grades_for(key), s.grade, dir)
	if next != s.grade:
		s.grade = next
		s.grade_ammo = 0.0
		Sfx.play("click")
	return s.grade


## Charged when an ammo packet launches for `s`: the grade it carries ("" for standard).
static func surcharge(s: Structure, stock: Stockpile) -> String:
	if not unlocked or s.grade == "std" or not has_grades(s) or stock == null:
		return ""
	if not stock.spend("salvage", float(AmmoDefs.GRADES[s.grade].packet)):
		return ""
	return s.grade


## A graded packet arrived: its rounds join the structure's graded stock.
static func arrived(s: Structure, grade: String, rounds: float) -> void:
	if grade == "":
		return
	if s.grade != grade:
		return  # the player switched grade while it flew: it unloads as standard
	s.grade_ammo = minf(s.ammo, s.grade_ammo + rounds)


## The grade the next shot from `s` uses; consumes its graded rounds.
static func take_shot(s: Structure) -> String:
	var n := s.per_shot()
	if s.grade_ammo < n:
		return "std"
	s.grade_ammo -= n
	s.grade_ammo = minf(s.grade_ammo, maxf(0.0, s.ammo - n))
	return s.grade


# ---- effect on a hit ------------------------------------------------------------------------

## Damage `t` (a world target { on_hit } or an enemy { hit }) with ammo `grade`.
static func shoot(t: Dictionary, dmg: float, grade: String, world: World, point := Vector3.ZERO) -> void:
	var g: Dictionary = AmmoDefs.GRADES.get(grade, AmmoDefs.GRADES.std)
	var tier: Dictionary = t.get("tier", {})
	var d := dmg
	var pierce := false
	if grade == "ap" and not tier.is_empty() and (g.targets as Array).has(str(tier.get("name", ""))):
		d *= float(g.bonus)
		pierce = true
	piercing = pierce
	_deal(t, d, point)
	piercing = false
	if grade == "inc":
		if not tier.is_empty():
			_burns.append({ "t": t, "left": float(g.burn_time), "dps": float(g.burn_dps) })
		impact(world, point if point != Vector3.ZERO else _where(t), grade)


## Incendiary rounds scorch the creeper at the impact cell.
static func impact(world: World, point: Vector3, grade: String) -> void:
	if grade != "inc" or world == null:
		return
	var c := world.grid.world_to_cell(point.x, point.z)
	if world.grid.in_bounds(c.x, c.y):
		world.creeper.remove(c.x, c.y, float(AmmoDefs.GRADES.inc.clear))
		world.effects.burst(point, AmmoDefs.GRADES.inc.color, 0.9, 0.25)


static func color(grade: String) -> Color:
	return AmmoDefs.GRADES.get(grade, AmmoDefs.GRADES.std).color


static func tick(dt: float) -> void:
	for i in range(_burns.size() - 1, -1, -1):
		var b: Dictionary = _burns[i]
		var t: Dictionary = b.t
		if not (t.alive as Callable).call() or float(b.left) <= 0.0:
			_burns.remove_at(i)
			continue
		b.left = float(b.left) - dt
		_deal(t, float(b.dps) * dt, _where(t))


static func burning(t: Dictionary) -> bool:
	return _burns.any(func(b): return b.t == t)


static func _where(t: Dictionary) -> Vector3:
	var n := t.get("node") as Node3D
	return n.position if n != null and is_instance_valid(n) else Vector3.ZERO


static func _deal(t: Dictionary, dmg: float, point: Vector3) -> void:
	if t.has("on_hit"):
		(t.on_hit as Callable).call(dmg, point)
	elif t.has("hit"):
		(t.hit as Callable).call(dmg)
