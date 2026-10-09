class_name CrossbowFx
extends RefCounted
## Crossbow shot animation on the viewmodel: the string snaps forward and rings back, the
## loaded bolt is gone while the shot flies, a bright glint flares at the bolt tip and the
## sight crystal overbrightens. Purely visual; OperativeWeapons calls shoot() once per shot.

const BOLT_GONE := 0.24   # seconds the model's bolt stays hidden (the reload)
const GLINT_TIME := 0.09

var _string: Node3D
var _bolt: Node3D
var _hand: Node3D
var _hand_base := Vector3.ZERO
var _crystal: MeshInstance3D
var _glint: MeshInstance3D
var _s := 0.0
var _sv := 0.0
var _gone := 0.0
var _glint_t := 0.0
var _reload := -1.0   # reload progress 0..1, -1 = loaded


func _init(model: Node3D, crystal: MeshInstance3D) -> void:
	_string = model.get_node_or_null("string")
	_bolt = model.get_node_or_null("bolt")
	_hand = model.get_node_or_null("arms/hand_l")
	if _hand:
		_hand_base = _hand.position
	_crystal = crystal
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	_glint = MeshInstance3D.new()
	_glint.mesh = sm
	_glint.material_override = Effects.glow_mat(Color("c8f6ff"), 0.95)
	_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint.position = Vector3(0, 0.048, -0.47)
	_glint.visible = false
	model.add_child(_glint)


func shoot() -> void:
	_s = 1.0
	_sv = 0.0
	_gone = BOLT_GONE
	_glint_t = GLINT_TIME


## Crossbow reload pose: the string stays slack and forward until it is drawn back, then the
## bolt is set. k is 0..1 progress, -1 when loaded.
func set_reload(k: float) -> void:
	_reload = k


func update(dt: float) -> void:
	var left := dt
	while left > 0.0:
		var h := minf(left, 1.0 / 180.0)
		left -= h
		_sv += (-Config.VM_SPRING_K * 1.2 * _s - Config.VM_SPRING_DAMP * 0.8 * _sv) * h
		_s += _sv * h
	if _string:
		var slack := 0.0 if _reload < 0.0 else -0.05 * (1.0 - smoothstep(0.0, 0.7, _reload))
		_string.position.z = -_s * Config.VM_STRING_SNAP + slack
	# Reload hand: the off hand grabs the slack string, draws it back with it, then
	# returns to the foregrip as the bolt is placed (bolt appears at reload > 0.75).
	if _hand:
		if _reload < 0.0:
			_hand.position = _hand_base
		else:
			var slack := -0.05 * (1.0 - smoothstep(0.0, 0.7, _reload))
			var draw := 1.0 - smoothstep(0.55, 0.78, _reload)
			_hand.position = _hand_base + Vector3(0, 0.02 * draw, slack * draw)
	_gone = maxf(0.0, _gone - dt)
	if _bolt:
		_bolt.visible = _gone <= 0.0 and (_reload < 0.0 or _reload > 0.75)
	_glint_t = maxf(0.0, _glint_t - dt)
	_glint.visible = _glint_t > 0.0
	if _glint.visible:
		var k := _glint_t / GLINT_TIME
		_glint.scale = Vector3.ONE * lerpf(0.05, 0.2, 1.0 - k * k)
	var m := _crystal.material_override as StandardMaterial3D
	if m:
		m.emission_energy_multiplier = 0.9 + 4.0 * clampf(_glint_t / GLINT_TIME, 0.0, 1.0)
