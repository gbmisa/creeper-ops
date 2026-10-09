class_name Crossbow
extends RefCounted
## Operative weapon: a real crossbow. One bolt per shot, a physical projectile with travel time
## and gravity drop that sticks in the terrain for a few seconds, then a reload (can't fire
## meanwhile). Hits use the same target dictionaries as the Pulse Rifle. Numbers: Config.CROSSBOW.

var bolts: Array[Dictionary] = []
var reload := 0.0           # seconds left; 0 = loaded
var report: Callable = Callable()  # (killed: bool) on a hit
static var _mesh_shaft: BoxMesh
static var _mesh_head: BoxMesh


func ready() -> bool:
	return reload <= 0.0


## 0..1 progress while reloading, -1 when loaded.
func reload_progress() -> float:
	return -1.0 if reload <= 0.0 else 1.0 - reload / float(Config.CROSSBOW.reload)


func fire(world: World, from: Vector3, dir: Vector3) -> bool:
	if not ready():
		return false
	reload = Config.CROSSBOW.reload
	var d := dir.normalized()
	var node := _bolt_node()
	world.add_child(node)
	node.look_at_from_position(from, from + d, Vector3.UP)
	bolts.append({ "node": node, "pos": from, "vel": d * float(Config.CROSSBOW.speed), "world": world,
		"stuck": 0.0, "age": 0.0 })
	return true


func update(dt: float) -> void:
	reload = maxf(0.0, reload - dt)
	for i in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[i]
		if not is_instance_valid(b.world) or _step(b, dt):
			if is_instance_valid(b.node):
				(b.node as Node3D).queue_free()
			bolts.remove_at(i)


## Advances one bolt; true when it should be removed.
func _step(b: Dictionary, dt: float) -> bool:
	if b.stuck > 0.0:
		b.stuck -= dt
		return b.stuck <= 0.0
	b.age += dt
	var w: World = b.world
	var left := dt
	while left > 0.0:
		var h := minf(left, 0.02)  # sub-steps: a bolt covers 1.5 m in 0.02 s
		left -= h
		var from: Vector3 = b.pos
		b.vel.y -= float(Config.CROSSBOW.gravity) * h
		var to: Vector3 = from + b.vel * h
		var seg := from.distance_to(to)
		var d: Vector3 = (to - from) / maxf(seg, 0.0001)
		var hit := _target_hit(w, from, d, seg)
		if not hit.is_empty():
			var at: Vector3 = from + d * float(hit.dist)
			hit.t.on_hit.call(float(Config.CROSSBOW.damage) * OperativeUpgrades.mult("firepower"), at)
			if report.is_valid():
				report.call(not hit.t.alive.call())
			w.effects.burst(at, Color("ffe0a0"), 0.5, 0.15)
			return true
		var ground = w.grid.raycast(from, d, seg)
		if ground != null or b.age > float(Config.CROSSBOW.range) / float(Config.CROSSBOW.speed) * 2.0:
			b.pos = ground if ground != null else to
			b.stuck = float(Config.CROSSBOW.stick_time)
			(b.node as Node3D).position = b.pos
			w.effects.burst(b.pos, Color("d8c8a0"), 0.4, 0.15)
			return false
		b.pos = to
	(b.node as Node3D).look_at_from_position(b.pos, b.pos + (b.vel as Vector3).normalized(), Vector3.UP)
	return false


static func _target_hit(w: World, o: Vector3, d: Vector3, seg: float) -> Dictionary:
	var best := {}
	var bt := seg
	for t in w.targets:
		if not t.alive.call():
			continue
		var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
		var dist := RifleFire.ray_sphere(o, d, c, t.radius)
		if dist <= bt:
			bt = dist
			best = { "t": t, "dist": dist }
	return best


static func _bolt_node() -> Node3D:
	var n := Node3D.new()
	var wood := StructureMeshes.mat(Color("6b4428"), 0.0, 0.7)
	var iron := StructureMeshes.mat(Color("8a847c"), 0.8, 0.35)
	var shaft := StructureMeshes.box(n, Vector3(0.026, 0.026, 0.8), wood, Vector3(0, 0, 0.4))
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	StructureMeshes.box(n, Vector3(0.05, 0.05, 0.16), iron, Vector3(0, 0, -0.06))
	StructureMeshes.box(n, Vector3(0.008, 0.1, 0.14), wood, Vector3(0, 0, 0.74))
	return n
