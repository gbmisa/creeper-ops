class_name HitboxRig
## Zone colliders for a humanoid body (layer 2, bullet-only) and collider -> (body, owner, zone).

## zone -> [centre, size (Vector3 box) or radius (float sphere)], standing, feet at y = 0
const SHAPES := {
	"head": [Vector3(0, 1.66, 0), 0.12],
	"thorax": [Vector3(0, 1.3, 0), Vector3(0.38, 0.4, 0.24)],
	"stomach": [Vector3(0, 1.0, 0), Vector3(0.32, 0.22, 0.22)],
	"larm": [Vector3(-0.27, 1.28, 0), Vector3(0.12, 0.55, 0.14)],
	"rarm": [Vector3(0.27, 1.28, 0), Vector3(0.12, 0.55, 0.14)],
	"lleg": [Vector3(-0.1, 0.45, 0), Vector3(0.16, 0.88, 0.18)],
	"rleg": [Vector3(0.1, 0.45, 0), Vector3(0.16, 0.88, 0.18)],
}


## Builds the colliders under `parent`; returns zone -> StaticBody3D.
static func build(parent: Node3D, body: BodyHealth, owner_node: Node) -> Dictionary:
	var rig := {}
	for zone in SHAPES:
		var sb := StaticBody3D.new()
		sb.name = "hb_" + zone
		sb.collision_layer = TacticalConfig.LAYER_HITBOX
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var row: Array = SHAPES[zone]
		if row[1] is float:
			var s := SphereShape3D.new()
			s.radius = row[1]
			cs.shape = s
		else:
			var b := BoxShape3D.new()
			b.size = row[1]
			cs.shape = b
		sb.position = row[0]
		sb.add_child(cs)
		sb.set_meta("hb_body", body)
		sb.set_meta("hb_owner", owner_node)
		sb.set_meta("hb_zone", zone)
		parent.add_child(sb)
		rig[zone] = sb
	return rig


## {} for non-hitboxes, else {body, owner, zone}.
static func lookup(collider: Object) -> Dictionary:
	if collider == null or not collider.has_meta("hb_zone"):
		return {}
	return {"body": collider.get_meta("hb_body"), "owner": collider.get_meta("hb_owner"), "zone": collider.get_meta("hb_zone")}


static func rids(rig: Dictionary) -> Array[RID]:
	var out: Array[RID] = []
	for z in rig:
		out.append((rig[z] as CollisionObject3D).get_rid())
	return out
