class_name PacketRequests
## What a structure asks the packet dispatcher for. Rates, transit headroom and the
## "build" | "ammo" | "unit" choice live here so packets.gd can grow. Packets calls these.


static func speed() -> float:
	return Config.PACKET_SPEED * Upgrades.mult("packet")


static func rate(kind: String) -> float:
	match kind:
		"build": return Config.REQ_BUILD * Upgrades.mult("build")
		"ammo": return Config.REQ_AMMO
		"terp": return Config.REQ_TERP
		_: return Config.REQ_UNIT


## Ammo a firing weapon burns while its next packet is still travelling. Requests include it,
## so long supply lines keep the magazine topped up instead of counting in-flight packets
## against a nearly empty gun. Only weapons that are actually firing get it.
static func transit_headroom(network: Network, s: Structure) -> float:
	if not s.def.has("fire_rate") or s.firing <= 0.0:
		return 0.0
	var transit := network.route_length(s) / speed() + 0.5
	return s.per_shot() / WeaponLogic.fire_interval(s) * transit


## "build" | "ammo" | "unit" | "terp" | "". Counts packets already in flight so we never over-send.
static func need(network: Network, s: Structure) -> String:
	if not s.connected or s.dead or not s.active or s.def.get("drop_pod", false):
		return ""
	if not s.is_built():  # a wet site asks for nothing (CW3)
		if s.wet > Config.MIN_DEPTH:
			return ""
		return "build" if s.delivered - s.lost + s.in_flight < s.def.cost else ""
	if s.is_flying():
		return ""
	if s.has_ammo_store():
		var a: Dictionary = s.def.ammo
		# A full magazine never asks: the packet would arrive with nowhere to go.
		if s.ammo <= a.max - a.per_packet + 0.001 \
				and s.ammo + s.in_flight * a.per_packet <= a.max - a.per_packet + transit_headroom(network, s) + 0.001:
			return "ammo"
	if not s.queue.is_empty():
		var q: Dictionary = s.queue[0]
		if q.delivered + s.in_flight < q.cost:
			return "unit"
	# Joins the same round robin as ammo and builds. No priority.
	if s.type == "terp" and not s.job.is_empty() and int(s.job.get("x", -1)) >= 0 \
			and float(s.job.get("timer", 0.0)) <= 0.0 \
			and int(s.job.get("paid", 0)) + s.in_flight < Config.TERP_PACKETS:
		return "terp"
	return ""
