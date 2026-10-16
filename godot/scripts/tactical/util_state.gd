class_name UtilState
extends RefCounted
## Server-owned utility state (MULTIPLAYER.md rules 5-6): thrown grenades, smoke volumes and
## grapple hooks live here with session-issued ids and to_dict/from_dict. The offline session
## owns it; in MP-2 the server simulates it and replicates. Pure data — UtilSystem steps it.


class ThrownUtil:
	extends RefCounted
	## A frag / smoke / flash grenade in flight or on the ground waiting on its fuse.
	var id := 0
	var kind := ""  # "frag" | "smoke" | "flash"
	var owner_peer := 0
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var fuse := 0.0
	var landed := false
	var rng := RandomNumberGenerator.new()

	func to_dict() -> Dictionary:
		return {"id": id, "kind": kind, "owner": owner_peer, "pos": [pos.x, pos.y, pos.z],
			"vel": [vel.x, vel.y, vel.z], "fuse": fuse, "landed": landed}

	static func from_dict(d: Dictionary) -> ThrownUtil:
		var g := ThrownUtil.new()
		g.id = int(d.get("id", 0))
		g.kind = str(d.get("kind", ""))
		g.owner_peer = int(d.get("owner", 0))
		var p: Array = d.get("pos", [0, 0, 0])
		g.pos = Vector3(p[0], p[1], p[2])
		var v: Array = d.get("vel", [0, 0, 0])
		g.vel = Vector3(v[0], v[1], v[2])
		g.fuse = float(d.get("fuse", 0.0))
		g.landed = bool(d.get("landed", false))
		return g


class SmokeVolume:
	extends RefCounted
	## A smoke cloud that blocks bot sight lines until `until` (session seconds).
	var id := 0
	var pos := Vector3.ZERO
	var radius := 6.0
	var until := 0.0

	func blocks(a: Vector3, b: Vector3) -> bool:
		return not Geometry3D.segment_intersects_sphere(a, b, pos, radius).is_empty()

	func to_dict() -> Dictionary:
		return {"id": id, "pos": [pos.x, pos.y, pos.z], "radius": radius, "until": until}

	static func from_dict(d: Dictionary) -> SmokeVolume:
		var s := SmokeVolume.new()
		s.id = int(d.get("id", 0))
		var p: Array = d.get("pos", [0, 0, 0])
		s.pos = Vector3(p[0], p[1], p[2])
		s.radius = float(d.get("radius", 6.0))
		s.until = float(d.get("until", 0.0))
		return s


class GrappleHook:
	extends RefCounted
	## One player's grappling hook: flying (unused — hitscan), attached, or cooling down.
	var id := 0
	var peer_id := 0
	var target := Vector3.ZERO
	var attached := false
	var cooldown_until := 0.0

	func to_dict() -> Dictionary:
		return {"id": id, "peer": peer_id, "target": [target.x, target.y, target.z],
			"attached": attached, "cooldown_until": cooldown_until}

	static func from_dict(d: Dictionary) -> GrappleHook:
		var g := GrappleHook.new()
		g.id = int(d.get("id", 0))
		g.peer_id = int(d.get("peer", 0))
		var p: Array = d.get("target", [0, 0, 0])
		g.target = Vector3(p[0], p[1], p[2])
		g.attached = bool(d.get("attached", false))
		g.cooldown_until = float(d.get("cooldown_until", 0.0))
		return g


var grenades: Array = []  # ThrownUtil
var smokes: Array = []  # SmokeVolume
var grapples := {}  # peer_id -> GrappleHook


func grapple_for(peer_id: int) -> GrappleHook:
	return grapples.get(peer_id)


func to_dict() -> Dictionary:
	var g := []
	for e in grenades:
		g.append(e.to_dict())
	var s := []
	for e in smokes:
		s.append(e.to_dict())
	var h := {}
	for k in grapples:
		h[k] = (grapples[k] as GrappleHook).to_dict()
	return {"grenades": g, "smokes": s, "grapples": h}


func load_dict(d: Dictionary) -> void:
	grenades.clear()
	for e in d.get("grenades", []):
		grenades.append(ThrownUtil.from_dict(e))
	smokes.clear()
	for e in d.get("smokes", []):
		smokes.append(SmokeVolume.from_dict(e))
	grapples.clear()
	for k in (d.get("grapples", {}) as Dictionary):
		grapples[int(k)] = GrappleHook.from_dict((d["grapples"] as Dictionary)[k])
