class_name TempestFx
extends Node
## Tempest effects: an electric-blue tracer, impact sparks, a zap, and a chain-lightning arc that really kills bots
## within SecretArms.CHAIN_R of the impact. Follows PlayerWeapons.shot and Ballistics.impact / body_hit.

const BLUE := Color(0.35, 0.7, 1.0)

var weapons: PlayerWeapons
var bots_fn: Callable = func(): return []  # returns the live ScavBots
var _mat: StandardMaterial3D
var _zap: AudioStreamWAV
var _zap_p: AudioStreamPlayer


func _init() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = BLUE
	_mat.emission_enabled = true
	_mat.emission = BLUE
	_mat.emission_energy_multiplier = 3.0
	_zap = make_zap()
	_zap_p = AudioStreamPlayer.new()
	_zap_p.stream = _zap
	_zap_p.volume_db = -6.0
	add_child(_zap_p)


func setup(w: PlayerWeapons, bal: Ballistics, bots_getter: Callable) -> void:
	weapons = w
	bots_fn = bots_getter
	w.shot.connect(_on_shot)
	bal.impact.connect(func(i): _on_hit(i["pos"], i["ammo"]))
	bal.body_hit.connect(func(i): _on_hit(i["pos"], i["ammo"], i.get("owner")))


func _on_shot(res: Dictionary, g: Gun) -> void:
	if g.id != SecretArms.TEMPEST or not res["fired"]:
		return
	var cam := weapons.player.cam
	var from := cam.global_position
	var fwd := -cam.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * 200.0, TacticalConfig.BULLET_MASK)
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	var to: Vector3 = hit["position"] if not hit.is_empty() else from + fwd * 200.0
	var start := from + cam.global_basis * Vector3(0.1, -0.09, -0.55)
	beam(start, to, 0.012, 0.09)
	if _zap_p.is_inside_tree():
		_zap_p.play()


func _on_hit(pos: Vector3, ammo: String, hit_owner: Object = null) -> void:
	if ammo != SecretArms.CELL:
		return
	sparks(pos)
	chain(pos, hit_owner)


## Kills every living bot within CHAIN_R of `pos` (except the one already hit) and draws an arc to each. Returns the count.
func chain(pos: Vector3, skip: Object = null) -> int:
	var n := 0
	for b in bots_fn.call():
		if not is_instance_valid(b) or b == skip or b.body.dead:
			continue
		var c: Vector3 = b.global_position + Vector3(0, 1.2, 0)
		if c.distance_to(pos) > SecretArms.CHAIN_R:
			continue
		b.body.hit("thorax", SecretArms.CHAIN_DMG)
		b.on_hit({})
		arc(pos, c)
		n += 1
	return n


func arc(a: Vector3, b: Vector3) -> void:
	var prev := a
	for i in range(1, 6):
		var p := a.lerp(b, i / 5.0)
		if i < 5:
			p += Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		beam(prev, p, 0.015, 0.2)
		prev = p


## A thin glowing bar from a to b that fades out.
func beam(a: Vector3, b: Vector3, width: float, life: float) -> void:
	var len := a.distance_to(b)
	if len < 0.01 or not is_inside_tree():
		return
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, width, len)
	m.mesh = box
	var mat := _mat.duplicate() as StandardMaterial3D
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(m)
	m.global_position = (a + b) * 0.5
	var up := Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT
	m.look_at(b, up)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tw := m.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, life)
	tw.tween_callback(m.queue_free)


func sparks(pos: Vector3) -> void:
	if not is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.35
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	var s := SphereMesh.new()
	s.radius = 0.012
	s.height = 0.024
	p.mesh = s
	p.material_override = _mat
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


## Short electric zap: a falling tone plus a noise burst (no sample file needed).
static func make_zap() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.18)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 22.0)
		var tone := sin(TAU * (2400.0 - 9000.0 * t) * t)
		var v := (tone * 0.5 + rng.randf_range(-1.0, 1.0) * 0.5) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w
