class_name Gun
extends RefCounted
## Runtime weapon state: magazines + chamber, fire modes, bolt/pump cycle, reloads, zero.
## Guns never jam or wear (Gregory 2026-10-16). Pure logic; call update(dt) every frame. The caller plays animations.

var id := ""
var def: Dictionary
var mag: Magazine
var spares: Array[Magazine] = []  # detachable / en-bloc: spare mags. tube: one pouch of loose shells
var chamber := ""
var mode := "semi"
var needs_cycle := false
var zero_idx := 0
var busy_kind := ""  # "cycle", "reload"
var busy_t := 0.0
var fire_cd := 0.0
var ammo_pick := ""  # grade loaded by refill()
var _fast := false
var fit := {}  # slot -> attachment id (AttachmentDefs); changes only through set_fit / clear_fit
var fit_ver := 0  # bumps on every change so the viewmodel rebuilds its parts
var zoom_hi := true  # variable sight (LPVO): at its top zoom


func _init(weapon_id: String) -> void:
	id = weapon_id
	def = WeaponDefs.of(weapon_id)
	mode = def["modes"][0]
	ammo_pick = TacAmmoDefs.grades(def["cal"])[0]
	zero_idx = 0
	for slot in def.get("fit", {}):
		fit[slot] = def["fit"][slot]
	refill()


func refill() -> void:
	mag = Magazine.new(int(stat("mag")))
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
			var m := Magazine.new(int(stat("mag")))
			m.fill(ammo_pick)
			spares.append(m)
		if def["action"] == "detachable":
			chamber = mag.pop()
	needs_cycle = false
	busy_kind = ""
	busy_t = 0.0
	fire_cd = 0.0


## A stat with the fitted attachments applied (player side; bots fit nothing, so they read the base). Names
## missing from the def (ads_mult, hip, noise, flash, vel) start at 1.0. "scope" is the sight's current zoom.
func stat(n: String) -> float:
	if n == "scope":
		return scope_now()
	var v: float = float(def[n]) if def.has(n) else 1.0
	for id in fit.values():
		v *= float(AttachmentDefs.ROWS[id]["mods"].get(n, 1.0))
	return roundf(v) if n == "mag" else v


func scope_now() -> float:
	var sid: String = fit.get("sight", "")
	if sid == "":
		return float(def.get("scope", 1.0))
	var r: Dictionary = AttachmentDefs.ROWS[sid]
	return float(r["zoom_max"]) if zoom_hi and r.has("zoom_max") else float(r["zoom"])


func reticle() -> String:
	var sid: String = fit.get("sight", "")
	return "mildot" if sid == "" else String(AttachmentDefs.ROWS[sid]["ret"])


func toggle_zoom() -> void:
	var sid: String = fit.get("sight", "")
	if sid != "" and AttachmentDefs.ROWS[sid].has("zoom_max"):
		zoom_hi = not zoom_hi


## The def with every fitted stat applied, plus ads_pos on the fitted sight's line. For recoil, ADS and the viewmodel.
func eff_def() -> Dictionary:
	var d := def.duplicate()
	for k in ["up", "side", "moa", "reload", "reload_fast", "mag", "scope", "ads_mult", "hip", "noise", "flash", "vel"]:
		d[k] = stat(k)
	d["ads_pos"] = AttachmentMounts.ads_pos(def, fit.get("sight", ""))
	return d


## Fits `id` into its slot (replacing any). The mag cap follows an extended magazine.
func set_fit(slot: String, id: String) -> void:
	fit[slot] = id
	_after_fit()


## Takes a part off. Returns rounds that no longer fit the magazine (ammo ids), normally [].
func clear_fit(slot: String) -> Array[String]:
	fit.erase(slot)
	return _after_fit()


func _after_fit() -> Array[String]:
	fit_ver += 1
	var spill: Array[String] = []
	if def["action"] == "tube":
		return spill
	var cap := int(stat("mag"))
	while mag.rounds.size() > cap:
		spill.append(mag.pop())
	mag.cap = cap
	return spill


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
	var ammo := loaded_ammo()
	if ammo == "":
		res["reason"] = "empty"
		return res
	var a := TacAmmoDefs.of(ammo)
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


## Start a reload. fast = drop the old mag (gone). False if it can't start.
func reload(fast: bool = false) -> bool:
	if busy() or needs_cycle or spares.is_empty():
		return false
	match def["action"]:
		"enbloc":
			if mag.count() > 0:
				return false
		"tube":
			if mag.is_full() or spares[0].count() == 0 or not mag.accepts(spares[0].top()):
				return false
		_:
			pass
	_fast = fast
	busy_kind = "reload"
	busy_t = stat("reload_fast") if fast else stat("reload")
	if def["action"] == "detachable" and chamber == "":
		busy_t += TacticalConfig.CHAMBER_TIME
	return true


func _finish() -> void:
	var kind := busy_kind
	busy_kind = ""
	match kind:
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


## Direction(s) for the shot just fired: zero elevation, MOA deviation, pellets. `aim` is the barrel's basis
## (hip inaccuracy is the recoil model's hip wander, FB-I: there is no hip cone). `ads` is kept for callers.
func shot_dirs(aim: Basis, ammo_id: String, _ads: bool, rng: RandomNumberGenerator) -> Array[Vector3]:
	var a := TacAmmoDefs.of(ammo_id)
	var out: Array[Vector3] = []
	var base_dev := deg_to_rad(def["moa"] / 60.0 * a["acc"])
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


## Plain-data snapshot (MULTIPLAYER.md rule 6). Rng state is not serialized.
func to_dict() -> Dictionary:
	var sp := []
	for m in spares:
		sp.append(m.to_dict())
	return {
		"id": id, "mag": mag.to_dict(), "spares": sp, "chamber": chamber, "mode": mode,
		"needs_cycle": needs_cycle, "zero_idx": zero_idx, "busy_kind": busy_kind,
		"busy_t": busy_t, "fire_cd": fire_cd, "ammo_pick": ammo_pick,
		"fit": fit.duplicate(), "fit_ver": fit_ver, "zoom_hi": zoom_hi,
	}


static func from_dict(d: Dictionary) -> Gun:
	var g := Gun.new(str(d.get("id", "ak47")))
	g.mag = Magazine.from_dict(d.get("mag", {}) as Dictionary)
	g.spares.clear()
	for m in d.get("spares", []):
		g.spares.append(Magazine.from_dict(m as Dictionary))
	g.chamber = str(d.get("chamber", ""))
	g.mode = str(d.get("mode", "semi"))
	g.needs_cycle = bool(d.get("needs_cycle", false))
	g.zero_idx = int(d.get("zero_idx", 0))
	g.busy_kind = str(d.get("busy_kind", ""))
	g.busy_t = float(d.get("busy_t", 0.0))
	g.fire_cd = float(d.get("fire_cd", 0.0))
	g.ammo_pick = str(d.get("ammo_pick", ""))
	g.fit = (d.get("fit", {}) as Dictionary).duplicate()
	g.fit_ver = int(d.get("fit_ver", 0))
	g.zoom_hi = bool(d.get("zoom_hi", true))
	return g
