class_name TacticalViewmodel
extends Node3D
## The held gun under the camera: hip / ADS poses (per-weapon ads_pos / hip_pos from WeaponDefs), recoil
## kick, mouse sway, walk bob, and the glb clips timed to fire / cycle / reload / fix.

var weapons: PlayerWeapons
var player: TacticalPlayer
var model: Node3D
var anim: AnimationPlayer
var flash: MuzzleFlash
var half_len := 0.3
var _def := {}
var _kick := 0.0
var _kick_v := 0.0
var _sway := Vector2.ZERO
var _bob_t := 0.0
var _check := 0.0
var _cycle_clip := ""
const HIP_BUTT := 0.2
const HIP_YAW := 2.5


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	w.switched.connect(_on_switched)
	w.shot.connect(_on_shot)
	w.action.connect(_on_action)


func _on_switched(g: Gun) -> void:
	if model != null:
		model.queue_free()
	_def = g.def
	model = Node3D.new()
	add_child(model)
	var glb := (load("res://assets/models/guns/%s.glb" % _def["model"]) as PackedScene).instantiate()
	model.add_child(glb)
	anim = glb.find_children("*", "AnimationPlayer", true, false)[0]
	for n in anim.get_animation_list():
		anim.get_animation(n).loop_mode = Animation.LOOP_NONE
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	if tune:
		mi.material_override = _metal()
	half_len = mi.get_aabb().size.z * 0.5
	flash = MuzzleFlash.new(model, Vector3(0, 0.01, -half_len - 0.03))
	_cycle_clip = "FireWBullet" if anim.has_animation("FireWBullet") else ""


func _on_shot(res: Dictionary, g: Gun) -> void:
	if not res["fired"]:
		return
	_kick_v += 0.4 + g.def["up"] * 0.2
	flash.flash(Color(1.0, 0.8, 0.45), 0.07 + 0.02 * float(g.def["kg"]), 0.05, 2.0)
	if _cycle_clip != "":
		var clip := "FireWOBullet" if res["last"] else "FireWBullet"
		_play(clip, 0.2 + g.def["cycle"] if g.def["cycle"] > 0.0 else maxf(0.18, 60.0 / g.def["rpm"]))
	else:
		_play("Fire", clampf(60.0 / g.def["rpm"], 0.06, 0.4))


func _on_action(kind: String, secs: float) -> void:
	match kind:
		"reload":
			_play("Reload", secs)
		"fix":
			_play("Slide" if anim.has_animation("Slide") else "Reload", secs)
		"cycle":
			if _cycle_clip != "" and not anim.is_playing():
				_play(_cycle_clip, secs / 0.65, 0.35)
		"check":
			_check = secs


func _play(clip: String, secs: float, from := 0.0) -> void:
	if not anim.has_animation(clip):
		return
	var len := anim.get_animation(clip).length
	anim.play(clip, 0.0, len * (1.0 - from) / maxf(secs, 0.05))
	if from > 0.0:
		anim.seek(len * from, true)


func _process(delta: float) -> void:
	if model == null:
		return
	model.visible = not weapons.scoped()
	flash.update(delta)
	var a := smoothstep(0.0, 1.0, weapons.ads_amt)
	var hip: Vector3 = _def["hip_pos"]
	hip.z = -(half_len + HIP_BUTT)  # butt stays out of the lens, gun parallel to the view
	var pos: Vector3 = hip.lerp(_def["ads_pos"], a)
	var rot := Vector3(0, deg_to_rad(HIP_YAW) * (1.0 - a), 0)
	var md := player.input.mouse_delta
	_sway = (_sway - md * 0.00035 * (1.0 - a * 0.6)).limit_length(0.05).lerp(Vector2.ZERO, minf(1.0, delta * 8.0))
	pos += Vector3(_sway.x, -_sway.y, 0)
	var speed := player.horizontal_speed() if player.is_on_floor() else 0.0
	_bob_t += delta * speed * 2.0
	var bob := speed * 0.0035 * (1.0 - a * 0.85)
	pos += Vector3(sin(_bob_t) * bob, absf(sin(_bob_t)) * bob * 0.8, 0)
	_kick_v -= (_kick * 400.0 + _kick_v * 20.0) * delta
	_kick += _kick_v * delta
	pos.z += _kick * (1.0 - a * 0.5)
	rot.x += _kick * 6.0 * (1.0 - a * 0.5)
	var d := weapons.draw_t / PlayerWeapons.DRAW_TIME
	pos.y -= d * 0.3
	rot.x -= d * 0.6
	if player.sprinting:
		pos += Vector3(0.04, -0.1, 0.02)
		rot += Vector3(-0.35, 0.5, 0.0)
	if _check > 0.0:
		_check -= delta
		pos += Vector3(-0.08, 0.02, 0.05)
		rot += Vector3(0.15, 0.3, 1.1)
	model.position = model.position.lerp(pos, minf(1.0, delta * 20.0))
	model.rotation = model.rotation.lerp(rot, minf(1.0, delta * 20.0))


static var tune := false
static var _metal_mat: StandardMaterial3D


static func _metal() -> StandardMaterial3D:
	if _metal_mat == null:
		_metal_mat = StandardMaterial3D.new()
		_metal_mat.albedo_color = Color(0.13, 0.13, 0.15)
		_metal_mat.metallic = 0.5
		_metal_mat.roughness = 0.5
		if tune:  # flat magenta so screenshots can be measured (--tune)
			_metal_mat.albedo_color = Color(1, 0, 1)
			_metal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _metal_mat
