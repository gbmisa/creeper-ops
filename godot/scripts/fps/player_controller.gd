class_name PlayerController
extends RefCounted
## First-person movement on a heightfield Grid: mouse look, walk/sprint/jump, smooth ground
## that matches the rendered terrain, cliffs (cell rise > CLIMB) that block unless you jump
## high enough, gravity, per-axis sliding and a little head bob.

const SENSITIVITY := 0.0022

var camera: Camera3D
var pos := Vector3.ZERO   # feet
var vel_y := 0.0
var yaw := 0.0
var pitch := 0.0
var on_ground := false
var bob := 0.0
var moving := false


func _init(cam: Camera3D) -> void:
	camera = cam


func spawn(g: Grid, x: int, z: int, facing := PI) -> void:
	pos = g.cell_ground(x, z)
	vel_y = 0.0
	yaw = facing
	pitch = 0.0
	_sync()


## Can the body (a small square) stand at (x, z) given the current height?
func can_occupy(g: Grid, x: float, z: float) -> bool:
	var r := Config.OP_RADIUS
	var reach := maxf(pos.y, g.ground_y(pos.x, pos.z)) / Config.LEVEL_H + Config.CLIMB  # in levels
	for o in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var c := g.world_to_cell(x + o.x, z + o.y)
		if not g.in_bounds(c.x, c.y) or g.walk_height(c.x, c.y, Grid.Faction.PLAYER) > reach:
			return false
	return true


func update(dt: float, input: InputState, g: Grid, speed_factor := 1.0) -> void:
	yaw -= input.mouse_delta.x * SENSITIVITY
	pitch = clampf(pitch - input.mouse_delta.y * SENSITIVITY, -1.5, 1.5)
	var mv := Vector2.ZERO
	if input.held("op_forward"): mv.y -= 1.0
	if input.held("op_back"): mv.y += 1.0
	if input.held("op_left"): mv.x -= 1.0
	if input.held("op_right"): mv.x += 1.0
	moving = mv.length() > 0.0
	if moving:
		var speed := (Config.SPRINT if input.held("sprint") else Config.WALK) * speed_factor
		mv = mv.normalized()
		var s := sin(yaw)
		var c := cos(yaw)
		var dx := (mv.x * c + mv.y * s) * speed * dt
		var dz := (-mv.x * s + mv.y * c) * speed * dt
		if can_occupy(g, pos.x + dx, pos.z):  # per-axis so you slide along cliffs
			pos.x += dx
		if can_occupy(g, pos.x, pos.z + dz):
			pos.z += dz
		if on_ground:
			bob += dt * speed * 1.6
	if on_ground and input.act("jump"):
		vel_y = Config.JUMP_V
		on_ground = false
	vel_y -= Config.GRAVITY * dt
	pos.y += vel_y * dt
	var ground := g.stand_y(pos.x, pos.z, Grid.Faction.PLAYER)  # drawbridge decks count
	if pos.y <= ground:
		pos.y = ground
		vel_y = 0.0
		on_ground = true
	elif on_ground and vel_y <= 0.0 and pos.y - ground < 0.5:
		pos.y = ground  # stick to slopes walking downhill
		vel_y = 0.0
	else:
		on_ground = false
	_sync()


func _sync() -> void:
	var b := sin(bob) * 0.05 if moving and on_ground else 0.0
	camera.position = pos + Vector3(0, Config.EYE + b, 0)
	camera.rotation = Vector3(pitch, yaw, 0)


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))
