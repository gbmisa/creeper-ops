class_name BowRig
## F146: moves the named parts of compound_bow.glb / crossbow.glb (art/guns_src/scratch_*.py). Bow: the String's
## "draw" blend shape and the nocked Arrow follow PlayerWeapons.bow_draw, the right hand rides the string. Crossbow:
## the String's "cock" shape is 1 while a bolt is loaded and pulls back over the reload. IronSight hides under an optic.

const DRAW_M := 0.55  # nock travel at full draw (scratch_compound_bow.py DRAW)

var _string: MeshInstance3D
var _shape := -1
var _ammo: Node3D     # Arrow / Bolt node
var _irons: Node3D
var _bow := false
var _ammo_z := 0.0
var _rl_len := 0.0
var draw := 0.0


## A rig when the glb has the named parts, else null (the fallback models have none).
static func make(glb: Node, def: Dictionary) -> BowRig:
	if not (def["action"] in BowDefs.ACTIONS):
		return null
	var s := glb.find_child("String", true, false) as MeshInstance3D
	if s == null:
		return null
	var r := BowRig.new()
	r._bow = def["action"] == "bow"
	r._string = s
	r._shape = s.find_blend_shape_by_name("draw" if r._bow else "cock")
	r._ammo = glb.find_child("Arrow" if r._bow else "Bolt", true, false) as Node3D
	r._irons = glb.find_child("IronSight", true, false) as Node3D
	if r._ammo != null:
		r._ammo_z = r._ammo.position.z
	return r


func update(g: Gun, w: PlayerWeapons) -> void:
	var loaded := g.chamber != ""
	var reloading := g.busy_kind == "reload"
	if reloading:
		_rl_len = maxf(_rl_len, g.busy_t)
	else:
		_rl_len = 0.0
	var frac := 1.0 - g.busy_t / _rl_len if reloading and _rl_len > 0.0 else 0.0
	if _bow:
		draw = w.bow_draw
		if _ammo != null:
			_ammo.visible = loaded or (reloading and frac > 0.4)
			_ammo.position.z = _ammo_z + draw * DRAW_M
	else:
		draw = clampf(frac / 0.7, 0.0, 1.0) if reloading else (1.0 if loaded else 0.0)
		if _ammo != null:
			_ammo.visible = loaded or (reloading and frac > 0.75)
	if _shape >= 0:
		_string.set_blend_shape_value(_shape, draw)
	if _irons != null:
		_irons.visible = g.fit.get("sight", "") == ""


## The right hand on the string: the bow's grip_r is the nock at rest; it moves back with the draw.
func hand_r(grip_r: Vector3) -> Vector3:
	return grip_r + Vector3(0, 0, draw * DRAW_M) if _bow else grip_r
