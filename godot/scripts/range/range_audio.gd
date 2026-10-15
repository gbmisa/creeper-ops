class_name RangeAudio
## Range-side sound player (the shared Sfx autoload and the RTS game are untouched). Recorded samples from SoundDefs
## through a pool of AudioStreamPlayer3D (positional: bots, thrown items) and AudioStreamPlayer (the player's own gun).
## Random pitch per play, the shot's tail is delayed by distance, and inside an indoor zone it goes through a reverb bus.

const POOL := 20
const ROOM_BUS := "RangeRoom"
const PITCH_JIT := 0.04
const SOUND_SPEED := 343.0

static var _root: Node
static var _p3: Array[AudioStreamPlayer3D] = []
static var _p2: Array[AudioStreamPlayer] = []
static var _n3 := 0
static var _n2 := 0
static var _cache := {}
static var _zones: Array[AABB] = []


static func add_zone(box: AABB) -> void:
	if not _zones.has(box):
		_zones.append(box)


static func indoor(pos: Vector3) -> bool:
	for z in _zones:
		if z.has_point(pos):
			return true
	return false


static func stream(stem: String) -> AudioStream:
	if stem == "":
		return null
	if not _cache.has(stem):
		_cache[stem] = load(SoundDefs.path(stem)) if ResourceLoader.exists(SoundDefs.path(stem)) else null
	return _cache[stem]


static func _setup() -> bool:
	if is_instance_valid(_root):
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	_root = Node.new()
	_root.name = "RangeAudio"
	tree.root.add_child(_root)
	if AudioServer.get_bus_index(ROOM_BUS) < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, ROOM_BUS)
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.55
		rv.damping = 0.5
		rv.wet = 0.3
		AudioServer.add_bus_effect(i, rv)
	_p3.clear()
	_p2.clear()
	for k in POOL:
		var a := AudioStreamPlayer3D.new()
		a.unit_size = 14.0
		a.max_distance = 220.0
		_root.add_child(a)
		_p3.append(a)
	for k in 6:
		var b := AudioStreamPlayer.new()
		_root.add_child(b)
		_p2.append(b)
	return true


## Plays a sample. pos == null: non-positional (the player's own sound). Returns false when nothing played.
static func play(stem: String, pos: Variant = null, db := 0.0, bus := "Master", pitch := 1.0) -> bool:
	var s := stream(stem)
	if s == null or not _setup():
		return false
	var jit := pitch * (1.0 + randf_range(-PITCH_JIT, PITCH_JIT))
	if pos == null:
		var b := _p2[_n2]
		_n2 = (_n2 + 1) % _p2.size()
		b.stream = s
		b.volume_db = db
		b.pitch_scale = jit
		b.bus = bus
		b.play()
		return true
	var a := _p3[_n3]
	_n3 = (_n3 + 1) % _p3.size()
	a.stream = s
	a.volume_db = db
	a.pitch_scale = jit
	a.bus = bus
	a.global_position = pos
	a.play()
	return true


## A gun report: shot (or suppressed shot) now, tail after the sound has travelled. Bots pass their muzzle position.
static func shot(gun_id: String, pos: Variant = null, suppressed := false, cal := "", cls := "") -> void:
	var prof: Dictionary = SoundDefs.PROFILES[SoundDefs.profile_of(gun_id, cal, cls)]
	var at: Vector3 = pos if pos != null else _listener()
	var room := indoor(at)
	var bus := ROOM_BUS if room else "Master"
	var db: float = prof["db"] - (6.0 if suppressed else 0.0)
	play(prof["sup"] if suppressed else prof["shot"], pos, db, bus)
	var dist := at.distance_to(_listener())
	var delay := clampf(0.05 + dist / SOUND_SPEED, 0.05, 0.7)
	var tail_db: float = prof["db"] - (14.0 if suppressed else 4.0) + (3.0 if room else 0.0) - minf(dist * 0.05, 8.0)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var tail: String = prof["tail"]
	tree.create_timer(delay).timeout.connect(func(): play(tail, pos, tail_db, bus))


static func gun(gun_id: String, ev: String, pos: Variant = null, cal := "", cls := "") -> bool:
	return play(SoundDefs.gun_event(gun_id, ev, cal, cls), pos, -2.0)


static func attach(att_id: String, ev: String) -> bool:
	return play(SoundDefs.ATTACH.get(att_id, {}).get(ev, ""), null, -4.0)


static func inventory(kind: String, ev: String) -> bool:
	return play(SoundDefs.INVENTORY.get(kind, SoundDefs.INVENTORY["gun"]).get(ev, ""), null, -6.0)


static func util(item: String, ev: String, pos: Variant = null) -> bool:
	return play(SoundDefs.UTILITY.get(item, {}).get(ev, ""), pos, -2.0)


static func med(item: String) -> bool:
	return play(SoundDefs.MEDS.get(item, "inv_cloth"), null, -4.0)


## The single entry point: an event dictionary {kind: shot|gun|attach|inventory|util|sample, item, ev, pos?, local?,
## suppressed?, cal?, cls?}. Gameplay emits these (the server would send the same dictionary to clients); local == true
## is the player's own sound (non-positional), otherwise it plays 3D at pos. No state is kept per player.
static func event(e: Dictionary) -> void:
	var pos: Variant = null if e.get("local", false) else e.get("pos")
	var item: String = e.get("item", "")
	match e.get("kind", ""):
		"shot":
			shot(item, pos, e.get("suppressed", false), e.get("cal", ""), e.get("cls", ""))
		"gun":
			gun(item, e["ev"], pos, e.get("cal", ""), e.get("cls", ""))
		"attach":
			attach(item, e["ev"])
		"inventory":
			inventory(item, e["ev"])
		"util":
			util(item, e["ev"], pos)
		"med":
			med(item)
		"sample":
			play(item, pos, e.get("db", 0.0))


static func _listener() -> Vector3:
	var tree := Engine.get_main_loop() as SceneTree
	var cam := tree.root.get_viewport().get_camera_3d() if tree != null and tree.root != null else null
	return cam.global_position if cam != null else Vector3.ZERO
