class_name Effects
extends Node3D
## Short-lived visual effects: beams (shot traces), bursts (impacts), lobs (arcing shells
## with an on_arrive callback). Lobs are gameplay-relevant (mortar damage lands on arrival),
## so they tick in update() with sim time, not render time.

var _items: Array[Dictionary] = []
static var _box: BoxMesh
static var _sphere: SphereMesh
var _flash: OmniLight3D       # one reused light for muzzle flashes / explosions
var _flash_e := 0.0


func _ready() -> void:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE
		_sphere = SphereMesh.new()
		_sphere.radius = 0.5
		_sphere.height = 1.0
		_sphere.radial_segments = 16
		_sphere.rings = 8
	_flash = OmniLight3D.new()
	_flash.omni_range = 18.0
	_flash.light_energy = 0.0
	_flash.shadow_enabled = false
	add_child(_flash)


static func glow_mat(color: Color, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = false
	return m


func beam(a: Vector3, b: Vector3, color: Color, life := 0.08, width := 0.06) -> void:
	var len := a.distance_to(b)
	if len < 0.01:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = _box
	mi.material_override = glow_mat(color, 0.9)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	mi.scale = Vector3(width, width, len)
	_items.append({ "node": mi, "t": 0.0, "life": life, "kind": "beam" })


## A puff of grey smoke that swells and fades (normal blending, so it shows against bright ground).
func smoke(p: Vector3, size := 1.0, life := 1.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.42, 0.4, 0.4, 0.6)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.scale = Vector3.ONE * size * 0.3
	add_child(mi)
	_items.append({ "node": mi, "t": 0.0, "life": life, "kind": "smoke", "size": size })


## A bright streak that flies from a to b at `speed` (a bolt or tracer round).
func tracer(a: Vector3, b: Vector3, color: Color, speed := 220.0, length := 3.0, width := 0.05) -> void:
	var total := a.distance_to(b)
	if total < 0.05:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = _box
	mi.material_override = glow_mat(color, 0.95)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.look_at_from_position(a, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	mi.scale = Vector3(width, width, 0.01)
	_items.append({ "node": mi, "t": 0.0, "life": maxf(total / speed, 0.05), "kind": "tracer",
		"a": a, "dir": (b - a) / total, "total": total, "len": length })


func burst(p: Vector3, color: Color, size := 1.5, life := 0.35) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.material_override = glow_mat(color, 0.8)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.scale = Vector3.ONE * 0.1
	add_child(mi)
	_items.append({ "node": mi, "t": 0.0, "life": life, "kind": "burst", "size": size })


## Brief bright point light (muzzle flashes, explosions). One light is reused; the
## newest call wins while the old one is still decaying.
func flash_light(p: Vector3, color: Color, energy := 6.0) -> void:
	if _flash == null:
		return
	_flash.position = p
	_flash.light_color = color
	_flash_e = energy


## Gravity debris chunks for structure deaths. Count is capped by Config.FX_MAX_DEBRIS.
func debris(p: Vector3, color: Color, n := 8, spread := 6.0) -> void:
	var live := 0
	for it in _items:
		if it.kind == "debris":
			live += 1
	n = mini(n, Config.FX_MAX_DEBRIS - live)
	if n <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(p.x * 13.0 + p.z * 7.0 + p.y * 3.0)) & 0x7fffffff
	for i in n:
		var mi := MeshInstance3D.new()
		mi.mesh = _box
		var m := StandardMaterial3D.new()
		m.albedo_color = color * rng.randf_range(0.7, 1.2)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := rng.randf() * TAU
		var sp := rng.randf_range(2.0, spread)
		mi.position = p
		add_child(mi)
		_items.append({ "node": mi, "t": 0.0, "life": rng.randf_range(0.7, 1.4), "kind": "debris",
			"vel": Vector3(cos(a) * sp, rng.randf_range(4.0, 9.0), sin(a) * sp),
			"size": rng.randf_range(0.15, 0.45) })


## A dust puff: grey, normal blending, shows against bright ground.
func dust(p: Vector3, size := 1.5) -> void:
	smoke(p, size, 1.4)


## Arcing projectile. opts: color, time, arc (apex height), size, on_arrive (Callable).
## Returns the item dict so callers (Beams vs spores) can cancel it via item.dead = true.
func lob(a: Vector3, b: Vector3, opts: Dictionary) -> Dictionary:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere
	mi.material_override = glow_mat(opts.get("color", Color.ORANGE))
	mi.scale = Vector3.ONE * opts.get("size", 0.45)
	mi.position = a
	add_child(mi)
	var it := { "node": mi, "t": 0.0, "life": opts.get("time", 1.0), "kind": "lob", "a": a, "b": b,
		"arc": opts.get("arc", 8.0), "cb": opts.get("on_arrive", Callable()), "dead": false, "pos": a,
		"foe": bool(opts.get("foe", false)), "mortar_shell": bool(opts.get("mortar_shell", false)) }
	_items.append(it)
	return it


func update(dt: float) -> void:
	# Perf cap (P6): lobs are gameplay-relevant and are never culled, only other fx.
	var over := _items.size() - Config.FX_MAX_ITEMS
	while over > 0:
		var idx := -1
		for i in range(_items.size()):
			if _items[i].kind != "lob":
				idx = i
				break
		if idx < 0:
			break
		(_items[idx].node as Node3D).queue_free()
		_items.remove_at(idx)
		over -= 1
	if _flash_e > 0.0 and _flash != null:
		_flash_e = maxf(0.0, _flash_e - dt * 40.0)
		_flash.light_energy = _flash_e
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		it.t += dt
		var k: float = clampf(it.t / it.life, 0.0, 1.0)
		var node: MeshInstance3D = it.node
		match it.kind:
			"beam":
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.9 * (1.0 - k)
			"tracer":
				var head: float = k * it.total
				var tail := maxf(0.0, head - float(it.len))
				node.position = it.a + it.dir * ((head + tail) * 0.5)
				node.scale.z = maxf(head - tail, 0.01)
			"smoke":
				node.scale = Vector3.ONE * lerpf(it.size * 0.3, it.size, sqrt(k))
				node.position.y += dt * 0.6
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.6 * (1.0 - k)
			"burst":
				node.scale = Vector3.ONE * lerpf(0.1, it.size, sqrt(k))
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.8 * (1.0 - k)
			"debris":
				it.vel.y -= 22.0 * dt
				node.position += it.vel * dt
				node.scale = Vector3.ONE * float(it.size) * (1.0 - k * 0.5)
				(node.material_override as StandardMaterial3D).albedo_color.a = 1.0 - k
			"lob":
				var p: Vector3 = it.a.lerp(it.b, k)
				p.y += sin(k * PI) * it.arc
				node.position = p
				it.pos = p
				if k >= 1.0 and not it.dead and it.cb.is_valid():
					it.cb.call()
		if k >= 1.0 or it.get("dead", false):
			node.queue_free()
			_items.remove_at(i)


## Live lobs (spore volleys are lobs; Beams look for them here).
func lobs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in _items:
		if it.kind == "lob" and not it.dead:
			out.append(it)
	return out
