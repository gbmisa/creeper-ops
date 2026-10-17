class_name ArrowFx
extends Node
## F146: arrows and bolts you can see and pick up. A shaft mesh follows each arrow in flight (nose along its velocity);
## on a world hit it stays stuck there (a frozen WorldItem, so the usual use prompt takes it back, same grade).
## Cap MAX_STUCK per scene (oldest removed). An arrow that hits a Scav goes into that bot's loot and drops with the body.
## Meshes: arrow.glb / bolt.glb (build_mesh is the one place that builds them).

const MAX_STUCK := 60
const HIDE_NEAR := 0.04   # s: no mesh for the first moments (it would fill the screen from the eye)

var weapons: PlayerWeapons
var bal: Ballistics
var world_items: WorldItems
var _flying := {}      # fx_id -> Node3D
var _stuck: Array = []  # item dicts of stuck arrows, oldest first
var _bot_arrows := {}   # ScavBot -> {ammo id: count}
var _next_id := 1
var rng := RandomNumberGenerator.new()


func setup(w: PlayerWeapons, b: Ballistics, items: WorldItems) -> void:
	weapons = w
	bal = b
	world_items = items
	w.shot.connect(_on_shot)
	b.impact.connect(_on_impact)
	b.body_hit.connect(_on_body)


static func is_arrow(ammo_id: String) -> bool:
	return ammo_id in TacAmmoDefs.ROWS and TacAmmoDefs.ROWS[ammo_id]["cal"] in ["arrow", "bolt"]


## The arrow / bolt, tip at the origin, trailing along +Z (so -Z is the flight direction). arrow.glb / bolt.glb
## (scratch models, centred on their bbox) are shifted back by half their length; LEN holds those lengths.
const LEN := {"arrow": 0.765, "bolt": 0.52}


static func build_mesh(ammo_id: String) -> Node3D:
	var root := Node3D.new()
	var cal: String = TacAmmoDefs.ROWS[ammo_id]["cal"]
	var m := (load("res://assets/models/guns/%s.glb" % cal) as PackedScene).instantiate() as Node3D
	m.position.z = LEN[cal] * 0.5
	root.add_child(m)
	return root


static func _basis(dir: Vector3) -> Basis:
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.RIGHT
	return Basis.looking_at(dir.normalized(), up)


func _on_shot(res: Dictionary, g: Gun) -> void:
	if not res["fired"] or not BowDefs.is_loose(g.def) or bal.shots.is_empty():
		return
	var s: Dictionary = bal.shots.back()
	if not is_arrow(s["ammo"]["id"]):
		return
	s["fx_id"] = _next_id
	var m := build_mesh(s["ammo"]["id"])
	m.visible = false
	add_child(m)
	_flying[_next_id] = m
	_next_id += 1


func _process(_dt: float) -> void:
	if not _flying.is_empty():
		var live := {}
		for s in bal.shots:
			if s.has("fx_id"):
				live[s["fx_id"]] = s
		for id in _flying.keys():
			var m: Node3D = _flying[id]
			if not live.has(id):   # flew out of range without hitting anything
				m.queue_free()
				_flying.erase(id)
				continue
			var s: Dictionary = live[id]
			m.visible = s["age"] > HIDE_NEAR
			m.global_transform = Transform3D(_basis(s["vel"]), s["pos"])
	_bot_loot_tick()


func _on_impact(info: Dictionary) -> void:
	if info["kind"] != "stop" or not is_arrow(info["ammo"]):
		return
	_drop_flying(info["fx_id"])
	_stick(info["ammo"], info["pos"], info["dir"])


func _on_body(info: Dictionary) -> void:
	if not is_arrow(info["ammo"]):
		return
	_drop_flying(info["fx_id"])
	var bot = info.get("owner")
	if bot is ScavBot:
		var have: Dictionary = _bot_arrows.get(bot, {})
		have[info["ammo"]] = int(have.get(info["ammo"], 0)) + 1
		_bot_arrows[bot] = have
	else:
		_stick(info["ammo"], info["pos"], info["dir"])


func _drop_flying(id: int) -> void:
	if _flying.has(id):
		(_flying[id] as Node).queue_free()
		_flying.erase(id)


## A stuck arrow: a frozen WorldItem holding one arrow of the grade, the mesh nose-first into the surface.
func _stick(ammo_id: String, pos: Vector3, dir: Vector3) -> void:
	RangeAudio.event({"kind": "sample", "item": "arrow_thud", "pos": pos, "db": -4.0})
	var it := weapons.inv.make(ammo_id, {"count": 1})
	var wi := world_items.drop(it, pos - dir.normalized() * 0.15)
	wi.freeze = true
	wi.collision_layer = 0
	for c in wi.get_children():
		if c is MeshInstance3D or c is Label3D:
			c.visible = false
	var m := build_mesh(ammo_id)
	wi.add_child(m)
	m.global_transform = Transform3D(_basis(dir), pos)
	_stuck = _stuck.filter(func(x): return world_items.items.has(x))   # picked-up ones are gone
	_stuck.append(it)
	while _stuck.size() > MAX_STUCK:
		world_items.release(_stuck.pop_front())


## Arrows in a Scav's body come out when it dies (they lie by the corpse, stacked by grade).
func _bot_loot_tick() -> void:
	for bot in _bot_arrows.keys():
		if not is_instance_valid(bot):
			_bot_arrows.erase(bot)
		elif bot.body.dead:
			for ammo_id in _bot_arrows[bot]:
				var at: Vector3 = bot.global_position + Vector3(rng.randf_range(-0.3, 0.3), 0.4, rng.randf_range(-0.3, 0.3))
				world_items.drop(weapons.inv.make(ammo_id, {"count": int(_bot_arrows[bot][ammo_id])}), at)
			_bot_arrows.erase(bot)
