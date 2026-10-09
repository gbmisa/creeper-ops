class_name Packets
extends MultiMeshInstance3D
## Packet dispatcher, CW3 rules: energy IS packets. The nearest sender launches a packet the
## moment a structure requests one AND the bank holds >= 1 energy. There is no global launch
## cap. One flying Node does not stop launches while another sender is ready. Throughput is
## limited only by income, the bank, and each structure's request rate
## (Config.REQ_BUILD / REQ_AMMO / REQ_UNIT / REQ_TERP). Requests the bank can't pay are counted as unmet
## demand so the HUD can show the red number the way CW3 does. No priority: requesters are
## served round robin, ammo and builds alike.
## Return packets (kind "ore" or "salvage") fly route() reversed and credit the Stockpile.
## They cost no energy. One already in flight still arrives if its source is gone.

const MAX_VISIBLE := 1200
const COLORS := { "build": Color("e8fbff"), "ammo": Color("ffb13b"), "unit": Color("9dff7a"), "terp": Color("e2b15a"),
	"ore": Color("e0a24a"), "salvage": Color("7dff9a") }

var network: Network
var economy: Economy
var stockpile: Stockpile
var flying: Array[Dictionary] = []
var _cursor := 0
var _node_atk := {}  # structure id -> last launch-attack msec (0.5 s rate limit)
var _structs: Array = []  # latest structure list, for relay pass-through (A4)

# Rolling stats (packets/s) for the HUD.
var sent_rate := 0.0
var demand_rate := 0.0
var unmet_rate := 0.0


func setup(net: Network, eco: Economy) -> void:
	network = net
	economy = eco
	name = "Packets"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = MAX_VISIBLE
	mm.visible_instance_count = 0
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	sphere.radial_segments = 8
	sphere.rings = 4
	mm.mesh = sphere
	multimesh = mm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func transit_headroom(s: Structure) -> float:
	return PacketRequests.transit_headroom(network, s)


func need(s: Structure) -> String:
	return PacketRequests.need(network, s)


static func speed() -> float:
	return PacketRequests.speed()


static func rate(kind: String) -> float:
	return PacketRequests.rate(kind)


func update(dt: float, list: Array, sender_ready: bool) -> void:
	_structs = list  # A4: relay pass-through lookup for the packet attack clip
	var sent := 0
	var wanted := 0.0
	var unmet := 0.0
	if sender_ready and not list.is_empty():
		var n := list.size()
		for s in list:  # every requester builds up its request at its own rate
			var kind := need(s)
			if kind == "":
				s.req_acc = 0.0
				continue
			var r := rate(kind)
			wanted += r * dt
			s.req_acc = minf(s.req_acc + r * dt, 2.0)
		# Round robin with no priority: one packet per requester per turn, ammo and builds
		# alike, resuming after the last one served, until the bank or the requests run out.
		var served := true
		while served:
			served = false
			var base := _cursor
			for k in n:
				var i := (base + k) % n
				var s: Structure = list[i]
				if s.req_acc < 1.0:
					continue
				var kind := need(s)
				if kind == "":
					continue
				if economy.energy < 1.0:
					break
				var route := network.route(s)
				if route.is_empty():
					continue
				economy.energy -= 1.0
				s.req_acc -= 1.0
				s.in_flight += 1
				sent += 1
				served = true
				_cursor = (i + 1) % n
				var fly := { "s": s, "kind": kind, "route": route, "seg": 0, "t": 0.0 }
				if kind == "ammo":
					fly["grade"] = AmmoGrades.surcharge(s, stockpile)  # Salvage surcharge for improved ammo
				flying.append(fly)
				_node_launch_anim(list, route)
		if economy.energy < 1.0:
			for s in list:
				if s.req_acc >= 1.0 and need(s) != "":
					unmet += rate(need(s)) * dt
	if dt > 0.0:
		var k := clampf(dt / Config.STAT_WINDOW, 0.0, 1.0)
		sent_rate = lerpf(sent_rate, sent / dt, k)
		demand_rate = lerpf(demand_rate, wanted / dt, k)
		unmet_rate = lerpf(unmet_rate, unmet / dt, k)
	_fly(dt)


