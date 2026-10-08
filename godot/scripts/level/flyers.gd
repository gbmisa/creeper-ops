class_name Flyers
extends RefCounted
## Flying enemies (Stage 19, FlyerDefs). Owned by SporeNests (`nests.flyers`), ticked from its
## update. They ignore terrain and walls, never land, and have no flow field. Only air weapons
## hit them: Beams, castle Flak, the Lance (static helpers below) and the Operative (a
## world target). They are not in SporeNests.enemies(), so units never shoot at them.
## State is plain dicts: `state()` / `load_state()`. Behaviour per type is in FlyerAi.

const FLY_UP := 14.0    # m/s climbing over a cliff
const FLY_DOWN := 8.0
## Every live flyer on every world; statics filter by f.world.
static var live: Array[Dictionary] = []
static var _shadow_mat: StandardMaterial3D

var host                      # SporeNests
var world: World
var list: Array[Dictionary] = []
var time := 0.0
var stats := { "spawned": 0, "killed": 0, "structures": 0, "drops": 0 }


func _init(h) -> void:
	host = h
	world = h.world


func count() -> int:
	return list.size()


func spawn(row: Dictionary, pos: Vector3, opts := {}) -> Dictionary:
	var node := FlyerMeshes.make(row)
	node.position = pos
	world.add_child(node)
	var f := { "row": row, "type": str(row.name), "node": node, "world": world, "hp": float(row.hp),
		"alive": true, "state": "cruise", "cd": float(opts.get("cd", 1.5)), "think": 0.0,
		"phase": randf() * TAU, "target": null, "node_bias": bool(opts.get("node_bias", false)),
		"home": opts.get("home", pos), "breath": 0.0, "aim": Vector3.ZERO,
		"wl": node.get_node_or_null("WingL"), "wr": node.get_node_or_null("WingR"),
		"tend": node.get_node_or_null("Tendrils") }
	var hit := func(dmg: float, _p = null): hurt(f, dmg)
	f["target_def"] = { "node": node, "oy": 0.0, "radius": float(row.size) * 0.9,
		"alive": func(): return f.alive, "on_hit": hit }
	world.add_target(f.target_def)
	f["shadow"] = _make_shadow(float(row.size))
	list.append(f)
	live.append(f)
	stats.spawned += 1
	return f


func _make_shadow(size: float) -> MeshInstance3D:
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.albedo_color = Color(0, 0, 0, 0.4)
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var c := CylinderMesh.new()
	c.top_radius = size * 0.6
	c.bottom_radius = size * 0.6
	c.height = 0.02
	c.radial_segments = 10
	c.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = _shadow_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	return mi


## Damage from any air weapon. Returns true when it killed.
func hurt(f: Dictionary, dmg: float) -> bool:
	if not f.alive:
		return false
	f.hp = float(f.hp) - dmg
	if float(f.hp) > 0.0:
		return false
	kill(f)
	return true


func kill(f: Dictionary) -> void:
	if not f.alive:
		return
	f.alive = false
	stats.killed += 1
	Bus.metric.emit("flyer_killed", { "type": f.type })
	var node := f.node as Node3D
	var p := node.position
	var row: Dictionary = f.row
	if host.stockpile != null and randf() < float(row.loot_p):
		var ground := Vector3(p.x, world.grid.smooth_y(p.x, p.z), p.z)
		Loot.drop(world, ground, float(row.loot), host.stockpile, host.operative)
	world.effects.burst(p, row.color, 1.0 + float(row.size), 0.35)
	Sfx.play("pop", p)
	world.remove_target(f.target_def)
	node.queue_free()
	(f.shadow as Node).queue_free()
	list.erase(f)
	live.erase(f)


func clear() -> void:
	for f in list.duplicate():
		kill_silent(f)


func kill_silent(f: Dictionary) -> void:
	f.alive = false
	world.remove_target(f.target_def)
	(f.node as Node).queue_free()
	(f.shadow as Node).queue_free()
	list.erase(f)
	live.erase(f)


func update(dt: float) -> void:
	time += dt
	FlyerLaunch.tick(host, dt)
	for f in list.duplicate():
		if f.alive:
			FlyerAi.step(self, f, dt)
			_animate(f)
			_shade(f)


