class_name CommandCamera
extends Camera3D
## Top-down orbit camera: WASD / arrow / screen-edge pan, Q/E rotate, wheel zoom,
## middle-drag rotate. Panning is clamped to the map.

const EDGE_PX := 6

var target := Vector3.ZERO
var yaw := 0.0
var pitch := 0.95
var dist := 70.0
var bounds := Vector2(160, 160)
var edge_pan := true


func _init() -> void:
	name = "CommandCamera"
	fov = 50.0
	near = 0.5
	far = 1500.0


func focus(p: Vector3) -> void:
	target = p
	_apply()


func update(dt: float, input: InputState, grid: Grid) -> void:
	var pan := Vector2.ZERO
	if input.held("cam_forward"): pan.y -= 1.0
	if input.held("cam_back"): pan.y += 1.0
	if input.held("cam_left"): pan.x -= 1.0
	if input.held("cam_right"): pan.x += 1.0
	var vp := get_viewport().get_visible_rect().size
	var m := input.mouse
	if edge_pan and DisplayServer.window_is_focused() and m != Vector2.ZERO:
		if m.x <= EDGE_PX: pan.x -= 1.0
		if m.x >= vp.x - EDGE_PX: pan.x += 1.0
		if m.y <= EDGE_PX: pan.y -= 1.0
		if m.y >= vp.y - EDGE_PX: pan.y += 1.0
	if pan != Vector2.ZERO:
		var speed := dist * 0.9 * dt
		var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		target += (right * pan.x - fwd * pan.y) * speed
	if input.held("cam_rot_left"): yaw += 1.6 * dt
	if input.held("cam_rot_right"): yaw -= 1.6 * dt
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		yaw -= input.mouse_delta.x * 0.006
		pitch = clampf(pitch + input.mouse_delta.y * 0.004, 0.35, 1.45)
	if input.wheel != 0.0:
		dist = clampf(dist * pow(1.12, input.wheel), 18.0, 220.0)
	target.x = clampf(target.x, 0.0, bounds.x)
	target.z = clampf(target.z, 0.0, bounds.y)
	target.y = lerpf(target.y, grid.smooth_y(target.x, target.z), minf(1.0, dt * 4.0))
	_apply()


func _apply() -> void:
	var off := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	look_at_from_position(target + off, target, Vector3.UP)


## Ground point under a screen position, or null.
func pick(screen: Vector2, grid: Grid) -> Variant:
	return grid.raycast(project_ray_origin(screen), project_ray_normal(screen), 1500.0)
