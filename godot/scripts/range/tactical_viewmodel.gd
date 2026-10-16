class_name TacticalViewmodel
extends Node3D
## The held gun under the camera: hip / ADS poses (per-weapon ads_pos / hip_pos from WeaponDefs), recoil
## kick, mouse sway, walk bob, and the glb clips timed to fire / cycle / reload / fix.
## Recoil (FB-I, Tarkov): the gun turns by the barrel angle the view did not take, about the row's pivot, and
## kicks back along the bore by the position process (recoil_xform); applied on top of the smoothed pose.

var weapons: PlayerWeapons
var player: TacticalPlayer
var model: Node3D
var anim: AnimationPlayer
var flash: MuzzleFlash
var arms: FpArms
var rig: AttachmentRig
var _gun: Gun
var half_len := 0.3
var _def := {}
var _base_pos := Vector3.ZERO  # the smoothed pose without recoil (what model.position/rotation used to hold)
var _base_rot := Vector3.ZERO
var _bob_t := 0.0
var _check := 0.0
var _cycle_clip := ""
var bolt: BoltCycle  # procedural bolt-action cycle (Mosin), null for other guns
var _posed := false  # held gun uses hand-posed arms (WeaponDefs arms_pose) instead of the IK arms
const HIP_BUTT := 0.1  # how far the butt sits behind the eye at the hip
const HIP_MIN_Z := 0.3  # pistols: held out at least this far
const HIP_YAW := 2.5
var _ads := Transform3D.IDENTITY  # FB-H: gun pose at full ADS (AdsPose), valid when _ads_ok
var _ads_euler := Vector3.ZERO
var _ads_ok := false


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p
	w.switched.connect(_on_switched)
	w.shot.connect(_on_shot)
	w.action.connect(_on_action)
	arms = FpArms.new()
	add_child(arms)
	ViewmodelClip.apply(arms, "Arms")


func _on_switched(g: Gun) -> void:
	if model != null:
		model.queue_free()
		model = null
	if g == null:  # hands empty (gun dropped or put away)
		return
	_gun = g
	_def = g.eff_def()
	model = Node3D.new()
	_base_pos = Vector3.ZERO
	_base_rot = Vector3.ZERO
	add_child(model)
	var glb := (load("res://assets/models/guns/%s.glb" % _def["model"]) as PackedScene).instantiate()
	model.add_child(glb)
	if _def.get("flip", false):
		glb.rotation.y = PI  # model exported muzzle toward +Z
	anim = WeaponDefs.anim_of(glb)
	for n in anim.get_animation_list():
		anim.get_animation(n).loop_mode = Animation.LOOP_NONE
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	if tune:
		mi.material_override = _metal()
	half_len = mi.get_aabb().size.z * 0.5
	flash = MuzzleFlash.new(model, Vector3(0, 0.01, -half_len - 0.03))
	_cycle_clip = "FireWBullet" if anim.has_animation("FireWBullet") else ""
	bolt = BoltCycle.make(glb, _def)
	arms.bolt = bolt
	rig = AttachmentRig.new()
	model.add_child(rig)
	rig.build(g, half_len)
	_clip_and_aim()
	arms.set_gun(_def)
	_posed = _add_posed_arms(String(_def.get("arms_pose", "")))
	arms.visible = not _posed


## Arms posed by hand in Blender for this gun (gun-model space), in place of the IK arms. False if none exist.
func _add_posed_arms(id: String) -> bool:
	var path := "res://assets/models/operative/%s.glb" % id
	if id == "" or not ResourceLoader.exists(path):
		return false
	var posed := (load(path) as PackedScene).instantiate()
	model.add_child(posed)
	for mi in posed.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ViewmodelClip.apply(posed)
	return true


## After the gun or its fit changes: z-clip the new materials and solve the ADS pose for the sight now fitted.
func _clip_and_aim() -> void:
	ViewmodelClip.apply(model.get_child(0))
	ViewmodelClip.apply(rig)
	var sid: String = _gun.fit.get("sight", "")
	_ads_ok = not AdsPose.points(_def, sid, half_len).is_empty()
	if not _ads_ok:
		push_warning("%s has no sight points (mounts.json): ADS uses ads_pos" % _def["id"])
		return
	_ads = AttachmentMounts.ads_pose(_def, sid, half_len)
	_ads_euler = _ads.basis.get_euler()


