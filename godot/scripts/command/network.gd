class_name Network
extends MeshInstance3D
## Energy network. Every pair of relaying nodes within link range is connected, and
## planned (unfinished) relays relay too, so a chain you just laid out carries packets
## along the shortest path immediately. Dijkstra starts at every built sender that is
## not flying, all at distance 0; planned relays never send, they only relay.
## Non-relaying structures hang off their nearest relaying node. Cut a relay, built or
## planned, and everything that only routed through it goes dark.

var _prev := {}          # Structure -> upstream Structure (null for a sender)
var _len := {}           # Structure -> route length in metres (packet transit distance)
var _imesh := ImmediateMesh.new()


func _init() -> void:
	name = "Network"
	mesh = _imesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.5, 0.88, 1.0, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _dist(a: Structure, b: Structure) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func linked(a: Structure, b: Structure) -> bool:
	return _dist(a, b) <= maxf(a.def.link, b.def.link)


static func _relaying(s: Structure) -> bool:
	# Planned (unfinished) relays relay too: a chain you just laid out carries packets
	# along the shortest path immediately, matching in_range/cover_discs which already
	# count planned relays. They are never senders (see _sender) and never count as built.
	return s.def.get("relays", false) and not s.is_flying() and not s.dead


static func _sender(s: Structure) -> bool:
	return s.def.get("sender", false) and s.is_built() and not s.is_flying()


func rebuild(list: Array) -> void:
	_prev.clear()
	_len.clear()
	for s in list:
		s.connected = false
	var roots := []
	for s in list:
		if _sender(s):
			roots.append(s)
	var edges := []  # [a, b] pairs to draw
	if not roots.is_empty():
		var dist := {}
		var open := []
		for root in roots:
			dist[root] = 0.0
			_prev[root] = null
			open.append(root)
		var relays := list.filter(func(s): return _relaying(s) and not _sender(s))
		while not open.is_empty():
			open.sort_custom(func(a, b): return dist[a] < dist[b])
			var a: Structure = open.pop_front()
			a.connected = true
			for b in relays:
				if not linked(a, b):
					continue
				var nd: float = dist[a] + _dist(a, b)
				if nd < dist.get(b, INF):
					dist[b] = nd
					_prev[b] = a
					if not open.has(b):
						open.append(b)
		for b in _prev.keys():
			if _prev[b] != null:
				edges.append([_prev[b], b])
		# Leaves (incl. unfinished relays): nearest connected relaying node in range.
		for s in list:
			if s.connected or s.def.link <= 0.0 or s.is_flying():
				continue
			var best: Structure = null
			var bd := INF
			for n in list:
				if n.connected and _relaying(n):
					var d := _dist(n, s)
					if d <= maxf(n.def.link, s.def.link) and d < bd:
						bd = d
						best = n
			if best:
				s.connected = true
				_prev[s] = best
				edges.append([best, s])
	for s in _prev.keys():
		var r := route(s)
		var m := 0.0
		for i in range(1, r.size()):
			m += r[i - 1].distance_to(r[i])
		_len[s] = m
	_hold_flying_node(list, edges)
	for s in list:
		if not s.def.get("needs_network", true):
			s.connected = true
	_draw(edges)


## A flying Command Node keeps its network: everything it reached from the cell it lifted off
## stays connected (collectors keep claiming, weapons keep firing from stock) and its links
## follow it. While connected it is a packet sender (launching from where it hovers) and
## produces nothing; an Outpost or castle keep still supplies whatever it reaches.
func _hold_flying_node(list: Array, edges: Array) -> void:
	var node: Structure = null
	for s in list:
		if s.type == "node" and s.is_flying() and s.is_built():
			node = s
	if node == null:
		return
	var from: Vector2i = node.flight.get("from_cell", Vector2i(node.x, node.z))
	node.connected = true
	if not _prev.has(node):
		_prev[node] = null
	var seen := { node: true }
	var open: Array = [node]
	while not open.is_empty():
		var a: Structure = open.pop_back()
		for b in list:
			if seen.has(b) or not _relaying(b):
				continue
			var near: bool = Vector2(b.x - from.x, b.z - from.y).length() <= maxf(node.def.link, b.def.link) \
				if a == node else linked(a, b)
			if not near:
				continue
			seen[b] = true
			open.append(b)
			_hold_link(a, b)
			if a == node or not b.connected:
				edges.append([a, b])
			b.connected = true
	for s in list:  # leaves hang off the nearest relaying node it kept
		if s.connected or s.def.link <= 0.0 or s.is_flying():
			continue
		for n in seen:
			if n != node and _dist(n, s) <= maxf(n.def.link, s.def.link):
				s.connected = true
				edges.append([n, s])
				_hold_link(n, s)
				break


## Route `b` through `a` unless a grounded sender already reaches it.
func _hold_link(a: Structure, b: Structure) -> void:
	if _prev.has(b):
		return
	_prev[b] = a
	var r := route(b)
	var m := 0.0
	for i in range(1, r.size()):
		m += r[i - 1].distance_to(r[i])
	_len[b] = m


func _draw(edges: Array) -> void:
	_imesh.clear_surfaces()
	if edges.is_empty():
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		_imesh.surface_add_vertex(e[0].link_point())
		_imesh.surface_add_vertex(e[1].link_point())
	_imesh.surface_end()


## Points a packet visits from the nearest sender to `s` (inclusive), or empty if unreachable.
func route(s: Structure) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not _prev.has(s):
		return out
	var chain := []
	var n: Structure = s
	while n != null:
		chain.push_front(n)
		n = _prev.get(n)
	for c in chain:
		out.append(c.link_point())
	return out


## Metres a packet travels from the nearest sender to `s` (0 if unreachable).
func route_length(s: Structure) -> float:
	return _len.get(s, 0.0)


## Could a structure at (x, z) with this link radius join the network? As in CW3, planned
## (unfinished) collectors and relays count too, so you can lay out a whole chain at once;
## each link builds as soon as the one before it is finished.
func in_range(list: Array, x: int, z: int, link: float, ignore: Structure) -> bool:
	for n in list:
		var planned: bool = n.def.get("relays", false) and not n.is_built() and not n.is_flying()
		if n != ignore and ((n.connected and _relaying(n)) or planned):
			if Vector2(n.x - x, n.z - z).length() <= maxf(n.def.link, link):
				return true
	return false


## Connected relaying nodes, for the shader's network-cover overlay: Vector4(x, z, r, 0).
func cover_discs(list: Array) -> Array[Vector4]:
	var out: Array[Vector4] = []
	for n in list:
		var planned: bool = n.def.get("relays", false) and not n.is_built()
		if ((n.connected and _relaying(n)) or planned) and out.size() < 96:
			out.append(Vector4(n.pos.x, n.pos.z, n.def.link * Config.CELL, 0))
	return out