func _fly(dt: float) -> void:
	var mm := multimesh
	var shown := 0
	for i in range(flying.size() - 1, -1, -1):
		var p: Dictionary = flying[i]
		var route: PackedVector3Array = p.route
		var move := speed() * dt
		while move > 0.0 and p.seg < route.size() - 1:
			var a := route[p.seg]
			var b := route[p.seg + 1]
			var len := maxf(0.001, a.distance_to(b))
			var left: float = (1.0 - p.t) * len
			if move >= left:
				move -= left
				p.seg += 1
				p.t = 0.0
				_relay_pass(route, p)
			else:
				p.t += move / len
				move = 0.0
		if p.seg >= route.size() - 1:
			_arrive(p)
			flying.remove_at(i)
			continue
		if shown < MAX_VISIBLE:
			var pos := route[p.seg].lerp(route[p.seg + 1], p.t)
			mm.set_instance_transform(shown, Transform3D(Basis(), pos))
			mm.set_instance_color(shown, COLORS.get(p.kind, Color.WHITE))
			shown += 1
	mm.visible_instance_count = shown


## A4: a packet passing through a relay plays its attack clip (at most once per 0.5 s).
## Route waypoints are the chain structures' link_points, so the intermediate relay
## is the structure whose link_point matches the waypoint the packet just reached.
func _relay_pass(route: PackedVector3Array, p: Dictionary) -> void:
	if int(p.seg) >= route.size() - 1:
		return  # final arrival is handled by _arrive
	var wp: Vector3 = route[int(p.seg)]
	for s in _structs:
		if s.type == "relay" and not s.dead and s.link_point().distance_to(wp) < 0.6:
			StructureMeshes.model_packet(s)
			return


func _arrive(p: Dictionary) -> void:
	if p.get("returns", false):
		if stockpile != null:
			stockpile.add(str(p.kind), float(p.n))
		return
	var s: Structure = p.s
	s.in_flight = maxi(0, s.in_flight - 1)
	if s.dead:
		return  # destroyed while the packet was en route: energy lost
	match p.kind:
		"build":
			s.delivered += 1
		"ammo":
			s.ammo = minf(s.ammo_max(), s.ammo + s.def.ammo.per_packet)
			if s.ammo_max() - s.ammo < 0.01:
				s.ammo = s.ammo_max()  # snap: float residue must never leave a magazine visually unfilled
			AmmoGrades.arrived(s, str(p.get("grade", "")), s.def.ammo.per_packet)
		"unit":
			if not s.queue.is_empty():
				s.queue[0].delivered += 1
		"terp":
			if s.job.is_empty() or int(s.job.get("x", -1)) < 0:
				return  # step was cancelled while this packet was in flight
			s.job["paid"] = int(s.job.paid) + 1
	# P1: packet arrival pop (visual only). Packets is a child of StructureManager.
	var _mgr := get_parent()
	var _w: Variant = _mgr.get("world") if _mgr != null else null
	if _w != null and (_w as World).effects != null:
		WeaponFx.packet_flash((_w as World).effects, s)


## Ore or Salvage already extracted. The route is copied reversed, so a later rebuild cannot recall it.
func launch_return(s: Structure, kind: String, n: float) -> bool:
	var route := network.route(s)
	if route.size() < 2:
		return false
	route.reverse()
	return launch_route(route, kind, n, s)


## A return packet along an explicit route (Salvage Engines start at their socket, not at a Structure).
func launch_route(route: PackedVector3Array, kind: String, n: float, s: Structure = null) -> bool:
	if route.size() < 2:
		return false
	flying.append({ "s": s, "kind": kind, "route": route, "seg": 0, "t": 0.0, "returns": true, "n": n })
	return true


func count() -> int:
	return flying.size()


## Attack swing on the Command Node's model when a packet leaves it, at most
## once every 0.5 s. The route starts at the sender's link_point().
func _node_launch_anim(list: Array, route: PackedVector3Array) -> void:
	if route.is_empty():
		return
	var from: Vector3 = route[0]
	for t in list:
		var s: Structure = t
		if s.type != "node" or s.body == null:
			continue
		if s.link_point().distance_squared_to(from) > 0.0001:
			continue
		var model := CreatureAnim.of(s.body)
		if model == null:
			return
		var now := Time.get_ticks_msec()
		if now - int(_node_atk.get(s.id, 0)) >= 500:
			_node_atk[s.id] = now
			CreatureAnim.attack(model)
		return
