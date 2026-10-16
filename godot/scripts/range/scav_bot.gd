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
var session: RangeSession
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
var react_t := 0.0   # F18: rolled per engagement; the bot will not fire at a seen target before sight_t passes this
var cover_t := 0.0
var shot_cover := false  # F88: current TakeCover was entered from a heard shot
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
func setup(s: RangeSession, b: Ballistics, house: Node3D, label: String, start_idx: int, bot_kind := "rifleman", route: Array[Vector3] = []) -> void:
	session = s
	bal = b
	kind = bot_kind
	def = BotDefs.of(kind)
	covers = house.covers
	patrol = route if not route.is_empty() else house.patrol
	if def["overwatch"]:
		covers = []
	percept.range_m = def["sight"]
	label_name = label
	patrol_i = start_idx % patrol.size()
	rng.seed = s.next_seed()
	gun = Gun.new(def["gun"])
	for a in def["armor"]:
		body.equip(a)
	s.noise.listen(_on_noise)


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


func _on_noise(pos: Vector3, radius: float, kind: String, src: Object) -> void:
	if body.dead or src is ScavBot or not is_inside_tree():
		return
	if global_position.distance_to(pos) <= radius:
		var shot := kind == "shot"
		percept.hear(pos, shot)
		if shot and not percept.seeing:  # F87: snap round to the shot so the view cone checks it now
			var d := _flat(pos - global_position)
			if d.length() > 0.05:
				rotation.y = atan2(-d.x, -d.z)
			if cover_t <= 0.0:
				_find_cover()


## Called by RangeFeedback with the Ballistics.body_hit dictionary.
func on_hit(res: Dictionary) -> void:
	hurt_t = 1.5
	if not _dying and not body.dead and def["overwatch"]:
		BotEngage.relocate(self)
	if not _dying:
		var target := session.nearest_player(global_position) if session != null else null
		percept.alert(target.node.global_position if target != null and target.node != null else res.get("origin", global_position))
	if body.dead:
		# Killing shot: throw the ragdoll along the bullet's travel direction, scaled by damage.
		var dir: Vector3 = (res["pos"] as Vector3) - (res["origin"] as Vector3)
		var scale := clampf(float(res.get("dmg", TacticalConfig.DEATH_IMPULSE_REF_DMG)) / TacticalConfig.DEATH_IMPULSE_REF_DMG, 0.25, 2.0)
		_die(dir.normalized() * TacticalConfig.DEATH_IMPULSE * scale, str(res.get("zone", "")))


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
	if to == "" and percept.noise_new and brain.state in [BotBrain.INVESTIGATE, BotBrain.SEARCH]:
		_go(percept.noise_pos)  # F87: a newer sound re-routes the bot
	percept.noise_new = false
	percept.shot_new = false
	if to != "":
		if from == BotBrain.HEAL and to == BotBrain.SEARCH:
			body.heal(0.4)
		shot_cover = to == BotBrain.COVER and from in [BotBrain.PATROL, BotBrain.INVESTIGATE]
		_enter(to)
		print("[bot] ", label_name, " ", from, " -> ", to)
		state_changed.emit(self, from, to)
	_act()


func _sense(dt: float) -> void:
	var target := session.nearest_player(global_position) if session != null else null
	var player := target.node if target != null else null
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
		BotBrain.ENGAGE:
			# F18: reaction delay before the first aimed shot of this engagement.
			var rc: Array = def.get("react", [0.5, 1.0])
			react_t = rng.randf_range(float(rc[0]), float(rc[1]))
			if percept.alerted():
				react_t *= BotPerception.ALERT_REACT_MULT
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
	elif s not in [BotBrain.ENGAGE, BotBrain.SUPPRESS] and gun.mag.count() < 10 and not gun.mag.is_full() and not gun.busy():
		gun.reload(false)
	if gun.needs_cycle and not gun.busy():
		gun.release()
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
	# F88: "finished" is judged in 3D and the navmesh sits 0.5 m up, so a bot at a path's end (target inside an
	# obstacle) never finished; being within 1 m of the path's end on the ground counts too.
	var at_end := nav != null and nav.get_current_navigation_path().size() > 1
	return routed and (nav.is_navigation_finished() or at_end) and _flat(global_position - nav.get_final_position()).length() < 1.0


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


func _move(dt: float) -> void:
	# A dead bot no longer drives its CharacterBody3D (its collision layer is 0, so move_and_slide
	# would sink the corpse through the floor); the ragdoll simulates in place instead. walk() is
	# still called so the ragdoll sleep timer ticks.
	if _dying:
		mesh.walk(dt, 0.0)
		return
	BotMotion.move(self, dt)


func _die(impulse := Vector3.ZERO, zone := "") -> void:
	if _dying:
		return
	_dying = true
	for z in rig:
		(rig[z] as CollisionObject3D).collision_layer = 0
	collision_layer = 0
	var tw := create_tween()
	mesh.die(impulse, zone)
	tw.tween_interval(8.5)
	tw.tween_callback(queue_free)
	died.emit(self)


## State needed to spawn this bot mid-session (MULTIPLAYER.md rule 6).
func to_dict() -> Dictionary:
	return {
		"kind": kind,
		"label": label_name,
		"pos": [global_position.x, global_position.y, global_position.z],
		"yaw": rotation.y,
		"body": body.to_dict(),
		"gun": gun.to_dict(),
		"patrol_i": patrol_i,
		"brain": brain.state,
	}


static func from_dict(d: Dictionary) -> ScavBot:
	var b := ScavBot.new()
	b.kind = str(d.get("kind", "rifleman"))
	b.def = BotDefs.of(b.kind)
	b.label_name = str(d.get("label", "Scav"))
	b.body = BodyHealth.from_dict(d.get("body", {}) as Dictionary)
	b.gun = Gun.from_dict(d.get("gun", {}) as Dictionary)
	b.patrol_i = int(d.get("patrol_i", 0))
	return b
