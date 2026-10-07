class_name Network
extends MeshInstance3D
## Energy network (CW3 style). Every pair of finished relaying nodes within link range is
## connected; packets take the SHORTEST path from the Command Node (Dijkstra). Non-relaying
## structures hang off their nearest finished relaying node. Cut a relay and everything
## that only routed through it goes dark.

var _prev := {}          # Structure -> upstream Structure (null for the node)
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
	return s.def.get("relays", false) and s.is_built() and not s.is_flying()


func rebuild(list: Array) -> void:
	_prev.clear()
	_len.clear()
	for s in list:
		s.connected = false
	var root: Structure = null
	for s in list:
		if s.type == "node" and not s.is_flying():
			root = s
	var edges := []  # [a, b] pairs to draw
	if root:
		var dist := { root: 0.0 }
		_prev[root] = null
		var open := [root]
		var relays := list.filter(func(s): return _relaying(s) and s != root)
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
	for s in list:
		if not s.def.get("needs_network", true):
			s.connected = true
	_draw(edges)


func _draw(edges: Array) -> void:
	_imesh.clear_surfaces()
	if edges.is_empty():
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		_imesh.surface_add_vertex(e[0].link_point())
		_imesh.surface_add_vertex(e[1].link_point())
	_imesh.surface_end()


## Points a packet visits from the node to `s` (inclusive), or empty if unreachable.
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


## Metres a packet travels from the node to `s` (0 if unreachable).
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
