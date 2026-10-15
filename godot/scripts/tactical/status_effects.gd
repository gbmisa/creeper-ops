class_name StatusEffects
extends RefCounted
## Tarkov-style build-up status meters + medical buffs. Per player, no scene dependencies.
## Meters are 0..1 (1 = bad): pain, radiation, toxication, dehydration, energy, fatigue, contusion.
## Warning icon from 0.5; the full effect triggers at 1. to_dict/from_dict for multiplayer.

const METERS := ["pain", "radiation", "toxication", "dehydration", "energy", "fatigue", "contusion"]

# Rates (per second unless noted).
const DEHYDRATION_RATE := 1.0 / 600.0   # ~10 min to full at rest
const ENERGY_RATE := 1.0 / 480.0        # ~8 min to drained at rest
const PAIN_DECAY := 0.02
const PAIN_PER_DMG := 0.01              # 100 damage -> full pain
const PAIN_FRACTURE := 0.3
const RADIATION_RATE := 0.05            # 20 s in the hot zone -> full
const RADIATION_DECAY := 0.005
const TOXICATION_DECAY := 0.01
const FATIGUE_RATE := 0.05
const FATIGUE_DECAY := 0.03
const CONTUSION_DECAY := 0.1            # ~10 s
const RAD_DOT := 0.5                    # HP/s when radiation is full
const TOX_DOT := 0.75                   # HP/s when toxication is full
const DEHYDRATION_DOT := 0.25           # HP/s once fully dehydrated

var m := {}
var pain_off_t := 0.0      # Analgin/Morphine/Adrenaline: pain effects suppressed
var regen_rate := 0.0      # HP/s (Propital, eTG-c)
var regen_t := 0.0
var propital_t := 0.0      # tremor starts in the last 60 s
var stam_buff_t := 0.0      # faster stamina regen (SJ6, stim)
var stam_buff_mult := 1.0
var sj6_t := 0.0            # on expiry: fatigue + tremor
var iodine_t := 0.0         # radiation build-up x0.4
var tremor_t := 0.0         # side-effect tremor


func _init() -> void:
	reset()


func reset() -> void:
	for k in METERS:
		m[k] = 0.0
	pain_off_t = 0.0
	regen_rate = 0.0
	regen_t = 0.0
	propital_t = 0.0
	stam_buff_t = 0.0
	stam_buff_mult = 1.0
	sj6_t = 0.0
	iodine_t = 0.0
	tremor_t = 0.0


func bump(meter: String, x: float) -> void:
	m[meter] = clampf(float(m.get(meter, 0.0)) + x, 0.0, 1.0)


## Immediate pain from a hit. Called by the player when BodyHealth takes damage.
func on_hit(dmg: float, heavy_bleed: bool, fracture: bool) -> void:
	bump("pain", dmg * PAIN_PER_DMG)
	if heavy_bleed:
		bump("pain", 0.15)
	if fracture:
		bump("pain", PAIN_FRACTURE)


func add_contusion() -> void:
	m["contusion"] = 1.0


