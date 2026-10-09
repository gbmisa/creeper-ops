class_name UnitManager
extends Node3D
## Soldiers and Crawlers: spawning from barracks, selection, group move orders (A* paths
## spread into a formation), movement with climb limits, and bars. Combat, creeper damage and
## the go-home-to-resupply loop live in unit_supply.gd. Units can never trigger objectives.

var world: World
var structures: StructureManager
var list: Array[Unit] = []
var selected: Array[Unit] = []
var castles: Strongholds = null   # injected: units from a barracks in a held castle garrison it
var lines := PatrolLines.new()


func setup(w: World, sm: StructureManager) -> void:
	name = "Units"
	world = w
	structures = sm
	lines.mgr = self
	add_child(lines)
	Bus.unit_trained.connect(_on_trained)
	Bus.terrain_changed.connect(func(cw, _cells):  # re-path anyone walking a stale route
		if cw == world:
			for u in list:
				if not u.path.is_empty():
					walk_to(u, u.path.back()))
	Bus.structure_removed.connect(func(s):
		for u in list:
			if u.home == s:
				u.home = null)


func living_for(b: Structure) -> int:
	return list.filter(func(u): return u.home == b).size()


func _on_trained(type: String, b: Structure) -> void:
	var sc := _free_cell(world.grid.world_to_cell(b.pos.x, b.pos.z + 4.2))
	var sx := (sc.x + 0.5) * Config.CELL + randf_range(-0.6, 0.6)
	var sz := (sc.y + 0.5) * Config.CELL + randf_range(-0.6, 0.6)
	var u := spawn(type, sx, sz)
	u.home = b
	var rally: Vector3 = b.rally if b.rally != null else b.pos + Vector3(randf_range(-3, 3), 0, 9)
	order([u], Vector2(rally.x, rally.z))
	UnitPatrol.auto_castle(self, u, b.pos)
	Bus.say("%s ready (%d/%d at this barracks)." % [u.def.label, living_for(b), Config.UNITS_PER_BARRACKS], "good")


## Nearest free cell to `prefer` (spiral search), so units never spawn or walk into
## an occupied cell. Falls back to `prefer` when everything nearby is blocked.
func _free_cell(prefer: Vector2i) -> Vector2i:
	var g := world.grid
	if g.in_bounds(prefer.x, prefer.y) and not world.occupied.call(prefer.x, prefer.y):
		return prefer
	for ring in range(1, 6):
		for dz in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var c := Vector2i(prefer.x + dx, prefer.y + dz)
				if g.in_bounds(c.x, c.y) and not world.occupied.call(c.x, c.y):
					return c
	return prefer


func spawn(type: String, x: float, z: float) -> Unit:
	var u := Unit.new(type)
	u.node = Node3D.new()
	var mesh := UnitMeshes.make(type)
	mesh.name = "Mesh"
	u.node.add_child(mesh)
	u.ring = UnitMeshes.selection_ring(u.def.radius)
	u.node.add_child(u.ring)
	var big := type == "crawler"
	u.hp_bar = Bar.new(1.8 if big else 1.1, 2.2 if big else 2.0)
	u.ammo_bar = Bar.new(1.8 if big else 1.1, (2.2 if big else 2.0) - 0.22)
	u.node.add_child(u.hp_bar)
	u.node.add_child(u.ammo_bar)
	add_child(u.node)
	u.pos = Vector3(x, world.grid.stand_y(x, z, Grid.Faction.PLAYER), z)
	u.prey = { "kind": "unit", "node": u.node, "radius": u.def.radius, "alive": func(): return u.alive, "hit": func(d): damage(u, d) }
	list.append(u)
	return u


## Group move: spiral destinations so they don't stack. Player orders set the unit's post.
func order(units: Array, dest: Vector2, player := false) -> void:
	for i in units.size():
		var u: Unit = units[i]
		var a := i * 2.4
		var r := 0.0 if i == 0 else 1.4 * sqrt(i)
		var goal := dest + Vector2(cos(a), sin(a)) * r
		walk_to(u, goal)
		u.post = goal
		u.patrol = []  # any move order cancels a patrol
		if u.state != "resupply" or player:
			u.state = "move"
	if not units.is_empty():
		Sfx.play("click")


func walk_to(u: Unit, goal: Vector2) -> void:
	var g := world.grid
	var from := g.world_to_cell(u.pos.x, u.pos.z)
	var gc := g.world_to_cell(goal.x, goal.y)
	if world.occupied.call(gc.x, gc.y):
		# Goal inside a structure (e.g. rally set on the barracks): step to the
		# nearest free cell instead of pushing against the wall forever.
		var nc := _free_cell(gc)
		goal = Vector2((nc.x + 0.5) * Config.CELL, (nc.y + 0.5) * Config.CELL)
	var start := from
	var prefix: Array[Vector2] = []
	if world.occupied.call(from.x, from.y):
		# Pathfind can't start inside a solid block (every neighbour is solid):
		# step out to the nearest free cell first. _move allows leaving an
		# occupied cell, so the prefix walks out through the wall.
		var nc := _free_cell(from)
		if nc == from:
			u.path = []
			return
		prefix = [Vector2((nc.x + 0.5) * Config.CELL, (nc.y + 0.5) * Config.CELL)]
		start = nc
	var found := Pathfind.find(g, world.creeper, start, g.world_to_cell(goal.x, goal.y), u.def, 6000, world.occupied)
	u.path = prefix
	u.path.append_array(found)
	if not u.path.is_empty():
		u.path[u.path.size() - 1] = goal


