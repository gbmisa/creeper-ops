class_name BotMesh
extends Node3D
## Simple soldier from boxes / capsules: olive uniform, dark vest, red armband and a rifle so the silhouette
## reads at range and differs from the tan dummies. Feet at y = 0, faces -Z. Legs swing with `walk(speed)`.

const UNIFORM := Color(0.2, 0.32, 0.2)
const VEST := Color(0.1, 0.11, 0.12)
const LOW_PITCH := 0.35
const SKIN := Color(0.7, 0.5, 0.4)

var legs: Array[Node3D] = []
var muzzle: Node3D
var gun: Node3D
var anim: AnimationPlayer
var fire_clip := ""
var scope_glint: MeshInstance3D
var _t := 0.0


func _init(def := {}) -> void:
	var uniform: Color = def.get("uniform", UNIFORM)
	var gun_id: String = WeaponDefs.of(def["gun"])["model"] if def.has("gun") else "ak47"
	_part(Vector3(0, 1.3, 0), Vector3(0.38, 0.5, 0.22), uniform)
	_part(Vector3(0, 1.32, 0.02), Vector3(0.4, 0.34, 0.26), VEST)
	_part(Vector3(0, 1.0, 0), Vector3(0.32, 0.2, 0.2), uniform)
	var head := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.11
	s.height = 0.22
	head.mesh = s
	head.material_override = RangeLayout.colour(SKIN)
	head.position = Vector3(0, 1.66, 0)
	add_child(head)
	_part(Vector3(0, 1.74, 0), Vector3(0.26, 0.1, 0.28), Color(0.12, 0.2, 0.12))  # cap
	_part(Vector3(-0.27, 1.3, -0.02), Vector3(0.11, 0.5, 0.12), uniform)
	_part(Vector3(0.27, 1.36, -0.12), Vector3(0.11, 0.42, 0.12), uniform)
	_part(Vector3(-0.27, 1.45, -0.02), Vector3(0.13, 0.08, 0.14), Color(0.8, 0.1, 0.1))  # armband
	for x in [-0.1, 0.1]:
		var leg := Node3D.new()
		leg.position = Vector3(x, 0.88, 0)
		add_child(leg)
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.15, 0.86, 0.17)
		m.mesh = b
		m.material_override = RangeLayout.colour(Color(0.14, 0.18, 0.14))
		m.position.y = -0.43
		leg.add_child(m)
		legs.append(leg)
	gun = Node3D.new()
	gun.position = Vector3(0.1, 1.3, -0.25)
	add_child(gun)
	var glb := (load("res://assets/models/guns/%s.glb" % gun_id) as PackedScene).instantiate()
	gun.add_child(glb)
	anim = glb.find_children("*", "AnimationPlayer", true, false)[0]
	for n in anim.get_animation_list():
		if n.begins_with("Fire") and fire_clip == "":
			fire_clip = n
	if fire_clip != "":
		anim.get_animation(fire_clip).loop_mode = Animation.LOOP_NONE
	var mi := glb.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.01, -mi.get_aabb().size.z * 0.5)
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
	gun.rotation.x = move_toward(gun.rotation.x, 0.0 if engaged else -LOW_PITCH, delta * 3.0)


func glint(on: bool) -> void:
	scope_glint.visible = on


func fire() -> void:
	if fire_clip == "":
		return
	anim.play(fire_clip)
	anim.seek(0.0, true)


func _part(pos: Vector3, size: Vector3, col: Color) -> void:
	_part_in(self, pos, size, col)


func _part_in(host: Node3D, pos: Vector3, size: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = RangeLayout.colour(col)
	m.position = pos
	host.add_child(m)


func walk(delta: float, speed: float) -> void:
	_t += delta * speed * 2.2
	var a := sin(_t) * 0.6 * clampf(speed / 3.0, 0.0, 1.0)
	legs[0].rotation.x = a
	legs[1].rotation.x = -a
