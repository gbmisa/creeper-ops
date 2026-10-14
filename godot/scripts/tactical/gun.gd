class_name Gun
extends RefCounted
## Runtime weapon state: magazines + chamber, fire modes, bolt/pump cycle, reloads, zero, wear
## and malfunctions. Pure logic; call update(dt) every frame. The caller plays animations.

var def: Dictionary
var mag: Magazine
var spares: Array[Magazine] = []  # detachable / en-bloc: spare mags. tube: one pouch of loose shells
var chamber := ""
var mode := "semi"
var needs_cycle := false
var durability := 1.0
var malf := ""  # "", "misfire", "feed", "jam"
var malf_known := false
var zero_idx := 0
var busy_kind := ""  # "cycle", "reload", "fix"
var busy_t := 0.0
var fire_cd := 0.0
var ammo_pick := ""  # grade loaded by refill()
var _fast := false


func _init(weapon_id: String) -> void:
	def = WeaponDefs.of(weapon_id)
	mode = def["modes"][0]
	ammo_pick = TacAmmoDefs.grades(def["cal"])[0]
	zero_idx = 0
	refill()


func refill() -> void:
	mag = Magazine.new(def["mag"])
	mag.fill(ammo_pick)
	chamber = ""
	spares.clear()
	if def["action"] == "tube":
		var pouch := Magazine.new(def["spares"])
		pouch.fill(ammo_pick)
		spares.append(pouch)
		chamber = ammo_pick
	else:
		for i in def["spares"]:
			var m := Magazine.new(def["mag"])
			m.fill(ammo_pick)
			spares.append(m)
		if def["action"] == "detachable":
			chamber = mag.pop()
	needs_cycle = false
	malf = ""
	malf_known = false
	busy_kind = ""
	busy_t = 0.0
	fire_cd = 0.0
	durability = 1.0


func busy() -> bool:
	return busy_t > 0.0


func zero_dist() -> float:
	return def["zeros"][zero_idx]


func zero_step(dir: int) -> void:
	zero_idx = clampi(zero_idx + dir, 0, (def["zeros"] as Array).size() - 1)


func cycle_mode() -> void:
	var m: Array = def["modes"]
	mode = m[(m.find(mode) + 1) % m.size()]


## Ammo id the next shot would use ("" if none).
func loaded_ammo() -> String:
	return mag.top() if def["action"] == "enbloc" else chamber


func rounds_total() -> int:
	return mag.count() + (1 if chamber != "" else 0)


func update(dt: float) -> void:
	fire_cd = maxf(0.0, fire_cd - dt)
	if busy_t > 0.0:
		busy_t -= dt
		if busy_t <= 0.0:
			busy_t = 0.0
			_finish()


## Trigger pull. {fired, reason, ammo, pellets, ping, last}
func fire(rng: RandomNumberGenerator) -> Dictionary:
	var res := {"fired": false, "reason": "", "ammo": "", "pellets": 0, "ping": false, "last": false}
	if needs_cycle and not busy():
		res["reason"] = "cycle"
		return res
	if busy() or fire_cd > 0.0:
		res["reason"] = "busy"
		return res
	if malf != "":
		res["reason"] = "click"
		return res
	var ammo := loaded_ammo()
	if ammo == "":
		res["reason"] = "empty"
		return res
	var a := TacAmmoDefs.of(ammo)
	if rng.randf() < TacticalConfig.MALF_BASE * (1.0 - durability) + a["malf"]:
		force_malf(["misfire", "feed", "jam"][rng.randi() % 3])
		res["reason"] = "click"
		return res
	durability = maxf(0.0, durability - TacticalConfig.WEAR_PER_SHOT)
	fire_cd = 60.0 / def["rpm"]
	res["fired"] = true
	res["ammo"] = ammo
	res["pellets"] = a["pellets"]
	match def["action"]:
		"enbloc":
			mag.pop()
			res["ping"] = mag.count() == 0
		"tube":
			chamber = ""
			needs_cycle = true
		_:
			chamber = ""
			if def["cycle"] > 0.0:
				needs_cycle = true
			else:
				chamber = mag.pop()
	res["last"] = loaded_ammo() == "" and mag.count() == 0
	return res


## Trigger released: bolt / pump cycle starts by itself.
func release() -> void:
	if needs_cycle and not busy():
		busy_kind = "cycle"
		busy_t = def["cycle"]


func force_malf(kind: String) -> void:
	malf = kind
	malf_known = false


## First press reveals the malfunction, the second starts the fix. Returns the state text.
func inspect() -> String:
	if busy():
		return "busy"
	if malf == "":
		return "ok"
	if not malf_known:
		malf_known = true
		return malf
	busy_kind = "fix"
	busy_t = TacticalConfig.FIX_TIME[malf]
	return "fixing"


## Start a reload. fast = drop the old mag (gone). False if it can't start.
func reload(fast: bool = false) -> bool:
	if busy() or needs_cycle or spares.is_empty():
		return false
	match def["action"]:
		"enbloc":
			if mag.count() > 0:
				return false
		"tube":
			if mag.is_full() or spares[0].count() == 0:
				return false
		_:
			pass
	_fast = fast
	busy_kind = "reload"
	busy_t = def["reload_fast"] if fast else def["reload"]
	if def["action"] == "detachable" and chamber == "":
		busy_t += TacticalConfig.CHAMBER_TIME
	return true


func _finish() -> void:
	var kind := busy_kind
	busy_kind = ""
	match kind:
		"fix":
			malf = ""
			malf_known = false
		"cycle":
			needs_cycle = false
			if def["action"] == "tube" or def["cycle"] > 0.0:
				chamber = mag.pop()
		"reload":
			_finish_reload()


func _finish_reload() -> void:
	match def["action"]:
		"enbloc":
			mag = spares.pop_front()
		"tube":
			mag.push(spares[0].pop())
		_:
			var best := spares[0]
			for m in spares:
				if m.count() > best.count():
					best = m
			spares.erase(best)
			if not _fast:
				spares.append(mag)
			mag = best
			if chamber == "":
				chamber = mag.pop()


## Direction(s) for the shot just fired: zero elevation, MOA deviation, hip cone, pellets.
func shot_dirs(aim: Basis, ammo_id: String, ads: bool, rng: RandomNumberGenerator) -> Array[Vector3]:
	var a := TacAmmoDefs.of(ammo_id)
	var out: Array[Vector3] = []
	var base_dev := deg_to_rad(def["moa"] / 60.0 * a["acc"])
	if not ads:
		base_dev += deg_to_rad(TacticalConfig.HIP_CONE_DEG)
	var elev := Ballistics.zero_angle(ammo_id, zero_dist())
	var centre := aim * Vector3(0, 0, -1).rotated(Vector3.RIGHT, elev)
	var shot_off := _disc(rng, base_dev)
	for i in a["pellets"]:
		var off := shot_off
		if a["pellets"] > 1:
			off += _disc(rng, deg_to_rad(def.get("pellet_spread", 2.2)))
		var d := centre.rotated(aim.x, off.y).rotated(aim.y, off.x)
		out.append(d.normalized())
	return out


static func _disc(rng: RandomNumberGenerator, radius: float) -> Vector2:
	var ang := rng.randf() * TAU
	var r := radius * sqrt(rng.randf())
	return Vector2(cos(ang), sin(ang)) * r