## Backstop: a unit whose path ran out while standing inside an occupied cell
## (boxed in by new construction, spawned on a blocked cell) re-paths out once
## instead of idling inside the obstacle forever. Returns true if it re-pathed.
func unstick(u: Unit) -> bool:
	if u.post == null:
		return false
	var g := world.grid
	var c := g.world_to_cell(u.pos.x, u.pos.z)
	if not world.occupied.call(c.x, c.y):
		return false
	walk_to(u, u.post)
	return not u.path.is_empty()


func damage(u: Unit, amount: float) -> void:
	if not u.alive:
		return
	u.hp -= amount
	u.hurt = 0.2
	if u.hp <= 0.0:
		kill(u)
	else:
		CreatureAnim.hit(u.node.get_node("Mesh"))


func kill(u: Unit) -> void:
	u.alive = false
	world.effects.burst(u.pos + Vector3.UP, Color("ff7744"), 2.0, 0.4)
	u.node.queue_free()
	selected.erase(u)
	list.erase(u)
	Sfx.play("lost", u.pos)
	Bus.say("%s lost." % u.def.label, "bad")


func select(units: Array, additive := false) -> void:
	if not additive:
		selected.clear()
	for u in units:
		if not selected.has(u):
			selected.append(u)
	for u in list:
		u.ring.visible = selected.has(u)


func update(dt: float, enemies: Array) -> void:
	for u in list.duplicate():
		if (u.state == "move" or u.state == "return" or u.state == "patrol") and not u.path.is_empty() and u.ammo >= 1.0:
			# Attack-move: hold the route and fight anything already in gun range.
			# No chasing — the unit never leaves its path for a target. Dry units
			# keep walking (their retreat is handled in UnitSupply.update).
			u.engaged = not UnitSupply.acquire(u, enemies).is_empty()
		else:
			u.engaged = false
		if u.engaged:
			# Stand and fight: idle the walk clip instead of freezing mid-stride.
			CreatureAnim.move(u.node.get_node("Mesh"), 0.0)
		else:
			_move(u, dt)
		UnitSupply.update(self, u, dt, enemies)
		if u.alive:
			_sync(u)


func _move(u: Unit, dt: float) -> void:
	var g := world.grid
	var v := Vector2.ZERO
	if not u.path.is_empty():
		var wp: Vector2 = u.path[0]
		var d := wp - Vector2(u.pos.x, u.pos.z)
		if d.length() < 0.5:
			u.path.pop_front()
		else:
			v = d.normalized()
			u.heading = atan2(-d.y, d.x)
	for o in list:  # separation so groups don't clump into one mesh
		if o == u:
			continue
		var d := Vector2(u.pos.x - o.pos.x, u.pos.z - o.pos.z)
		var mn: float = u.def.radius + o.def.radius + 0.3
		if d.length() > 0.001 and d.length() < mn:
			v += d.normalized() * (mn - d.length()) * 2.0
	var wet := world.creeper.depth_world(u.pos) > Config.DAMAGE_DEPTH
	var step: float = u.def.speed * (0.6 if wet else 1.0) * dt
	var nx := u.pos.x + v.x * step
	var nz := u.pos.z + v.y * step
	var a := g.world_to_cell(u.pos.x, u.pos.z)
	var b := g.world_to_cell(nx, nz)
	var rise := g.walk_height(b.x, b.y, Grid.Faction.PLAYER) - g.walk_height(a.x, a.y, Grid.Faction.PLAYER)
	var p := u.pos
	var into_tower: bool = b != a and world.occupied.call(b.x, b.y) and not world.occupied.call(a.x, a.y)
	if g.in_bounds(b.x, b.y) and rise <= u.def.climb and -rise <= u.def.drop and not into_tower:
		p.x = nx
		p.z = nz
	p.y = g.stand_y(p.x, p.z, Grid.Faction.PLAYER)
	u.pos = p
	CreatureAnim.move(u.node.get_node("Mesh"), v.length() * u.def.speed)


func _sync(u: Unit) -> void:
	(u.node.get_node("Mesh") as Node3D).rotation.y = u.heading
	var f: float = u.hp / u.def.hp
	var show: bool = f < 0.999 or selected.has(u) or u.ammo < u.def.ammo
	u.hp_bar.visible = show
	u.ammo_bar.visible = show
	u.hurt = maxf(0.0, u.hurt - 1.0 / 60.0)
	u.hp_bar.set_value(f, Color.WHITE if u.hurt > 0.0 else Bar.hp_color(f))
	u.ammo_bar.set_value(u.ammo / u.def.ammo, Color("ff3030") if u.ammo < 1.0 else Color("ffb13b"))


## Unit near a world point (click-select).
func nearest(p: Vector3, max_dist := 1.8) -> Unit:
	var best: Unit = null
	var bd := max_dist
	for u in list:
		var d := Vector2(u.pos.x - p.x, u.pos.z - p.z).length()
		if d < bd:
			bd = d
			best = u
	return best
