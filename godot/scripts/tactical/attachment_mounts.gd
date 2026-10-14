class_name AttachmentMounts
## Where attachments sit on a gun (gun space, muzzle -Z) and the sight line they give. Defaults come from the gun's view
## data (ads_pos); art/gen/mounts.json (ART track, {gun_id: {rail, muzzle, under: [x,y,z], ads_y}}) overrides them through
## `_override`, the only place that reads it.

const IRON_BELOW := 0.015  # rail top is this far under the iron sight line
static var _json := {}
static var _loaded := false


static func _override(gun_id: String, key: String):
	if not _loaded:
		_loaded = true
		var path := ProjectSettings.globalize_path("res://").path_join("../art/gen/mounts.json")
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				_json = parsed
	var row = _json.get(gun_id)
	if row is Dictionary and row.has(key):
		var a = row[key]
		return Vector3(a[0], a[1], a[2]) if a is Array else a
	return null


static func iron_y(def: Dictionary) -> float:
	var o = _override(def["id"], "ads_y")
	return float(o) if o != null else -(def["ads_pos"] as Vector3).y


static func mount(def: Dictionary, slot: String, half: float) -> Vector3:
	var o = _override(def["id"], {"sight": "rail", "muzzle": "muzzle", "under": "under", "mag": "mag_l"}[slot])
	if o is Vector3:
		return o
	var iy := iron_y(def)
	match slot:
		"sight":
			return Vector3(0, iy - IRON_BELOW, -half * 0.12)
		"muzzle":
			return Vector3(0, iy - 0.045, -half)
		"under":
			return Vector3(0, iy - 0.075, -half * 0.55)
	return (def["mag_l"] as Vector3) + Vector3(0, -0.05, 0)


## Eye-line height in gun space with this sight fitted ("" = iron sights).
static func sight_line(def: Dictionary, sight_id: String) -> float:
	if sight_id == "":
		return iron_y(def)
	return mount(def, "sight", 0.0).y + float(AttachmentDefs.ROWS[sight_id]["axis_h"])


static func ads_pos(def: Dictionary, sight_id: String) -> Vector3:
	var p: Vector3 = def["ads_pos"]
	if sight_id != "":
		p.y = -sight_line(def, sight_id)
	return p
