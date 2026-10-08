class_name MuzzleFlash
extends RefCounted
## One reusable additive flash (plus a short light) at a weapon's muzzle, for rockets and the
## Armoury weapons. The crossbow has its own glint (CrossbowFx).

var _mesh: MeshInstance3D
var _light: OmniLight3D
var _t := 0.0
var _life := 0.1
var _size := 1.0


func _init(parent: Node3D, at: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	_mesh = MeshInstance3D.new()
	_mesh.mesh = sm
	_mesh.material_override = Effects.glow_mat(Color.WHITE, 0.9)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.position = at
	_mesh.visible = false
	parent.add_child(_mesh)
	_light = OmniLight3D.new()
	_light.omni_range = 7.0
	_light.shadow_enabled = false
	_light.visible = false
	_light.position = at
	parent.add_child(_light)


## size is in the parent's (scaled) model units; life in seconds.
func flash(color: Color, size: float, life := 0.1, energy := 3.0) -> void:
	_t = life
	_life = life
	_size = size
	(_mesh.material_override as StandardMaterial3D).albedo_color = Color(color, 0.9)
	_light.light_color = color
	_light.light_energy = energy
	_mesh.visible = true
	_light.visible = true


func active() -> bool:
	return _t > 0.0


func update(dt: float) -> void:
	_t = maxf(0.0, _t - dt)
	var on := _t > 0.0
	_mesh.visible = on
	_light.visible = on
	if on:
		var k := _t / _life
		_mesh.scale = Vector3.ONE * _size * (1.4 - 0.7 * k)
		_light.light_energy *= 0.8 + 0.2 * k
