class_name AdsPose
## FB-H: the one rule that places a gun at full ADS. The rear and front sight points (gun space, muzzle -Z) both lie on
## the camera's forward axis, with zero roll, and the rear point sits `relief` metres ahead of the eye. Points come from
## art/gen/mounts.json (irons) or from the fitted sight's lens axis; with neither, `points` is empty (caller falls back).


## [rear, front] in gun space, or [] when the gun has no sight points for this fit.
static func points(def: Dictionary, sight_id: String, half: float) -> Array:
	if sight_id != "":
		var m := AttachmentMounts.mount(def, "sight", half)
		var row: Dictionary = AttachmentDefs.ROWS[sight_id]
		var h := float(row["axis_h"]) * Vector3.UP + m
		var d := float(row["depth"]) * 0.5
		return [h + Vector3(0, 0, d), h - Vector3(0, 0, d)]
	var rear = AttachmentMounts._override(def["id"], "sight_rear")
	var front = AttachmentMounts._override(def["id"], "sight_front")
	if rear is Vector3 and front is Vector3:
		return [rear, front]
	return []


## TacticalConfig.ADS_RELIEF key for this gun and fit.
static func kind(def: Dictionary, sight_id: String) -> String:
	var pistol: bool = def.get("class", "") == "pistol"
	if sight_id != "":
		var row: Dictionary = AttachmentDefs.ROWS[sight_id]
		if pistol:
			return "pistol_optic"
		return "scope" if float(row["zoom"]) > 1.0 or row.has("zoom_max") else "optic"
	if pistol:
		return "pistol"
	var k := String(AttachmentMounts._override(def["id"], "sight_kind"))
	return "notch" if k == "none" or k == "" else k


## Iron sights: never closer than the gun's `relief_min` (mounts.json, from art/guns_src/eye_clear.py: the eye keeps
## TacticalConfig.ADS_EYE_CLEAR from every part of the gun). Set only where the kind's relief would put the eye inside it.
static func relief(def: Dictionary, sight_id: String) -> float:
	var r := float(TacticalConfig.ADS_RELIEF.get(kind(def, sight_id), 0.16))
	var m = AttachmentMounts._override(def["id"], "relief_min") if sight_id == "" else null
	return maxf(r, float(m)) if m != null else r


## Rotation (pitch, yaw, zero roll; Node3D YXZ order) that sends front - rear to -Z, and the origin that puts the
## rear point at (0, 0, -relief). Identity when there are no sight points.
static func pose(def: Dictionary, sight_id: String, half: float) -> Transform3D:
	var p := points(def, sight_id, half)
	if p.is_empty():
		return Transform3D.IDENTITY
	return solve(p[0], p[1], relief(def, sight_id))


static func solve(rear: Vector3, front: Vector3, rel: float) -> Transform3D:
	var d := front - rear
	var rho := sqrt(d.y * d.y + d.z * d.z)
	var b := Basis.from_euler(Vector3(atan2(-d.y, -d.z), atan2(d.x, rho), 0.0))
	return Transform3D(b, -(b * rear) + Vector3(0, 0, -rel))
