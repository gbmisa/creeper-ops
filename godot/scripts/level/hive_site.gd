class_name HiveSite
## Blight, the anchor node, and rebuilding a razed hive (§3.3). Split from hives.gd so each file
## stays short. Three raiders inside HIVE_REBUILD_RANGE for HIVE_REBUILD_TIME restore it one
## stage lower. A player structure in that range blocks them; an Outpost on the Core cell
## is the outpost state and is also that blocker.


static func tick(host, hive: Dictionary, dt: float) -> void:
	if str(hive.state) == "active":
		return
	_watch(host, hive)
	if _blocked(host, hive) or _near(host, hive) < Config.HIVE_REBUILD_NEED:
		hive.rebuild_t = 0.0
		return
	hive.rebuild_t = float(hive.rebuild_t) + dt
	if float(hive.rebuild_t) >= Config.HIVE_REBUILD_TIME:
		_restore(host, hive)


static func _watch(host, hive: Dictionary) -> void:
	if host.structures == null:
		return
	var s: Structure = host.structures.structure_at(int(hive.x), int(hive.z))
	if s != null and not s.dead and s.type == "outpost":
		hive.state = "outpost"
	elif str(hive.state) == "outpost":
		hive.state = "razed"


static func _blocked(host, hive: Dictionary) -> bool:
	if host.structures == null:
		return false
	for s in host.structures.list:
		var st: Structure = s
		if st.dead:
			continue
		if Vector2(st.x - int(hive.x), st.z - int(hive.z)).length() <= Config.HIVE_REBUILD_RANGE:
			return true
	return false


static func _near(host, hive: Dictionary) -> int:
	var n := 0
	for r in host.raiders.list:
		var row: Dictionary = r
		if not row.alive:
			continue
		var node := row.node as Node3D
		var c: Vector2i = host.world.grid.world_to_cell(node.position.x, node.position.z)
		if Vector2(c.x - int(hive.x), c.y - int(hive.z)).length() <= Config.HIVE_REBUILD_RANGE:
			n += 1
	return n


static func _restore(host, hive: Dictionary) -> void:
	_crush(host, hive)
	var back := maxi(1, int(hive.stage) - 1)
	hive.parts = []
	hive.stage = 0
	hive.boosted = false
	hive.state = "active"
	hive.alive = true
	hive.rebuild_t = 0.0
	anchor(host, hive)
	zone(host, hive, true)
	Hives.unlock_to(host, hive, back)
	for part in hive.parts:
		var p: Dictionary = part
		p.grown = true
		p.grow = 0.0
		var node := p.get("node") as Node3D
		if node != null and is_instance_valid(node):
			node.scale = Vector3.ONE
	Bus.say("%s is growing back (stage %d)." % [str(hive.name), back], "bad")


static func _crush(host, hive: Dictionary) -> void:
	if host.structures == null:
		return
	var sm: StructureManager = host.structures
	for s in sm.list.duplicate():
		var st: Structure = s
		if st.dead:
			continue
		if Vector2(st.x - int(hive.x), st.z - int(hive.z)).length() <= Config.HIVE_RADIUS:
			sm.remove(st, "destroyed")


static func zone(host, hive: Dictionary, on: bool) -> void:
	var g: Grid = host.world.grid
	for c in hive.blight:
		var cell := c as Vector2i
		if g.in_bounds(cell.x, cell.y):
			g.zone[g.idx(cell.x, cell.y)] = Grid.Zone.BLIGHT if on else Grid.Zone.NONE
	if on:
		return
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x := int(hive.x) + dx
			var z := int(hive.z) + dz
			if not g.in_bounds(x, z):
				continue
			var i := g.idx(x, z)
			g.zone[i] = Grid.Zone.NONE
			g.blocked[i] = 0


static func anchor(host, hive: Dictionary) -> void:
	var node := hive.get("node") as Node3D
	if node != null and is_instance_valid(node):
		return
	node = HiveMeshes.anchor()
	hive["node"] = node
	hive["pos"] = host.world.place_at(node, int(hive.x), int(hive.z))


static func drop_anchor(hive: Dictionary) -> void:
	var node := hive.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.queue_free()
	hive["node"] = null
