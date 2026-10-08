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
var kick_pitch := 0.0   # recoil camera kick (rad); set each frame by FpsMode, never accumulates
var moving := false
var _air_left := 0
var _jet_left := 0.0


func _init(cam: Camera3D) -> void:
	camera = cam


func spawn(g: Grid, x: int, z: int, facing := PI) -> void:
	pos = g.cell_ground(x, z)
	vel_y = 0.0
	yaw = facing
	pitch = 0.0
	_air_left = 0
	_jet_left = 0.0
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
		var speed := Config.WALK
		if input.held("sprint"):
			speed = Config.SPRINT * OperativeUpgrades.mult("mobility")
		speed *= speed_factor
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
	_push_out(g)
	if input.act("jump"):
		if on_ground:
			_hop()
		elif _air_left > 0:
			_air_left -= 1
			vel_y = Config.JUMP_V
	if not on_ground and input.held("jump") and _jet_left > 0.0:
		var lift := minf(_jet_left, OperativeUpgrades.jet_rate() * dt)
		pos.y += lift  # jump jet: one terrace of extra lift, then it is spent
		_jet_left -= lift
	vel_y -= Config.GRAVITY * dt
	pos.y += vel_y * dt
	var ground := g.stand_y(pos.x, pos.z, Grid.Faction.PLAYER)  # drawbridge decks count
	if pos.y <= ground:
		pos.y = ground
		vel_y = 0.0
		on_ground = true
		_air_left = 0
		_jet_left = 0.0
	elif on_ground and vel_y <= 0.0 and pos.y - ground < 0.5:
		pos.y = ground  # stick to slopes walking downhill
		vel_y = 0.0
	else:
		on_ground = false
	_sync()


## Moves the body clear of any wall cell its edge sank into. In the air the edge may slide
## over a ledge up to CLIMB above the feet; after landing beside it (worst in an inside
## corner) every move would keep that overlap and the Operative would be stuck.
func _push_out(g: Grid) -> void:
	var r := Config.OP_RADIUS
	var reach := maxf(pos.y, g.ground_y(pos.x, pos.z)) / Config.LEVEL_H + Config.CLIMB
	for o in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var c := g.world_to_cell(pos.x + o.x, pos.z + o.y)
		if g.walk_height(c.x, c.y, Grid.Faction.PLAYER) <= reach:
			continue
		var x0 := c.x * Config.CELL
		var z0 := c.y * Config.CELL
		var in_x := pos.x >= x0 and pos.x < x0 + Config.CELL
		var in_z := pos.z >= z0 and pos.z < z0 + Config.CELL
		var px := (x0 - r - 0.01) if pos.x < x0 else (x0 + Config.CELL + r + 0.01)
		var pz := (z0 - r - 0.01) if pos.z < z0 else (z0 + Config.CELL + r + 0.01)
		if in_x and in_z:
			continue  # the centre is on that cell: it's the floor, not a wall
		if in_z or (not in_x and absf(px - pos.x) <= absf(pz - pos.z)):
			pos.x = px
		else:
			pos.z = pz


func _hop() -> void:
	vel_y = Config.JUMP_V
	on_ground = false
	_air_left = OperativeUpgrades.air_jumps()
	_jet_left = OperativeUpgrades.jet_budget()


func _sync() -> void:
	var b := sin(bob) * 0.05 if moving and on_ground else 0.0
	camera.position = pos + Vector3(0, Config.EYE + b, 0)
	camera.rotation = Vector3(pitch + kick_pitch, yaw, 0)


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))
