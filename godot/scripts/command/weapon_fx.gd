class_name WeaponFx
## Visual-only weapon/structure feedback: spring recoil on the "Arm" part, muzzle
## flashes, hit flashes, nullifier charge glow, packet arrival pops, death debris.
## All state lives in static dicts keyed by instance_id (with weakrefs for pruning);
## logic files call one-line hooks. Shared mesh materials are never mutated — flashes
## use material_overlay with cached additive materials.

## Per weapon: [recoil kick distance (m), muzzle flash color].
const SHOTS := {
	"cannon": [0.5, Color("fff2b0")],
	"mortar": [0.65, Color("ffb347")],
	"bertha": [0.8, Color("ff9a3c")],
	"beam": [0.25, Color("ff6060")],
	"sniper": [0.45, Color("dff2ff")],
	"thor": [0.4, Color("7fe0ff")],
}

const SPRING_K := 220.0
const SPRING_C := 16.0

static var _st := {}      # instance_id -> {ref, arm, rest, kx, kv, flash_t, flash_dur, flash_col, meshes, core_meshes}
static var _omats := {}   # color html -> shared additive overlay material


static func _omat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _omats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_omats[key] = m
	return _omats[key]


static func _sweep() -> void:
	if _st.size() < 64:
		return
	for id in _st.keys():
		if (_st[id].ref as WeakRef).get_ref() == null:
			_st.erase(id)


static func _entry(s: Structure) -> Dictionary:
	_sweep()
	var id := s.get_instance_id()
	if _st.has(id) and (_st[id].ref as WeakRef).get_ref() == null:
		_st.erase(id)  # id reused after free: drop the stale entry
	if not _st.has(id):
		_st[id] = { "ref": weakref(s), "arm": null, "rest": Vector3.ZERO, "kx": 0.0, "kv": 0.0,
			"flash_t": 99.0, "flash_dur": 0.0, "flash_col": Color.WHITE, "meshes": [], "core_meshes": [] }
	return _st[id]


static func _body_meshes(s: Structure, e: Dictionary) -> Array:
	if e.meshes.is_empty() and is_instance_valid(s.body):
		for mi in s.body.find_children("*", "MeshInstance3D", true, false):
			(e.meshes as Array).append(mi)
	return e.meshes


static func _core_meshes(s: Structure, e: Dictionary) -> Array:
	if e.core_meshes.is_empty() and is_instance_valid(s.body):
		var core := s.body.find_child("Core", true, false) as Node3D
		if core:
			for mi in core.find_children("*", "MeshInstance3D", true, false):
				(e.core_meshes as Array).append(mi)
	return e.core_meshes


## Recoil kick on the "Arm" part (called when a weapon fires).
static func kick(s: Structure, dist := 0.4) -> void:
	if not is_instance_valid(s.body):
		return
	var e := _entry(s)
	if e.arm == null or not is_instance_valid(e.arm):
		e.arm = s.body.find_child("Arm", true, false) as Node3D
		if e.arm == null:
			return
		e.rest = (e.arm as Node3D).position
	e.kx = dist
	e.kv = 0.0


## Muzzle flash + kick + brief body flash. One-line hook from WeaponLogic fire sites.
static func fire(s: Structure, fx: Effects) -> void:
	var d: Array = SHOTS.get(s.type, [0.4, Color.WHITE])
	kick(s, d[0])
	var col: Color = d[1]
	var pos: Vector3 = WeaponLogic._fx(s)
	fx.burst(pos, col, 1.3, 0.09)
	fx.flash_light(pos, col)
	var e := _entry(s)
	e.flash_t = 0.0
	e.flash_dur = 0.12
	e.flash_col = col


## Small flash where a packet lands on its receiver.
static func packet_flash(fx: Effects, s: Structure) -> void:
	if not is_instance_valid(s.node):
		return
	fx.burst(s.node.position + Vector3(0, StructureMeshes.top_y(s.type) * 0.75, 0),
		Color("e8fbff"), 0.5, 0.15)


## Structure removed: debris + dust for kills, smaller pops otherwise.
static func death(fx: Effects, s: Structure, reason: String) -> void:
	var p := s.node.position + Vector3.UP
	match reason:
		"destroyed":
			fx.debris(p, Color("8a7a5a"), 10)
			fx.dust(p, 2.2)
			fx.burst(p, Color("ff6a33"), 3.0, 0.5)
			fx.flash_light(p, Color("ff8a4d"))
		"recycled":
			fx.burst(p, Color("7fe0ff"), 1.5, 0.3)
		_:
			fx.dust(p, 1.0)


## Per-frame visual update for one structure. One-line hook from StructureBehaviors.
static func update(s: Structure, dt: float) -> void:
	if not is_instance_valid(s.body):
		return
	var e := _entry(s)
	# Recoil spring on the arm.
	if e.arm != null and is_instance_valid(e.arm):
		e.kv += (-SPRING_K * e.kx - SPRING_C * e.kv) * dt
		e.kx += e.kv * dt
		if absf(e.kx) > 0.001 or absf(e.kv) > 0.001:
			(e.arm as Node3D).position = (e.rest as Vector3) + Vector3(-e.kx, 0, 0)
	# Overlay flash: fire flash > hurt flash > nullifier charge glow.
	var col := Color(0, 0, 0, 0)
	var meshes: Array = []
	if e.flash_t < e.flash_dur:
		e.flash_t += dt
		var k: float = 1.0 - e.flash_t / e.flash_dur
		col = Color(e.flash_col, 0.55 * k)
		meshes = _body_meshes(s, e)
	elif s.hurt > 0.0:
		col = Color(1.0, 0.25, 0.2, 0.45)
		meshes = _body_meshes(s, e)
	elif s.type == "nullifier" and s.charge > 0.0:
		var k: float = s.charge / Config.NULLIFY_TIME
		col = Color(0.75, 0.35, 1.0, 0.15 + 0.45 * k)
		meshes = _core_meshes(s, e)
	_apply(s, e, col, meshes)


static func _apply(s: Structure, e: Dictionary, col: Color, meshes: Array) -> void:
	var key := "none" if col.a <= 0.0 else col.to_html()
	if e.get("shown", "none") == key:
		return  # already in the desired state
	e.shown = key
	for mi in _body_meshes(s, e):
		(mi as MeshInstance3D).material_overlay = null
	for mi in _core_meshes(s, e):
		(mi as MeshInstance3D).material_overlay = null
	if col.a > 0.0:
		var m := _omat(col)
		for mi in meshes:
			(mi as MeshInstance3D).material_overlay = m