func _on_shot(res: Dictionary, g: Gun) -> void:
	if not res["fired"]:
		return
	if g.stat("flash") > 0.5:
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
			arms.reload(secs)
		"fix":
			_play("Slide" if anim.has_animation("Slide") else "Reload", secs)
		"cycle":
			if _cycle_clip != "" and not anim.is_playing():
				_play(_cycle_clip, secs / 0.65, 0.35)
			elif bolt != null:
				bolt.start(secs)
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
	if rig.stale():
		_def = _gun.eff_def()
		rig.build(_gun, half_len)
		_clip_and_aim()
	rig.update_beam()
	var a := smoothstep(0.0, 1.0, weapons.ads_amt)
	var pos := base_pos(_def, half_len, a)
	var rot := Vector3(0, deg_to_rad(HIP_YAW) * (1.0 - a), 0)
	if _ads_ok:  # FB-H: hip pose to the sight-aligned pose, rotation (pitch, yaw, no roll) scaled by a
		pos = base_pos(_def, half_len, 0.0).lerp(_ads.origin, a)
		rot += _ads_euler * a
	var speed := player.horizontal_speed() if player.is_on_floor() else 0.0
	_bob_t += delta * speed * 2.0
	var bob := speed * 0.0035 * (1.0 - a * 0.85)
	pos += Vector3(sin(_bob_t) * bob, absf(sin(_bob_t)) * bob * 0.8, 0)
	if bolt != null:
		bolt.update(delta)
		rot.z += bolt.roll()
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
	_base_pos = _base_pos.lerp(pos, minf(1.0, delta * 20.0))
	_base_rot = _base_rot.lerp(rot, minf(1.0, delta * 20.0))
	model.position = _base_pos
	model.rotation = _base_rot
	var rx := recoil_xform(weapons.recoil)
	if rx != Transform3D.IDENTITY:
		model.transform = model.transform * rx
	if not _posed:
		arms.update(model, delta)


## The recoil's turn and kick back in the gun's own frame (identity at rest, so the FB-H poses are untouched).
static func recoil_xform(rm: RecoilModel) -> Transform3D:
	var w := rm.weapon_rot()
	var rel := rm.barrel - rm.view_offset()   # the barrel angle the view did not take (deg)
	var back := rm.weapon_pos().y
	if rel.length_squared() < 1e-12 and absf(w.y) < 1e-6 and absf(back) < 1e-7:
		return Transform3D.IDENTITY
	var piv: Vector3 = rm.row["pivot"]
	var p := Vector3(piv.x, piv.z, piv.y)   # Tarkov bone axes: y runs back along the bore -> gun-local z
	var b := Basis.from_euler(Vector3(deg_to_rad(rel.x), deg_to_rad(rel.y), deg_to_rad(w.y)))
	return Transform3D(Basis(), Vector3(0, 0, back) + p - b * p) * Transform3D(b, Vector3.ZERO)


## Gun model position under the camera, hip (a = 0) to ADS (a = 1). The butt is shouldered at the hip; when
## aiming the eye sits `ads_eye` ahead of the butt plate (cheek weld, P4), so the stock is in view — ADS_NEAR is
## small enough not to clip it.
static func base_pos(def: Dictionary, half: float, a: float) -> Vector3:
	var hip: Vector3 = def["hip_pos"]
	hip.z = -maxf(half - HIP_BUTT, HIP_MIN_Z)  # butt tucked behind the eye, gun parallel to the view
	var ads: Vector3 = def["ads_pos"]
	ads.z = -(half - ads_eye(def))
	return hip.lerp(ads, a)


## Eye-to-butt-plate distance at full ADS: `eye` where the rear sight is closer to the butt than the cheek weld
## (the eye must stay behind it), else `butt` (0.30 m for stocked guns, P4).
static func ads_eye(def: Dictionary) -> float:
	return float(def.get("eye", def["butt"]))


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
