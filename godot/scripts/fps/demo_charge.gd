class_name DemoCharge
extends RefCounted
## Thrown demolition charge: a fixed loft so a level throw travels about `range` metres,
## sticks to the ground, then bursts. The Deep Core target is skipped (cave_hazards marks
## it with deep_core).

var spec: Dictionary
var charges: Array[Dictionary] = []
var _ball: SphereMesh


func _init(d: Dictionary) -> void:
	spec = d


func launch(world: World, from: Vector3, dir: Vector3) -> void:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() < 0.04:
		flat = Vector3(0.0, 0.0, -1.0)
	flat = flat.normalized()
	var spd := float(spec.speed)
	var loft := float(spec.loft)
	var vel := flat * cos(loft) * spd + Vector3.UP * sin(loft) * spd
	charges.append(_make(world, from, vel, false))
	Sfx.play("mortar", from)


func plant(world: World, pos: Vector3) -> void:
	charges.append(_make(world, pos, Vector3.ZERO, true))


func update(dt: float) -> void:
	for i in range(charges.size() - 1, -1, -1):
		var c: Dictionary = charges[i]
		var w: World = c.world
		if not c.stuck:
			var vel: Vector3 = c.vel
			vel.y -= Config.GRAVITY * dt
			c.vel = vel
			var step: Vector3 = vel * dt
			c.pos = (c.pos as Vector3) + step
			c.travel = float(c.travel) + step.length()
			var p: Vector3 = c.pos
			var gy := w.grid.smooth_y(p.x, p.z)
			if p.y <= gy or float(c.travel) > float(spec.range) * 1.4:
				p.y = gy
				c.pos = p
				c.stuck = true
				c.fuse = float(spec.fuse)
		else:
			c.fuse = float(c.fuse) - dt
			if float(c.fuse) <= 0.0:
				_explode(w, c.pos)
				(c.node as Node3D).queue_free()
				charges.remove_at(i)
				continue
		(c.node as Node3D).position = c.pos


func clear() -> void:
	for c in charges:
		if is_instance_valid(c.node):
			(c.node as Node3D).queue_free()
	charges.clear()


func _make(world: World, pos: Vector3, vel: Vector3, stuck: bool) -> Dictionary:
	if _ball == null:
		_ball = SphereMesh.new()
		_ball.radius = 0.16
		_ball.height = 0.32
	var mi := MeshInstance3D.new()
	mi.mesh = _ball
	mi.material_override = Effects.glow_mat(Color("ff8844"))
	mi.position = pos
	world.add_child(mi)
	return { "world": world, "pos": pos, "vel": vel, "stuck": stuck, "fuse": float(spec.fuse),
		"travel": 0.0, "node": mi }


func _explode(w: World, pos: Vector3) -> void:
	var dmg := float(spec.damage)
	var reach := float(spec.radius) * Config.CELL
	for t in w.targets:
		if not t.alive.call() or t.get("deep_core", false):
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		if c.distance_to(pos) - float(t.radius) <= reach:
			t.on_hit.call(dmg, pos)
	w.effects.burst(pos, Color("ff8844"), reach, 0.45)
	Sfx.play("boom", pos)
