class_name Loot
## Salvage pickups (§4.4). A glowing orb lasts LOOT_LIFE seconds.
## Only the Operative collects one, by standing within LOOT_RANGE metres.
## Raider amounts come from RaiderDefs. Hive parts, crown nests and the Core use Config.


static var live: Array[Dictionary] = []
static var _mesh: SphereMesh


static func amount_for(tier: Dictionary, roll: float) -> float:
	if roll >= float(tier.get("loot_p", 0.0)):
		return 0.0
	return maxf(0.0, float(tier.get("loot", 0.0)))


static func from_raider(host, r: Dictionary) -> void:
	var node: Node3D = r.get("node") as Node3D
	if host == null or node == null or not is_instance_valid(node):
		return
	var n := amount_for(r.tier, randf())
	if n <= 0.0:
		return
	drop(host.world, node.position, n, host.stockpile, host.operative)


static func drop(world: World, pos: Vector3, amount: float, stockpile: Stockpile, who: Callable) -> Dictionary:
	if world == null or stockpile == null or amount <= 0.0:
		return {}
	var root := Node3D.new()
	root.name = "Salvage"
	var orb := MeshInstance3D.new()
	orb.mesh = _sphere()
	orb.material_override = Effects.glow_mat(Color("ffd36a"))
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orb.position.y = 0.55
	root.add_child(orb)
	root.position = pos
	world.add_child(root)
	var item := { "node": root, "pos": pos, "amount": amount, "life": Config.LOOT_LIFE, "alive": true }
	var marker := {
		"pos": pos + Vector3(0, 1.2, 0), "color": Color("ffd36a"), "minor": true,
		"label": "Salvage %d" % int(round(amount)),
		"visible": func(): return bool(item.alive),
	}
	item["marker"] = marker
	world.markers.append(marker)
	var tick: Callable = func(dt: float) -> void:
		_tick(world, item, stockpile, who, dt)
	item["tick"] = tick
	world.updaters.append(tick)
	live.append(item)
	return item


static func find(pos: Vector3, amount: float) -> Dictionary:
	for item in live:
		if not bool(item.alive):
			continue
		var p: Vector3 = item.pos
		if absf(float(item.amount) - amount) < 0.01 and Vector2(p.x - pos.x, p.z - pos.z).length() <= 1.0:
			return item
	return {}


static func holding(pos: Vector3, amount: float) -> bool:
	return not find(pos, amount).is_empty()


static func _tick(world: World, item: Dictionary, stockpile: Stockpile, who: Callable, dt: float) -> void:
	if not bool(item.alive):
		return
	item.life = float(item.life) - dt
	var node: Node3D = item.get("node") as Node3D
	if node != null and is_instance_valid(node) and node.get_child_count() > 0:
		(node.get_child(0) as Node3D).position.y = 0.55 + sin((Config.LOOT_LIFE - float(item.life)) * 3.0) * 0.1
	var feet: Variant = _feet(who)
	if feet is Vector3 and (feet as Vector3).distance_to(item.pos) <= Config.LOOT_RANGE:
		_finish(world, item, stockpile, true)
		return
	if float(item.life) <= 0.0:
		_finish(world, item, stockpile, false)


static func _feet(who: Callable) -> Variant:
	if not who.is_valid():
		return null
	var body: Variant = who.call()
	if body == null:
		return null
	if body is FpsMode:
		var fps: FpsMode = body as FpsMode
		if fps.world == null:
			return null
		return fps.controller.pos
	if body is PlayerController:
		return (body as PlayerController).pos
	return null


static func _finish(world: World, item: Dictionary, stockpile: Stockpile, take: bool) -> void:
	if not bool(item.alive):
		return
	item.alive = false
	if take:
		stockpile.add("salvage", float(item.amount))
		Bus.say("Salvage +%s" % String.num(float(item.amount), 0), "good")
		world.effects.burst(item.pos + Vector3(0, 0.6, 0), Color("ffd36a"), 0.8, 0.25)
	var node: Node3D = item.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.queue_free()
	world.markers.erase(item.marker)
	world.updaters.erase(item.tick)
	for i in range(live.size() - 1, -1, -1):
		if live[i] == item:
			live.remove_at(i)
			break


static func _sphere() -> SphereMesh:
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 0.22
		_mesh.height = 0.44
		_mesh.radial_segments = 10
		_mesh.rings = 5
	return _mesh
