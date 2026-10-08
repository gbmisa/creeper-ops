class_name RocketLauncher
extends RefCounted
## Operative weapon 3: a slow rocket that bursts on ground, creeper or a target, gutting the
## creeper in a radius at any depth (a hand-held mortar) and splashing targets. Small
## magazine that reloads on its own, so it's for problem pools, not for mowing the flood.

var rockets: Array[Dictionary] = []
var loaded: int = Config.ROCKET.mag
var _reload := 0.0
var _cap := Config.ROCKET.mag
static var _mesh: SphereMesh


func mag_size() -> int:
	return Config.ROCKET.mag + OperativeUpgrades.level("firepower")


func update(dt: float, world: World) -> void:
	var cap := mag_size()
	if cap > _cap:
		loaded += cap - _cap  # a bigger magazine arrives loaded
	_cap = cap
	if loaded > cap:
		loaded = cap
	if loaded < cap:
		_reload += dt
		if _reload >= Config.ROCKET.reload:
			_reload = 0.0
			loaded += 1
	for i in range(rockets.size() - 1, -1, -1):
		var r: Dictionary = rockets[i]
		if r.world != world or _step(r, dt):
			(r.node as Node3D).queue_free()
			rockets.remove_at(i)


func fire(world: World, from: Vector3, dir: Vector3) -> bool:
	if loaded <= 0:
		return false
	loaded -= 1
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 0.18
		_mesh.height = 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	mi.material_override = Effects.glow_mat(Color("ffb347"))
	mi.position = from
	world.add_child(mi)
	rockets.append({ "node": mi, "pos": from, "dir": dir.normalized(), "dist": 0.0, "world": world })
	Sfx.play("mortar")
	return true


## Advances one rocket; true when it has exploded or expired.
func _step(r: Dictionary, dt: float) -> bool:
	var w: World = r.world
	var move: float = Config.ROCKET.speed * dt
	var prev: Vector3 = r.pos
	while move > 0.0:
		var s := minf(move, 0.4)
		move -= s
		r.pos += r.dir * s
		r.dist += s
		var p: Vector3 = r.pos
		if r.dist > Config.ROCKET.range:
			return true
		for t in w.targets:
			if t.alive.call():
				var c: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
				if p.distance_to(c) <= t.radius:
					_explode(w, p)
					return true
		var surf := w.grid.smooth_y(p.x, p.z) + w.creeper.depth_world(p) * Config.LEVEL_H
		var size := w.grid.world_size()
		if p.y <= surf or p.x < 0.0 or p.z < 0.0 or p.x > size.x or p.z > size.y:
			_explode(w, p)
			return true
	(r.node as Node3D).position = r.pos
	w.effects.beam(prev, r.pos, Color("ffcc66"), 0.25, 0.05)
	return false


func _explode(w: World, p: Vector3) -> void:
	var c := w.grid.world_to_cell(p.x, p.z)
	var blast: float = Config.ROCKET.blast
	w.creeper.remove_radius(c.x, c.y, blast, Config.ROCKET.power)
	var reach := blast * Config.CELL
	for t in w.targets:
		if t.alive.call():
			var tc: Vector3 = (t.node as Node3D).global_position + Vector3(0, t.get("oy", 0.0), 0)
			var d: float = tc.distance_to(p) - t.radius
			if d <= reach:
				t.on_hit.call(Config.ROCKET.damage * (1.0 - 0.5 * maxf(0.0, d) / reach), p)
	w.effects.burst(p, Color("ffaa33"), reach * 0.9, 0.45)
	Sfx.play("boom", p)
