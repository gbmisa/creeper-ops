class_name Penetration
## Static rules: armor penetration (Tarkov formula), world-material pass / ricochet. Rolls are
## passed in (0..1) so tests are deterministic.

## Armor resistance for a plate at `dur_pct` (0..100) of its max durability.
static func armor_a(cls: int, dur_pct: float) -> float:
	return cls * 10.0 * (121.0 - 5000.0 / (45.0 + 2.0 * dur_pct)) / 100.0


static func pen_chance(pen: float, a: float) -> float:
	if pen >= a:
		return 1.0
	if pen > a - 15.0:
		return 0.004 * pow(pen - a + 15.0, 2.0)
	return 0.0


## Damage / pen of one projectile of `ammo` at `speed` (both scale with v/v0).
static func scaled(ammo: Dictionary, speed: float) -> Dictionary:
	var r := clampf(speed / ammo["v0"], 0.0, 1.0)
	return {"dmg": ammo["dmg"] * r, "pen": ammo["pen"] * r}


## Fragmentation bonus multiplier (needs pen >= FRAG_MIN_PEN).
static func frag_mult(ammo: Dictionary, pen: float, roll: float) -> float:
	if ammo["frag"] > 0.0 and pen >= TacticalConfig.FRAG_MIN_PEN and roll < ammo["frag"]:
		return TacticalConfig.FRAG_DMG_MULT
	return 1.0


## Armor vs one shot. shot: dmg, pen, armor_dmg, glance (deg from surface).
## Returns {ricochet, pen (bool), chance, dmg, dur_loss}.
static func armor_hit(def: Dictionary, dur: float, shot: Dictionary, roll_pen: float, roll_ric: float) -> Dictionary:
	var out := {"ricochet": false, "pen": false, "chance": 0.0, "dmg": 0.0, "dur_loss": 0.0}
	if def["ricochet"] > 0.0 and shot.get("glance", 90.0) <= TacticalConfig.ARMOR_RICOCHET_GLANCE_DEG and roll_ric < def["ricochet"]:
		out["ricochet"] = true
		return out
	var a := armor_a(def["cls"], 100.0 * dur / def["max_dur"])
	var pen: float = shot["pen"]
	var p := pen_chance(pen, a)
	out["chance"] = p
	out["pen"] = roll_pen < p
	if out["pen"]:
		out["dmg"] = shot["dmg"] * clampf(0.5 + pen / (2.0 * a), 0.6, 1.0)
	else:
		out["dmg"] = shot["dmg"] * def["blunt"]
	out["dur_loss"] = pen * shot["armor_dmg"] * def["destruct"] * clampf(pen / a, 0.6, 1.1)
	return out


## World material vs a bullet. glance = degrees between flight path and the surface.
## Returns {ricochet, pass, resist, pen_loss, dmg_mult, speed_mult, deviate_deg}.
static func world_hit(mat_id: String, thick: float, pen: float, glance: float, roll: float) -> Dictionary:
	var m := MaterialDefs.of(mat_id)
	var out := {"ricochet": false, "pass": false, "resist": 0.0, "pen_loss": 0.0, "dmg_mult": 1.0, "speed_mult": 1.0, "deviate_deg": 0.0}
	if m["ric_angle"] > 0.0 and glance <= m["ric_angle"] and roll < m["ric_chance"]:
		out["ricochet"] = true
		out["speed_mult"] = TacticalConfig.RICOCHET_SPEED_MULT
		return out
	var f := clampf(thick / TacticalConfig.WALL_REF_THICK, 0.0, TacticalConfig.WALL_THICK_CAP)
	var eff: float = m["resist"] * f if m["resist"] != INF else INF
	out["resist"] = eff
	if pen > eff:
		out["pass"] = true
		out["pen_loss"] = TacticalConfig.PASS_PEN_LOSS * eff
		out["dmg_mult"] = TacticalConfig.PASS_DMG_MULT
		out["speed_mult"] = TacticalConfig.PASS_SPEED_MULT
		out["deviate_deg"] = TacticalConfig.PASS_DEVIATE_DEG
	return out