## ctx: sprinting, jumping, moving, bleeding (any), heavy_bleed, fractured, in_hot_zone.
func tick(dt: float, ctx: Dictionary, body: BodyHealth) -> void:
	if body.dead:
		return
	var sprinting: bool = ctx.get("sprinting", false)
	var bleeding: bool = ctx.get("bleeding", false)
	# Dehydration / energy drain over time, faster when sprinting or bleeding.
	var drain_mult := 1.0 + (2.0 if sprinting else 0.0) + (1.0 if bleeding else 0.0)
	bump("dehydration", DEHYDRATION_RATE * drain_mult * dt)
	bump("energy", ENERGY_RATE * (4.0 if sprinting else 1.0) * dt)
	# Fatigue builds sprinting/jumping while low on energy, recovers at rest.
	if (sprinting or ctx.get("jumping", false)) and float(m["energy"]) > 0.6:
		bump("fatigue", FATIGUE_RATE * dt)
	elif not ctx.get("moving", false):
		bump("fatigue", -FATIGUE_DECAY * dt)
	# Pain rises with open wounds, decays slowly.
	if bleeding:
		bump("pain", (0.06 if ctx.get("heavy_bleed", false) else 0.02) * dt)
	if ctx.get("fractured", false):
		bump("pain", 0.03 * dt)
	bump("pain", -PAIN_DECAY * dt)
	# Radiation in the hot zone (iodine slows build-up 60 %).
	if ctx.get("in_hot_zone", false):
		bump("radiation", RADIATION_RATE * (0.4 if iodine_t > 0.0 else 1.0) * dt)
	else:
		bump("radiation", -RADIATION_DECAY * dt)
	bump("toxication", -TOXICATION_DECAY * dt)
	bump("contusion", -CONTUSION_DECAY * dt)
	# Buff timers.
	pain_off_t = maxf(0.0, pain_off_t - dt)
	iodine_t = maxf(0.0, iodine_t - dt)
	tremor_t = maxf(0.0, tremor_t - dt)
	stam_buff_t = maxf(0.0, stam_buff_t - dt)
	if stam_buff_t <= 0.0:
		stam_buff_mult = 1.0
	if propital_t > 0.0:
		propital_t -= dt
		if propital_t < 60.0:
			tremor_t = maxf(tremor_t, 1.0)  # tremor for the last minute
	if sj6_t > 0.0:
		sj6_t -= dt
		if sj6_t <= 0.0:  # SJ6 wears off: fatigue + tremor
			bump("fatigue", 0.5)
			tremor_t = maxf(tremor_t, 30.0)
	# Regen pool heals the worst zone first.
	if regen_t > 0.0 and regen_rate > 0.0:
		regen_t -= dt
		body.heal_pool(regen_rate * dt)
		if regen_t <= 0.0:
			regen_rate = 0.0
	# Full-meter damage over time.
	if float(m["radiation"]) >= 1.0:
		body.hit("thorax", RAD_DOT * dt)
	if float(m["toxication"]) >= 1.0:
		body.hit("thorax", TOX_DOT * dt)
	if float(m["dehydration"]) >= 1.0:
		body.hit("thorax", DEHYDRATION_DOT * dt)


func pain_active() -> bool:
	return float(m["pain"]) >= 1.0 and pain_off_t <= 0.0


func tremor() -> bool:
	return pain_active() or tremor_t > 0.0


## Sway multiplier (tremor doubles it).
func sway_mult() -> float:
	return 2.0 if tremor() else 1.0


## ADS takes longer in full pain.
func ads_time_mult() -> float:
	return 1.3 if pain_active() else 1.0


func stamina_regen_mult() -> float:
	var x := 1.0
	if float(m["dehydration"]) >= 1.0:
		x *= 0.5
	if float(m["energy"]) >= 1.0:
		x *= 0.5
	if float(m["fatigue"]) >= 1.0:
		x *= 0.7
	if stam_buff_t > 0.0:
		x *= stam_buff_mult
	return x


func max_stamina_mult() -> float:
	return 0.7 if float(m["radiation"]) >= 1.0 else 1.0


func muffle() -> float:
	return clampf(float(m["contusion"]), 0.0, 1.0)


func nausea() -> float:
	return 1.0 if float(m["toxication"]) >= 1.0 else 0.0


## Candidate zones for a zone-targeted med. Used by the inventory zone picker.
static func zone_candidates(body: BodyHealth, use: Dictionary) -> Array:
	var effect := String(use.get("effect", ""))
	var out := []
	if effect == "stop_bleed":
		var kind := String(use.get("bleed", "light"))
		var limb_only := bool(use.get("limb_only", false))
		for b in body.bleeds:
			var heavy: bool = float(b["rate"]) >= TacticalConfig.HEAVY_BLEED_DPS
			if (kind == "heavy") == heavy and not out.has(b["zone"]) \
					and (not limb_only or String(b["zone"]) in BodyHealth.LIMBS):
				out.append(b["zone"])
	elif effect == "fix_fracture":
		for z in body.fractured:
			out.append(z)
	elif effect == "surgery":
		for z in BodyHealth.LIMBS:
			if float(body.hp[z]) <= 0.0:
				out.append(z)
	return out


## Pick the zone for a med use. `want` is the player's choice ("" = auto). Returns a zone,
## "" when the med needs no zone, or "NO_TARGET" when there is nothing to treat.
static func pick_zone(body: BodyHealth, use: Dictionary, want: String) -> String:
	var effect := String(use.get("effect", ""))
	if not effect in ["stop_bleed", "fix_fracture", "surgery"]:
		return ""
	var cands := zone_candidates(body, use)
	if cands.is_empty():
		return "NO_TARGET"
	if want != "" and cands.has(want):
		return want
	# Auto: the candidate with the lowest HP.
	var best := String(cands[0])
	for z in cands:
		if float(body.hp[z]) < float(body.hp[best]):
			best = String(z)
	return best


