class_name Ballistics
extends Node3D
## Live projectiles stepped in fixed substeps with segment raycasts on layers 1+2.
## Hits on hitbox rigs go to BodyHealth.shoot; world colliders use meta "mat" / "thick".
## Signals carry plain dictionaries so any HUD / decal system can listen.

signal impact(info: Dictionary)  # pos, normal, mat, kind ("stop"/"pass"/"ricochet")
signal body_hit(info: Dictionary)  # BodyHealth result + owner, dist, ammo, pos

var shots: Array = []
var auto_step := true
var rng := RandomNumberGenerator.new()
static var _zero_cache := {}


func _physics_process(dt: float) -> void:
	if auto_step:
		step(dt)


## One projectile. exclude: the shooter's own hitbox RIDs.
func spawn(origin: Vector3, dir: Vector3, ammo_id: String, exclude: Array[RID] = [], speed_mult: float = 1.0) -> void:
	var ammo := TacAmmoDefs.of(ammo_id)
	shots.append({"pos": origin, "origin": origin, "vel": dir.normalized() * ammo["v0"] * speed_mult, "ammo": ammo,
		"exclude": exclude, "age": 0.0, "bounces": 0, "pen_loss": 0.0, "dmg_mult": 1.0})


func step(dt: float) -> void:
	var n := maxi(1, ceili(dt / TacticalConfig.SIM_STEP))
	var sub := dt / n
	var space := get_world_3d().direct_space_state
	var alive: Array = []
	for s in shots:
		var ok := true
		for i in n:
			if not _advance(s, sub, space):
				ok = false
				break
		if ok:
			alive.append(s)
	shots = alive


## Same motion rule for live shots and the zero solver. Returns [pos, vel].
static func motion(pos: Vector3, vel: Vector3, drag: float, dt: float) -> Array:
	vel *= exp(-drag * vel.length() * dt)
	vel.y -= TacticalConfig.GRAVITY * dt
	return [pos + vel * dt, vel]


## Launch elevation (radians above the sight line) that crosses the sight line at `dist` metres.
static func zero_angle(ammo_id: String, dist: float) -> float:
	var key := "%s:%d" % [ammo_id, int(dist)]
	if _zero_cache.has(key):
		return _zero_cache[key]
	var ammo := TacAmmoDefs.of(ammo_id)
	var lo := 0.0
	var hi := 0.2
	for i in 40:
		var mid := (lo + hi) * 0.5
		if height_at(ammo_id, mid, dist) < 0.0:
			lo = mid
		else:
			hi = mid
	_zero_cache[key] = (lo + hi) * 0.5
	return _zero_cache[key]


## Height above the launch line at horizontal distance `dist` (flat fire, no scene needed).
static func height_at(ammo_id: String, elev: float, dist: float) -> float:
	var ammo := TacAmmoDefs.of(ammo_id)
	var pos := Vector3.ZERO
	var vel: Vector3 = Vector3(0, sin(elev), -cos(elev)) * ammo["v0"]
	var t := 0.0
	while -pos.z < dist and t < TacticalConfig.MAX_FLIGHT_TIME:
		var prev := pos
		var r := motion(pos, vel, ammo["drag"], TacticalConfig.SIM_STEP / 2.0)
		pos = r[0]
		vel = r[1]
		t += TacticalConfig.SIM_STEP / 2.0
		if -pos.z >= dist:
			var f := (dist + prev.z) / (prev.z - pos.z)
			return lerpf(prev.y, pos.y, f)
	return -1000.0


func _advance(s: Dictionary, dt: float, space: PhysicsDirectSpaceState3D) -> bool:
	var ammo: Dictionary = s["ammo"]
	var r := motion(s["pos"], s["vel"], ammo["drag"], dt)
	var np: Vector3 = r[0]
	s["vel"] = r[1]
	s["age"] += dt
	var q := PhysicsRayQueryParameters3D.create(s["pos"], np, TacticalConfig.BULLET_MASK, s["exclude"])
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		s["pos"] = np
		return s["age"] < TacticalConfig.MAX_FLIGHT_TIME and (s["vel"] as Vector3).length() > TacticalConfig.MIN_SPEED and np.y > -50.0
	return _on_hit(s, hit)


func _on_hit(s: Dictionary, hit: Dictionary) -> bool:
	var vel: Vector3 = s["vel"]
	var speed := vel.length()
	var dir := vel / speed
	var n: Vector3 = hit["normal"]
	var glance := 90.0 - rad_to_deg(acos(clampf(absf(dir.dot(n)), 0.0, 1.0)))
	var sc := Penetration.scaled(s["ammo"], speed)
	var pen: float = maxf(0.0, sc["pen"] - s["pen_loss"])
	var dmg: float = sc["dmg"] * s["dmg_mult"]
	var rig := HitboxRig.lookup(hit["collider"])
	if not rig.is_empty():
		var shot := {"dmg": dmg, "pen": pen, "armor_dmg": s["ammo"]["armor_dmg"], "ammo": s["ammo"], "glance": glance,
			"lbleed": s["ammo"]["lbleed"], "hbleed": s["ammo"]["hbleed"]}
		var res: Dictionary = (rig["body"] as BodyHealth).shoot(rig["zone"], shot)
		res["owner"] = rig["owner"]
		res["dist"] = (s["origin"] as Vector3).distance_to(hit["position"])
		res["ammo"] = s["ammo"]["id"]
		res["pos"] = hit["position"]
		body_hit.emit(res)
		return false
	var col: Object = hit["collider"]
	var mat: String = col.get_meta("mat", "dirt_berm")
	var thick: float = col.get_meta("thick", 0.05)
	var w := Penetration.world_hit(mat, thick, pen, glance, rng.randf())
	var info := {"pos": hit["position"], "normal": n, "mat": mat, "kind": "stop", "ammo": s["ammo"]["id"]}
	if w["ricochet"] and s["bounces"] < TacticalConfig.MAX_BOUNCES:
		info["kind"] = "ricochet"
		s["vel"] = (dir - 2.0 * dir.dot(n) * n) * speed * w["speed_mult"]
		s["pos"] = hit["position"] + n * 0.01
		s["bounces"] += 1
		impact.emit(info)
		return true
	if w["pass"]:
		info["kind"] = "pass"
		var axis := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized().rotated(dir, rng.randf() * TAU)
		var out_dir := dir.rotated(axis, deg_to_rad(w["deviate_deg"]) * rng.randf())
		s["vel"] = out_dir * speed * w["speed_mult"]
		s["pos"] = hit["position"] + dir * (thick + 0.005)
		s["pen_loss"] += w["pen_loss"]
		s["dmg_mult"] *= w["dmg_mult"]
		impact.emit(info)
		return true
	impact.emit(info)
	return false
