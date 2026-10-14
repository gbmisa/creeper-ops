class_name RangeDummy
extends Node3D
## Armored mannequin: boxes / spheres at the HitboxRig zone shapes, a BodyHealth, armor overlays, a per-zone
## panel after hits, fall on death and respawn. Optional rail (moving target). Feet at local y = 0, faces +Z.

const RESPAWN := 4.0
const SKIN := Color(0.62, 0.55, 0.45)
const ARMOR_COL := {"vest2": Color(0.3, 0.38, 0.3), "plate4": Color(0.18, 0.2, 0.24), "steel6": Color(0.5, 0.52, 0.56), "helmet3": Color(0.3, 0.34, 0.2)}
const ZONE_NAMES := {"head": "Head", "thorax": "Thorax", "stomach": "Stomach", "larm": "L arm", "rarm": "R arm", "lleg": "L leg", "rleg": "R leg"}

var body := BodyHealth.new()
var label_name := "Dummy"
var loadout := 0
var rig := {}
var rail := Vector3.ZERO  # x0, x1, speed (m/s); zero speed = static
var _dir := 1.0
var _parts := {}   # zone -> MeshInstance3D
var _overlay := {}  # zone -> MeshInstance3D
var _marks: Array[Node3D] = []
var _dead_t := 0.0
var _fall: Tween


func _ready() -> void:
	rig = HitboxRig.build(self, body, self)
	for zone in HitboxRig.SHAPES:
		var row: Array = HitboxRig.SHAPES[zone]
		_parts[zone] = _mesh(row, rig[zone], SKIN, 1.0)
		_overlay[zone] = _mesh(row, rig[zone], Color.WHITE, 1.18)
		(_overlay[zone] as MeshInstance3D).visible = false
	set_loadout(loadout)


func _mesh(row: Array, host: Node3D, col: Color, grow: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if row[1] is float:
		var s := SphereMesh.new()
		s.radius = row[1] * grow
		s.height = s.radius * 2.0
		mi.mesh = s
	else:
		var b := BoxMesh.new()
		b.size = (row[1] as Vector3) * grow
		mi.mesh = b
	mi.material_override = RangeLayout.colour(col)
	host.add_child(mi)
	return mi


## Equips ArmorDefs.LOADOUTS[idx] (none / class 2 / class 4 / class 6 + helmet) at full durability.
func set_loadout(idx: int) -> void:
	loadout = idx % ArmorDefs.LOADOUTS.size()
	body.clear_armor()
	for z in _overlay:
		(_overlay[z] as MeshInstance3D).visible = false
	for id in ArmorDefs.LOADOUTS[loadout]:
		body.equip(id)
		for z in ArmorDefs.of(id)["zones"]:
			var mi := _overlay[z] as MeshInstance3D
			mi.material_override = RangeLayout.colour(ARMOR_COL[id])
			mi.visible = true


func kill() -> void:
	body.hit("head", 999.0)
	_die()


func respawn() -> void:
	if _fall != null:
		_fall.kill()
	body.reset()
	set_loadout(loadout)
	rotation = Vector3.ZERO
	_dead_t = 0.0
	for m in _marks:
		m.queue_free()
	_marks.clear()
	for z in rig:
		(rig[z] as CollisionObject3D).collision_layer = TacticalConfig.LAYER_HITBOX


## Called by RangeFeedback with the Ballistics.body_hit dictionary.
func on_hit(res: Dictionary) -> void:
	_mark(res)
	_flash(res["zone"])
	if res.get("killed", false):
		_die()


## Per-zone HP text for the HUD target panel.
func zones_text() -> String:
	var lines := [label_name.to_upper() + (" - DEAD" if body.dead else "")]
	for z in BodyHealth.ZONES:
		var a := ""
		if body.armor.has(z):
			a = "  [armor %d]" % int(body.armor[z]["dur"])
		lines.append("%s %d/%d%s" % [ZONE_NAMES[z], ceili(body.hp[z]), int(BodyHealth.MAX[z]), a])
	return "\n".join(lines)


func _die() -> void:
	_dead_t = RESPAWN
	for z in rig:
		(rig[z] as CollisionObject3D).collision_layer = 0
	_fall = create_tween()
	_fall.tween_property(self, "rotation:x", -PI * 0.5, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _mark(res: Dictionary) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.03
	s.height = 0.04
	m.mesh = s
	var mt := StandardMaterial3D.new()
	mt.albedo_color = {"PEN": Color(0.8, 0.1, 0.1), "BLOCKED": Color(0.95, 0.65, 0.1), "RICOCHET": Color(0.9, 0.9, 0.9)}.get(res["result"], Color.RED)
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mt
	add_child(m)
	m.global_position = res["pos"]
	_marks.append(m)


func _flash(zone: String) -> void:
	var mi := (_overlay[zone] if body.armor.has(zone) else _parts[zone]) as MeshInstance3D
	var base := mi.material_override
	mi.material_override = RangeLayout.colour(Color(1, 0.9, 0.6))
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(mi) and base != null:
		mi.material_override = base


func _process(delta: float) -> void:
	body.tick(delta)
	if body.dead:
		if _dead_t > 0.0:
			_dead_t -= delta
			if _dead_t <= 0.0:
				respawn()
		return
	if rail.z > 0.0:
		position.x += _dir * rail.z * delta
		if position.x > rail.y:
			_dir = -1.0
		elif position.x < rail.x:
			_dir = 1.0
