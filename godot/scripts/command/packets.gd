class_name Packets
extends MultiMeshInstance3D
## Packet dispatcher, CW3 rules: energy IS packets. The nearest sender launches a packet the
## moment a structure requests one AND the bank holds >= 1 energy. There is no global launch
## cap. One flying Node does not stop launches while another sender is ready. Throughput is
## limited only by income, the bank, and each structure's request rate
## (Config.REQ_BUILD / REQ_AMMO / REQ_UNIT / REQ_TERP). Requests the bank can't pay are counted as unmet
## demand so the HUD can show the red number the way CW3 does. No priority: requesters are
## served round robin, ammo and builds alike.

const MAX_VISIBLE := 1200
const COLORS := { "build": Color("e8fbff"), "ammo": Color("ffb13b"), "unit": Color("9dff7a"), "terp": Color("e2b15a") }

var network: Network
var economy: Economy
var flying: Array[Dictionary] = []
var _cursor := 0

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
				flying.append({ "s": s, "kind": kind, "route": route, "seg": 0, "t": 0.0 })
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
			mm.set_instance_color(shown, COLORS[p.kind])
			shown += 1
	mm.visible_instance_count = shown


func _arrive(p: Dictionary) -> void:
	var s: Structure = p.s
	s.in_flight = maxi(0, s.in_flight - 1)
	if s.dead:
		return  # destroyed while the packet was en route: energy lost
	match p.kind:
		"build":
			s.delivered += 1
		"ammo":
			s.ammo = minf(s.ammo_max(), s.ammo + s.def.ammo.per_packet)
		"unit":
			if not s.queue.is_empty():
				s.queue[0].delivered += 1
		"terp":
			if s.job.is_empty() or int(s.job.get("x", -1)) < 0:
				return  # step was cancelled while this packet was in flight
			s.job["paid"] = int(s.job.paid) + 1


func count() -> int:
	return flying.size()
