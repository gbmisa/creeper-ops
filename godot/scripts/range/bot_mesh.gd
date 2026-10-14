class_name BotMesh
extends Node3D
## An enemy soldier: the character body.glb (BotBody) dyed per kind with a red armband, holding its gun in both
## hands. Feet at y = 0, faces -Z. `walk(speed)` picks and paces the locomotion clip, `aim` pitches the upper body.

const UNIFORM := Color(0.2, 0.32, 0.2)
const LOW_PITCH := 0.35

var body: BotBody
var muzzle: Node3D
var gun: Node3D
var anim: AnimationPlayer
var fire_clip := ""
var scope_glint: MeshInstance3D
var pitch := -LOW_PITCH


func _init(def := {}) -> void:
	var uniform: Color = def.get("uniform", UNIFORM)
	var gun_def: Dictionary = WeaponDefs.of(def["gun"]) if def.has("gun") else WeaponDefs.of("ak47")
	body = BotBody.new(uniform.lightened(0.25))
	add_child(body)
	gun = Node3D.new()
	var glb := (load("res://assets/models/guns/%s.glb" % gun_def["model"]) as PackedScene).instantiate()
	if gun_def.get("flip", false):
		glb.rotation.y = PI  # model exported muzzle toward +Z
	gun.add_child(glb)
	anim = WeaponDefs.anim_of(glb)
	for n in anim.get_animation_list():
		if n.begins_with("Fire") and fire_clip == "":
			fire_clip = n
	if fire_clip != "":
		anim.get_animation(fire_clip).loop_mode = Animation.LOOP_NONE
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.01, -mi.get_aabb().size.z * 0.5)
	body.hold(gun, gun_def, mi.get_aabb().size.z * 0.5)
	gun.add_child(muzzle)
	scope_glint = MeshInstance3D.new()
	var gs := SphereMesh.new()
	gs.radius = 0.09
	gs.height = 0.18
	scope_glint.mesh = gs
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(1.0, 0.95, 0.7)
	gm.emission_enabled = true
	gm.emission = Color(1.0, 0.95, 0.7)
	gm.emission_energy_multiplier = 4.0
	scope_glint.material_override = gm
	scope_glint.position = Vector3(0, 0.08, -0.15)
	scope_glint.visible = false
	gun.add_child(scope_glint)


## Rifle pitch: level while engaging, lowered otherwise.
func aim(delta: float, engaged: bool) -> void:
	pitch = move_toward(pitch, 0.0 if engaged else -LOW_PITCH, delta * 3.0)


func glint(on: bool) -> void:
	scope_glint.visible = on


func fire() -> void:
	if fire_clip == "":
		return
	anim.play(fire_clip)
	anim.seek(0.0, true)


func die() -> void:
	body.die()


func walk(delta: float, speed: float) -> void:
	body.update(delta, speed, pitch, gun)
