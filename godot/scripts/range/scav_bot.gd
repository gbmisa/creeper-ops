class_name ScavBot
extends CharacterBody3D
## An enemy bot. Row `kind` of BotDefs (default `rifleman` = the Scav: AK-47 (PS), class 2 vest), hitbox rig + BodyHealth, magazine reloads, real ballistics. Perception in
## BotPerception, decisions in BotBrain, movement with a NavigationAgent3D on the kill house navmesh.
## `think(dt, over)` is the whole AI tick (tests call it directly with fact overrides).

signal state_changed(bot: ScavBot, from: String, to: String)
signal died(bot: ScavBot)

const WALK := 1.8
const MOVE := 2.6
const RUN := 4.2
const EYE := 1.6
const TURN := 8.0

var label_name := "Scav"
var kind := "rifleman"
var def := {}
var body := BodyHealth.new()
var gun: Gun
var brain := BotBrain.new()
var percept := BotPerception.new()
var rig := {}
var player: TacticalPlayer
var bal: Ballistics
var covers: Array[Vector3] = []
var patrol: Array[Vector3] = []
var ally: ScavBot
var leader: ScavBot
var reloc_t := 0.0
var shots_since := 0
var winding := false
var wind := 0.0
var rng := RandomNumberGenerator.new()
var nav: NavigationAgent3D
var mesh: BotMesh
var flash: MuzzleFlash
var hurt_t := 0.0
var has_cover := false
var cover_pos := Vector3.ZERO
var patrol_i := 0
var _target := Vector3.ZERO
var _has_target := false
var burst := 0
var cd := 0.0
var cover_t := 0.0
var _dying := false
var _go_age := 0.0


func _init() -> void:
	collision_layer = TacticalConfig.LAYER_BODY
	collision_mask = TacticalConfig.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)


## `house` is anything with `covers` and `patrol` (KillHouse, SkirmishLayout); `route` overrides its patrol.
func setup(p: TacticalPlayer, b: Ballistics, house: Node3D, label: String, start_idx: int, bot_kind := "rifleman", route: Array[Vector3] = []) -> void:
	player = p
	bal = b
	kind = bot_kind
	def = BotDefs.of(kind)
	covers = house.covers if house != null else []
	patrol = route if not route.is_empty() else (house.patrol if house != null else [Vector3.ZERO])
	if def["overwatch"]:
		covers = []
	percept.range_m = def["sight"]
	label_name = label
	patrol_i = start_idx % patrol.size()
	rng.randomize()
	gun = Gun.new(def["gun"])
	for a in def["armor"]:
		body.equip(a)
	BotNoise.listen(_on_noise)


func _ready() -> void:
	rig = HitboxRig.build(self, body, self)
	mesh = BotMesh.new(def)
	add_child(mesh)
	flash = MuzzleFlash.new(mesh.muzzle, Vector3(0, 0, -0.1))
	nav = NavigationAgent3D.new()
	nav.radius = 0.4
	nav.path_desired_distance = 0.5
	nav.target_desired_distance = 0.7
	nav.path_max_distance = 3.0
	add_child(nav)
	_go(patrol[patrol_i])


func _physics_process(dt: float) -> void:
	think(dt)
	_move(dt)
	flash.update(dt)
	mesh.aim(dt, is_engaged())


func is_engaged() -> bool:
	return not body.dead and brain.state in [BotBrain.ENGAGE, BotBrain.SUPPRESS]


func eye() -> Vector3:
	return global_position + Vector3(0, EYE, 0)


func _on_noise(pos: Vector3, radius: float, _kind: String, src: Object) -> void:
	if body.dead or src is ScavBot or not is_inside_tree():
		return
	if global_position.distance_to(pos) <= radius:
		percept.hear(pos)


## Called by RangeFeedback with the Ballistics.body_hit dictionary.
func on_hit(res: Dictionary) -> void:
	hurt_t = 1.5
	if not _dying and not body.dead and def["overwatch"]:
		BotEngage.relocate(self)
	if not _dying:
		percept.alert(player.global_position if player != null else res.get("origin", global_position))
	if body.dead:
		_die()


