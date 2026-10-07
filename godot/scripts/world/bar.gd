class_name Bar
extends MeshInstance3D
## Billboard HP/ammo/supply bar: one quad, drawn by a tiny shader (fill fraction + colour as
## per-instance uniforms), always facing the camera and never hidden behind terrain.

static var _mat: ShaderMaterial
static var _quad: QuadMesh

const SHADER := "shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;
instance uniform float fill = 1.0;
instance uniform vec4 fill_color : source_color = vec4(0.3, 1.0, 0.4, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0), vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
}
void fragment() {
	vec2 uv = UV;
	bool border = uv.x < 0.03 || uv.x > 0.97 || uv.y < 0.12 || uv.y > 0.88;
	vec3 c = uv.x <= fill ? fill_color.rgb : vec3(0.08, 0.08, 0.1);
	ALBEDO = border ? vec3(0.0) : c;
	ALPHA = 0.9;
}"


func _init(width := 1.6, y := 2.0) -> void:
	if _mat == null:
		var sh := Shader.new()
		sh.code = SHADER
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		_mat.render_priority = 10
		_quad = QuadMesh.new()
		_quad.size = Vector2(1, 1)
	mesh = _quad
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale = Vector3(width, 0.16, 1)
	position.y = y


func set_value(f: float, color: Color) -> void:
	set_instance_shader_parameter("fill", clampf(f, 0.0, 1.0))
	set_instance_shader_parameter("fill_color", color)


static func hp_color(f: float) -> Color:
	if f > 0.6:
		return Color("5dff8a")
	if f > 0.3:
		return Color("ffd23f")
	return Color("ff4b3b")
