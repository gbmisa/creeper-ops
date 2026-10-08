class_name SprayFx
extends RefCounted
## Null Sprayer visuals: a plume of pale cyan-green mist and droplets from the nozzle out to
## the spray's reach (CPUParticles3D, so it works on the GL compatibility renderer too) and
## fizz bursts (white steam) where droplets really evaporate creeper. All counts are capped
## in Config (SPRAY_MIST, SPRAY_DROPLETS, FIZZ_POOL * FIZZ_PER_BURST).

const NOZZLE := Vector3(0, 0.02, -0.38)  # sprayer model space
const SPREAD_DEG := 17.0

static var _puff_mesh: QuadMesh
static var _drop_mesh: SphereMesh

var mist: CPUParticles3D
var droplets: CPUParticles3D
var _fizz: Array[CPUParticles3D] = []
var _fizz_world: World = null
var _next := 0
var _cool := 0.0


func _init(model: Node3D) -> void:
	_make_meshes()
	var speed: float = Config.SPRAYER.range * 1.45
	mist = _emitter(Config.SPRAY_MIST, 0.72, speed * 0.75, speed, _puff_mesh)
	mist.scale_amount_min = 0.7
	mist.scale_amount_max = 1.3
	mist.scale_amount_curve = _curve(0.15, 0.7, 1.5)
	mist.color_ramp = _ramp(Color(0.7, 1.0, 0.85, 0.0), Color(0.5, 1.0, 0.8, 0.22), Color(0.45, 0.9, 1.0, 0.0))
	droplets = _emitter(Config.SPRAY_DROPLETS, 0.8, speed * 0.8, speed * 1.1, _drop_mesh)
	droplets.gravity = Vector3(0, -7.0, 0)
	droplets.color_ramp = _ramp(Color(0.9, 1.0, 1.0, 1.0), Color(0.7, 1.0, 0.95, 0.9), Color(0.5, 0.9, 1.0, 0.0))
	for e in [mist, droplets]:
		e.position = NOZZLE
		e.rotation.y = 0.0
		model.add_child(e)


func _emitter(n: int, life: float, v0: float, v1: float, mesh: Mesh) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = life
	p.local_coords = false
	p.emitting = false
	p.direction = Vector3(0, 0, -1)
	p.spread = SPREAD_DEG
	p.initial_velocity_min = v0
	p.initial_velocity_max = v1
	p.gravity = Vector3(0, -1.2, 0)
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


static func _make_meshes() -> void:
	if _puff_mesh != null:
		return
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.no_depth_test = false
	_puff_mesh = QuadMesh.new()
	_puff_mesh.size = Vector2(0.6, 0.6)
	_puff_mesh.material = m
	_drop_mesh = SphereMesh.new()
	_drop_mesh.radius = 0.02
	_drop_mesh.height = 0.04
	_drop_mesh.radial_segments = 8
	_drop_mesh.rings = 4
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.vertex_color_use_as_albedo = true
	_drop_mesh.material = dm


static func _ramp(a: Color, b: Color, c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, c)
	g.add_point(0.25, b)
	return g


static func _curve(a: float, b: float, c: float) -> Curve:
	var cv := Curve.new()
	cv.add_point(Vector2(0, a))
	cv.add_point(Vector2(0.5, b))
	cv.add_point(Vector2(1, c))
	return cv


func set_active(on: bool) -> void:
	mist.emitting = on
	droplets.emitting = on


## Particle slots this effect can ever have alive (smoke test checks the cap).
static func budget() -> int:
	return Config.SPRAY_MIST + Config.SPRAY_DROPLETS + Config.FIZZ_POOL * Config.FIZZ_PER_BURST


func fizz_nodes() -> int:
	return _fizz.size()


## White steam where creeper really evaporated. `cells` are the cells that lost depth this frame.
func fizz(world: World, cells: Array[Vector2i], dt: float) -> void:
	_cool -= dt
	if cells.is_empty() or _cool > 0.0:
		return
	_cool = Config.FIZZ_INTERVAL
	if _fizz_world != world:
		_clear_pool()
		_fizz_world = world
	if _fizz.is_empty():
		for i in Config.FIZZ_POOL:
			var f := _emitter(Config.FIZZ_PER_BURST, 0.7, 1.2, 3.2, _puff_mesh)
			f.one_shot = true
			f.explosiveness = 0.9
			f.direction = Vector3.UP
			f.spread = 55.0
			f.gravity = Vector3(0, 0.8, 0)
			f.scale_amount_min = 0.35
			f.scale_amount_max = 0.7
			f.scale_amount_curve = _curve(0.5, 1.0, 1.8)
			f.color_ramp = _ramp(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(0.9, 0.97, 1, 0.0))
			world.add_child(f)
			_fizz.append(f)
	var c: Vector2i = cells[randi() % cells.size()]
	var g := world.grid
	var e := _fizz[_next]
	_next = (_next + 1) % _fizz.size()
	e.position = g.cell_center(c.x, c.y) + Vector3(0, 0, 0)
	e.position.y = g.ground_y(e.position.x, e.position.z) + world.creeper.depth_at(c.x, c.y) * Config.LEVEL_H + 0.15
	e.emitting = true
	e.restart()
	Sfx.play("fizz")


func _clear_pool() -> void:
	for f in _fizz:
		if is_instance_valid(f):
			f.queue_free()
	_fizz.clear()