func think(dt: float, over := {}) -> void:
	if body.dead or _dying:
		return
	body.tick(dt)
	if body.dead:
		_die()
		return
	gun.update(dt)
	hurt_t = maxf(0.0, hurt_t - dt)
	cd -= dt
	_go_age += dt
	cover_t -= dt
	reloc_t = maxf(0.0, reloc_t - dt) if reloc_t > 0.0 else 0.0
	wind -= dt
	if winding and not is_engaged():
		winding = false
		mesh.glint(false)
	_sense(dt)
	var f := _facts()
	f.merge(over, true)
	var from := brain.state
	var to := brain.update(dt, f)
	percept.noise_new = false
	if to != "":
		if from == BotBrain.HEAL and to == BotBrain.SEARCH:
			body.heal(0.4)
		_enter(to)
		print("[bot] ", label_name, " ", from, " -> ", to)
		state_changed.emit(self, from, to)
	_act()


func _sense(dt: float) -> void:
	if player == null or player.body.dead:
		percept.seeing = false
		percept.aware = false
		percept.since_seen = 99.0
		return
	var head := player.eye_pos()
	var chest := player.global_position + Vector3(0, 0.85 if player.crouching else 1.3, 0)
	var still := player.horizontal_speed() < 0.3 or player.crouching
	percept.update(dt, eye(), -global_basis.z, get_world_3d().direct_space_state, [head, chest], still, rng, player.spot_mult)


func _facts() -> Dictionary:
	return BotShooting.facts(self)


func _find_cover() -> void:
	BotShooting.find_cover(self)


func _enter(s: String) -> void:
	match s:
		BotBrain.PATROL:
			_go(patrol[patrol_i])
		BotBrain.INVESTIGATE:
			_go(percept.noise_pos)
		BotBrain.COVER:
			_find_cover()
			_go(cover_pos)
		BotBrain.HEAL, BotBrain.SUPPRESS:
			_has_target = false
		BotBrain.FLANK:
			var d := _flat(percept.last_known - global_position)
			var side := Vector3(-d.z, 0, d.x).normalized() * (10.0 if rng.randf() < 0.5 else -10.0)
			_go(percept.last_known + side)
		BotBrain.SEARCH:
			_go(percept.last_known)
	mesh.scale.y = 0.8 if s == BotBrain.HEAL else 1.0


func _act() -> void:
	var s := brain.state
	if gun.mag.count() == 0 and gun.chamber == "" and not gun.busy():
		if not gun.reload(false):
			gun.refill()
	elif s not in [BotBrain.ENGAGE, BotBrain.SUPPRESS] and gun.mag.count() < 10 and not gun.busy():
		gun.reload(false)
	if gun.needs_cycle and not gun.busy():
		gun.release()
	if gun.malf != "" and not gun.busy():
		gun.inspect()
	match s:
		BotBrain.PATROL:
			BotEngage.patrol(self)
		BotBrain.ENGAGE:
			BotEngage.engage(self)
		BotBrain.SUPPRESS:
			if percept.has_last:
				_shoot_at(percept.last_known + Vector3(rng.randf_range(-1.2, 1.2), 0.2, rng.randf_range(-1.2, 1.2)))


func _shoot_at(point: Vector3) -> void:
	BotShooting.fire(self, point)


func _go(p: Vector3) -> void:
	_target = p
	_has_target = true
	_go_age = 0.0
	if nav != null and (nav.target_position - p).length() > 0.5:
		nav.target_position = p


func _arrived() -> bool:
	if not _has_target:
		return true
	if _flat(global_position - _target).length() < 1.0:
		return true
	# the navmesh needs a few frames to sync after bake: only trust "finished" once a path exists (or 1.5 s passed)
	var routed := nav != null and (nav.get_current_navigation_path().size() > 1 or _go_age > 1.5)
	return routed and nav.is_navigation_finished() and _flat(global_position - nav.get_final_position()).length() < 1.0


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


func _move(dt: float) -> void:
	BotMotion.move(self, dt)


func _die() -> void:
	if _dying:
		return
	_dying = true
	for z in rig:
		(rig[z] as CollisionObject3D).collision_layer = 0
	collision_layer = 0
	var tw := create_tween()
	mesh.die()
	tw.tween_interval(8.5)
	tw.tween_callback(queue_free)
	died.emit(self)
