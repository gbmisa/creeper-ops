class_name BowDraw
## F146: draw-and-hold for the compound bow (action "bow"). Hold fire to draw (BowDefs.DRAW_TIME to full), release to
## shoot: speed, and with it damage and pen, scale with the draw. Full draw costs arm stamina and, after SHAKE_AFTER
## seconds, the aim shakes. Releasing below MIN_DRAW (or sprinting / opening a menu mid-draw) lets down without shooting.
## State (bow_draw, bow_hold) lives on PlayerWeapons; the viewmodel reads bow_draw for its draw pose.


static func is_bow(w: PlayerWeapons) -> bool:
	return w.gun != null and w.gun.def["action"] == "bow"


## Every frame a bow is in hand. down = fire held and allowed; raw = fire held at all; pressed = fresh press.
static func tick(w: PlayerWeapons, down: bool, pressed: bool, raw: bool, delta: float) -> void:
	var g := w.gun
	if down and g.chamber != "" and not g.busy() and g.fire_cd <= 0.0 and (w.bow_draw > 0.0 or pressed):
		w.bow_draw = minf(1.0, w.bow_draw + delta / BowDefs.DRAW_TIME)
		if w.bow_draw >= 1.0:
			w.bow_hold += delta
			w.arm_stamina = maxf(0.0, w.arm_stamina - BowDefs.HOLD_DRAIN * delta)
		return
	if w.bow_draw <= 0.0:
		return
	var f := w.bow_draw
	w.bow_draw = 0.0
	w.bow_hold = 0.0
	if not raw and f >= BowDefs.MIN_DRAW and g.chamber != "":
		var res := g.fire(w.rng)
		if res["fired"]:
			w.shoot(res, speed_mult(f))


## Launch speed share for a draw fraction: MIN_SPEED at the minimum draw, 1.0 at full.
static func speed_mult(f: float) -> float:
	return lerpf(BowDefs.MIN_SPEED, 1.0, clampf((f - BowDefs.MIN_DRAW) / (1.0 - BowDefs.MIN_DRAW), 0.0, 1.0))


## Extra sway (deg) once the draw has been held past SHAKE_AFTER.
static func shake(w: PlayerWeapons, t: float) -> Vector2:
	if w.bow_hold <= BowDefs.SHAKE_AFTER:
		return Vector2.ZERO
	var amp := BowDefs.SHAKE_DEG * clampf((w.bow_hold - BowDefs.SHAKE_AFTER) / BowDefs.SHAKE_RAMP, 0.0, 1.0)
	return Vector2(sin(t * 23.0), sin(t * 17.0 + 1.0)) * amp


## The bow-hand kick: the view lifts a little (no recoil curve).
static func kick(w: PlayerWeapons) -> void:
	w.player.turn_view(Vector2(BowDefs.KICK_DEG, 0.0))


## HUD text: arrows / bolts left (nocked + loose in the bags). Infinite-ammo maps show the nock only.
static func counter(w: PlayerWeapons) -> String:
	var g := w.gun
	var cal: String = g.def["cal"]
	var word := "Arrows" if cal == "arrow" else "Bolts"
	var nocked := 1 if g.chamber != "" else 0
	if w.reloader.infinite:
		return "%s: %s" % [word, "nocked" if nocked > 0 else "none nocked"]
	var loose := 0
	for it in w.inv.all_items():
		if it["id"] in TacAmmoDefs.ROWS and TacAmmoDefs.ROWS[it["id"]]["cal"] == cal:
			loose += int(it["count"])
	return "%s: %d" % [word, nocked + loose]