## Apply a finished med use. `use` is the item's use dict, `zone` the chosen zone (may be "").
## Returns {"msg": String, "stamina_refill": bool} for the player to finish.
func apply_med(use: Dictionary, zone: String, body: BodyHealth) -> Dictionary:
	var res := {"msg": "", "stamina_refill": false}
	match String(use.get("effect", "")):
		"stop_bleed":
			var kind: String = use.get("bleed", "light")
			var n := body.stop_bleed(zone, kind)
			if n > 0:
				res["msg"] = "Stopped %s bleed%s" % [kind, "" if zone == "" else " (%s)" % zone]
			else:
				res["msg"] = "No %s bleed to treat" % kind
		"fix_fracture":
			if body.fractured.has(zone):
				body.fractured.erase(zone)
				res["msg"] = "Splinted %s" % zone
			else:
				res["msg"] = "No fracture there"
		"surgery":
			if body.surgery(zone):
				res["msg"] = "Surgery on %s: limb restored at 60%%" % zone
			else:
				res["msg"] = "Nothing to operate on"
		"hp_pool":
			body.heal_pool(float(use.get("amount", 100.0)))
			for z in use.get("stop", []):
				body.stop_bleed("", String(z))
			if bool(use.get("all_wounds", false)):
				body.fractured.clear()
			res["msg"] = "+%d HP" % int(use.get("amount", 100.0))
		"pain_off":
			pain_off_t = maxf(pain_off_t, float(use.get("dur", 95.0)))
			res["msg"] = "Painkillers: no pain for %ds" % int(use.get("dur", 95.0))
		"regen":
			regen_rate = float(use.get("rate", 1.0))
			regen_t = float(use.get("dur", 300.0))
			if use.get("id", "") == "med_propital":
				propital_t = regen_t
			res["msg"] = "Regenerating %g HP/s" % regen_rate
		"stim":
			res["stamina_refill"] = true
			stam_buff_t = float(use.get("dur", 20.0))
			stam_buff_mult = float(use.get("mult", 2.0))
			res["msg"] = "Stim: stamina restored"
		"sj6":
			res["stamina_refill"] = true
			stam_buff_t = 240.0
			stam_buff_mult = 1.75
			sj6_t = 240.0
			res["msg"] = "SJ6: 4 min of legs"
		"adrenaline":
			res["stamina_refill"] = true
			pain_off_t = maxf(pain_off_t, 60.0)
			res["msg"] = "Adrenaline: pain gone, full stamina"
		"etgc":
			regen_rate = 6.5
			regen_t = 60.0
			bump("toxication", 0.4)
			res["msg"] = "eTG-c: rapid regen, toxic"
		"iodine":
			iodine_t = 300.0
			res["msg"] = "Iodine: radiation build-up slowed"
		"hydrate":
			bump("dehydration", -float(use.get("amount", 0.5)))
			bump("energy", -float(use.get("energy", 0.0)))
			res["msg"] = "Hydrated"
		"feed":
			bump("energy", -float(use.get("amount", 0.3)))
			res["msg"] = "Ate"
	# Generic side effects any med can declare.
	bump("dehydration", float(use.get("dehydration", 0.0)))
	bump("toxication", float(use.get("toxication", 0.0)))
	return res


func to_dict() -> Dictionary:
	return {"m": m.duplicate(), "pain_off_t": pain_off_t, "regen_rate": regen_rate, "regen_t": regen_t,
		"propital_t": propital_t, "stam_buff_t": stam_buff_t, "stam_buff_mult": stam_buff_mult,
		"sj6_t": sj6_t, "iodine_t": iodine_t, "tremor_t": tremor_t}


func from_dict(d: Dictionary) -> void:
	reset()
	for k in METERS:
		m[k] = clampf(float((d.get("m", {}) as Dictionary).get(k, 0.0)), 0.0, 1.0)
	pain_off_t = float(d.get("pain_off_t", 0.0))
	regen_rate = float(d.get("regen_rate", 0.0))
	regen_t = float(d.get("regen_t", 0.0))
	propital_t = float(d.get("propital_t", 0.0))
	stam_buff_t = float(d.get("stam_buff_t", 0.0))
	stam_buff_mult = float(d.get("stam_buff_mult", 1.0))
	sj6_t = float(d.get("sj6_t", 0.0))
	iodine_t = float(d.get("iodine_t", 0.0))
	tremor_t = float(d.get("tremor_t", 0.0))
