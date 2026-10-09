class_name CreatureAnim
## Runtime for Opus's skinned creature .glb files (ART3 track M).
## Model contract: `godot/assets/models/<id>.glb`, where <id> is the lower-case def
## name: "skitter", "brute", "spitter", "spore_bat", "gasbag", "wyvern", "soldier",
## "crawler", "core". One AnimationPlayer with clips `idle`, `walk` (looping, authored
## at 1 m/s ground speed), `attack`, `hit`, `die` (one-shots). The model faces +X,
## feet at y=0, authored at u=1; the caller scales it like the procedural mesh.
## A material named "glow" on the model is replaced with the caller's glow material.
## Everything is a safe no-op when there is no .glb: mesh makers fall back to the
## procedural meshes and death stays instant.

const MODEL_DIR := "res://assets/models/"
const WALK_SPEED := 1.0  # m/s the walk clip is authored at
const DIE_MAX := 1.5  # s before a death callback fires no matter what

## Blend states kept in the node's "_anim_state" meta.
const ST_IDLE := 0
const ST_WALK := 1
const ST_ATTACK := 2
const ST_HIT := 3
const ST_DIE := 4

static var _scenes := {}  # id -> PackedScene (only ids that have a .glb)


## "Spore Bat" -> "spore_bat", "Skitter" -> "skitter".
static func id_of(def_name: String) -> String:
	return def_name.strip_edges().to_lower().replace(" ", "_")


## Instance the model for `id`, scaled by `scale`, glow materials replaced.
## Returns null when there is no .glb (caller falls back to procedural).
static func make(id: String, scale: float, glow: Material) -> Node3D:
	if id.is_empty():
		return null
	if not _scenes.has(id):
		var path := MODEL_DIR + id + ".glb"
		if not ResourceLoader.exists(path):
			return null
		var ps := load(path) as PackedScene
		if ps == null:
			return null
		_scenes[id] = ps
	var node := (_scenes[id] as PackedScene).instantiate() as Node3D
	node.scale = Vector3.ONE * scale
	return _wrap(node, glow)


## Find the AnimationPlayer, remember it in meta, swap "glow" materials.
## Also used by tests to wrap a hand-built animated node.
static func _wrap(node: Node3D, glow: Material) -> Node3D:
	var player: AnimationPlayer = null
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n := stack.pop_back() as Node
		if n is AnimationPlayer:
			player = n
			break
		for c in n.get_children():
			stack.push_back(c)
	node.set_meta("_anim_player", player)
	node.set_meta("_anim_state", ST_IDLE)
	if glow != null:
		_replace_glow(node, glow)
	return node


static func _replace_glow(node: Node3D, glow: Material) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var cur: Material = (mi as MeshInstance3D).get_surface_override_material(i)
			if cur == null:
				cur = mesh.surface_get_material(i)
			if cur != null and cur.resource_name == "glow":
				(mi as MeshInstance3D).set_surface_override_material(i, glow)


static func _player(node: Node3D) -> AnimationPlayer:
	if node == null or not is_instance_valid(node) or not node.has_meta("_anim_player"):
		return null
	var p := node.get_meta("_anim_player") as AnimationPlayer
	return p if p != null and is_instance_valid(p) else null


static func _state(node: Node3D) -> int:
	return int(node.get_meta("_anim_state", ST_IDLE))


## Walk/idle blend from ground speed. Never stomps an attack/hit/die one-shot
## that is still playing; no-op on procedural nodes.
static func move(node: Node3D, speed_mps: float) -> void:
	var p := _player(node)
	if p == null:
		return
	var st := _state(node)
	if st >= ST_ATTACK and p.is_playing():
		return
	if speed_mps > 0.05:
		if st != ST_WALK or not p.is_playing():
			if p.has_animation("walk"):
				p.play("walk")
			elif p.has_animation("idle"):
				p.play("idle")
		p.speed_scale = clampf(speed_mps / WALK_SPEED, 0.2, 4.0)
		node.set_meta("_anim_state", ST_WALK)
	else:
		if st != ST_IDLE or not p.is_playing():
			if p.has_animation("idle"):
				p.play("idle")
		p.speed_scale = 1.0
		node.set_meta("_anim_state", ST_IDLE)


## One-shot attack swing. Re-trigger safe: won't restart a swing in progress.
static func attack(node: Node3D) -> void:
	_oneshot(node, "attack", ST_ATTACK)


## One-shot hit flinch. Re-trigger safe.
static func hit(node: Node3D) -> void:
	_oneshot(node, "hit", ST_HIT)


static func _oneshot(node: Node3D, clip: String, st: int) -> void:
	var p := _player(node)
	if p == null or not p.has_animation(clip):
		return
	if p.is_playing() and p.current_animation == clip:
		return
	p.speed_scale = 1.0
	p.play(clip)
	node.set_meta("_anim_state", st)


## Play the die clip, then call `then`. With no clip (procedural fallback),
## calls `then` at once. Never waits longer than DIE_MAX.
static func die(node: Node3D, then: Callable) -> void:
	var p := _player(node)
	if p == null or not p.has_animation("die") or not is_instance_valid(node):
		then.call()
		return
	node.set_meta("_anim_state", ST_DIE)
	node.set_meta("_die_fired", false)
	var fire := func() -> void:
		if not is_instance_valid(node):
			return
		if bool(node.get_meta("_die_fired", false)):
			return
		node.set_meta("_die_fired", true)
		then.call()
	p.speed_scale = 1.0
	p.animation_finished.connect(func(_clip: StringName) -> void: fire.call(), CONNECT_ONE_SHOT)
	p.play("die")
	var tree := node.get_tree()
	if tree != null:
		tree.create_timer(DIE_MAX).timeout.connect(func() -> void: fire.call())
