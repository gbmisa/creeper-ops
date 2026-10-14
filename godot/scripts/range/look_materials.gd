class_name LookMaterials
## Shared PBR materials (Poly Haven CC0, see assets/CREDITS.md) for the range and Skirmish. World-space triplanar UVs,
## so a box of any size tiles at the same texel density. Visual only: collision and the `mat` ids are untouched.
## STYLE[map][mat] = [texture id, metres per tile, tint, tint_mix (how much the layout colour shows through), normal strength]

const DIR := "res://assets/textures/polyhaven/"

const STYLE := {
	"range": {   # clean, well-kept base
		"concrete": ["concrete_floor_worn_001", 3.0, Color(1.6, 1.55, 1.45), 0.15, 0.8],
		"dirt_berm": ["grass_ground", 4.0, Color(1.0, 1.0, 0.8), 0.1, 1.0],
		"berm": ["grass_ground", 3.0, Color(0.95, 1.05, 0.72), 0.1, 1.2],
		"wood_plank": ["wood_planks", 1.5, Color(0.85, 0.8, 0.72), 0.2, 1.0],
		"plywood": ["plywood", 2.0, Color(0.95, 0.92, 0.85), 0.15, 0.8],
		"brick": ["brick_wall_005", 2.0, Color(1, 1, 1), 0.2, 1.0],
		"sheet_metal": ["corrugated_iron", 2.0, Color(1, 1, 1), 0.7, 1.0],
	},
	"skirmish": {   # derelict border station, late autumn
		"concrete": ["dirty_concrete", 3.0, Color(1.25, 1.25, 1.2), 0.1, 1.0],
		"dirt_berm": ["brown_mud_leaves_01", 3.5, Color(0.8, 0.82, 0.68), 0.05, 1.2],
		"berm": ["gravel_concrete_02", 3.0, Color(0.85, 0.85, 0.9), 0.1, 1.2],
		"wood_plank": ["weathered_planks", 1.5, Color(0.8, 0.75, 0.68), 0.15, 1.0],
		"plywood": ["peeling_painted_wall", 2.5, Color(1.2, 1.3, 1.15), 0.3, 1.0],
		"brick": ["brick_moss_001", 2.0, Color(1.4, 1.3, 1.2), 0.2, 1.0],
		"sheet_metal": ["rusty_corrugated_iron", 2.0, Color(1, 1, 1), 0.45, 1.0],
	},
}

static var _cache := {}
static var _tex := {}


static func map_id() -> String:
	return "skirmish" if RangeMaps.selected == "skirmish" else "range"


## Material for a layout box, or the flat colour material when the mat id has no style.
static func get_mat(mat: String, col: Color, nm := "") -> StandardMaterial3D:
	var map := map_id()
	if DisplayServer.get_name() == "headless":   # nothing is drawn; skip texture loads (they stall the range-test nav sync)
		return RangeLayout.colour(col)
	if nm.begins_with("berm"):
		mat = "berm"
	var st: Dictionary = STYLE[map]
	if not st.has(mat):
		return RangeLayout.colour(col)
	var key := "%s|%s|%s" % [map, mat, col.to_html(false)]
	if _cache.has(key):
		return _cache[key]
	var s: Array = st[mat]
	var m := StandardMaterial3D.new()
	var id: String = s[0]
	m.albedo_texture = _load(id, "diff")
	m.normal_enabled = true
	m.normal_texture = _load(id, "nor")
	m.normal_scale = s[4]
	var arm := _load(id, "arm")
	if arm != null:
		m.ao_enabled = true
		m.ao_texture = arm
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.roughness_texture = arm
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.metallic_texture = arm
		m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		m.metallic = 1.0
		m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / float(s[1])
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# layout colour only tints: keep its hue, normalise brightness, blend by tint_mix
	var hue := Color.WHITE.lerp(col * (1.0 / maxf(col.get_luminance() * 2.0, 0.2)), float(s[3]))
	m.albedo_color = (s[2] as Color) * hue
	_cache[key] = m
	return m


static func _load(id: String, kind: String) -> Texture2D:
	var p := "%s%s/%s.jpg" % [DIR, id, kind]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]