# ---- movement ----------------------------------------------------------------------
## Highest ground in the 3x3 cells around a point: flyers glide over cliffs before they reach them.
func ground_max(x: float, z: float) -> float:
	var g := world.grid
	var y := 0.0
	for dx in [-1.0, 0.0, 1.0]:
		for dz in [-1.0, 0.0, 1.0]:
			y = maxf(y, g.smooth_y(x + dx * Config.CELL, z + dz * Config.CELL))
	return y


## Horizontal flight toward `goal` (x, z) at the type's speed; y eases toward `y_goal`
## (default: ground_max + altitude). Returns the horizontal distance left after the step.
func fly(f: Dictionary, goal: Vector3, dt: float, speed_mul := 1.0, y_goal := NAN, vy := 0.0) -> float:
	var node := f.node as Node3D
	var p := node.position
	var d := Vector2(goal.x - p.x, goal.z - p.z)
	var dist := d.length()
	var step := minf(dist, float(f.row.speed) * speed_mul * dt)
	if dist > 0.01:
		p.x += d.x / dist * step
		p.z += d.y / dist * step
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-d.y, d.x), minf(1.0, dt * 5.0))
	var want := y_goal if not is_nan(y_goal) else ground_max(p.x, p.z) + float(f.row.alt)
	var rate := vy if vy > 0.0 else (FLY_UP if want > p.y else FLY_DOWN)
	p.y = move_toward(p.y, want, rate * dt)
	node.position = p
	return maxf(0.0, dist - step)


func _animate(f: Dictionary) -> void:
	var wl = f.wl
	if wl == null:
		return
	var rate := 14.0 if f.type == "Spore Bat" else (7.0 if f.type == "Wyvern" else 3.0)
	var amp := 0.7 if f.type != "Gasbag" else 0.35
	var a := sin(time * rate + float(f.phase)) * amp
	(wl as Node3D).rotation.x = a
	(f.wr as Node3D).rotation.x = -a
	if f.tend != null:
		(f.tend as Node3D).rotation.z = sin(time * 1.6 + float(f.phase)) * 0.12


func _shade(f: Dictionary) -> void:
	var p := (f.node as Node3D).position
	var sh := f.shadow as Node3D
	sh.position = Vector3(p.x, world.grid.smooth_y(p.x, p.z) + 0.06, p.z)
	var k := clampf(1.0 - (p.y - sh.position.y) / 40.0, 0.5, 1.0)
	sh.scale = Vector3(k, 1.0, k)


# ---- air weapons (static: Beam, Flak and the Lance know nothing else about flyers) ------
static func nearest(w: World, from: Vector3, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var bd := reach
	for f in live:
		if f.world != w or not f.alive:
			continue
		var d := ((f.node as Node3D).position).distance_to(from)
		if d <= bd:
			bd = d
			best = f
	return best


## Damage the nearest flyer in range. Returns its position, or null when none.
static func strike(w: World, from: Vector3, reach: float, dmg: float) -> Variant:
	var f := nearest(w, from, reach)
	if f.is_empty():
		return null
	var p := (f.node as Node3D).position
	(f.target_def.on_hit as Callable).call(dmg)
	return p


## Every flyer within `reach` metres (horizontal) of `at`.
static func strike_area(w: World, at: Vector3, reach: float, dmg: float) -> int:
	var n := 0
	for f in live.duplicate():
		if f.world != w or not f.alive:
			continue
		var p := (f.node as Node3D).position
		if Vector2(p.x - at.x, p.z - at.z).length() <= reach:
			(f.target_def.on_hit as Callable).call(dmg)
			n += 1
	return n


# ---- save --------------------------------------------------------------------------
func state() -> Array:
	var rows: Array = []
	for f in list:
		var p := (f.node as Node3D).position
		rows.append({ "type": f.type, "x": p.x, "y": p.y, "z": p.z, "hp": f.hp, "node_bias": f.node_bias })
	return rows


func load_state(rows: Array) -> void:
	clear()
	for row in rows:
		var src: Dictionary = row
		var def := FlyerDefs.named(str(src.type))
		if def.is_empty():
			continue
		var f := spawn(def, Vector3(float(src.x), float(src.y), float(src.z)), { "node_bias": bool(src.node_bias) })
		f.hp = float(src.hp)
