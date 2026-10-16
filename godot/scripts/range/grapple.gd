class_name Grapple
extends Node3D
## Grappling hook (RANGE5 Track UTIL): aim, fire the hook 35 m, attaches to world geometry
## (bots are on the body layer: never hooked), reels the player at 12 m/s, releases on
## jump / use key or arrival, keeps momentum (swing onto roofs / the watchtower), visible
## rope line, 4 s cooldown, unlimited uses. One Grapple node per UtilSystem; the hook entity
## itself (target, attached, cooldown) lives in the session's UtilState (server-owned in MP-2).

const RANGE := 35.0
const SPEED := 12.0
const COOLDOWN := 4.0
const ARRIVE := 1.6

var session: RangeSession
var has_hook: Callable  # peer_id -> bool: the hook item is still equipped
var _rope: MeshInstance3D
var _rope_mesh: ImmediateMesh


func setup(s: RangeSession, hook_fn: Callable) -> void:
	session = s
	has_hook = hook_fn
	_rope_mesh = ImmediateMesh.new()
	_rope = MeshInstance3D.new()
	_rope.mesh = _rope_mesh
	_rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rope)


func _node_for(peer_id: int) -> TacticalPlayer:
	for s in session.players:
		if s.peer_id == peer_id:
			return s.node
	return null


## Fire at the camera aim. {ok, why}. Firing again while attached releases the hook.
func fire(peer_id: int, time: float) -> Dictionary:
	var n := _node_for(peer_id)
	if n == null:
		return {"ok": false, "why": "no such player"}
	var g := session.util.grapple_for(peer_id)
	if g != null and g.attached:
		release(peer_id, "released")
		return {"ok": true, "why": ""}
	if g != null and g.cooldown_until > time:
		return {"ok": false, "why": "recharging"}
	return fire_at(peer_id, n.eye_pos(), -n.cam.global_basis.z, time)


## Hitscan 35 m at world geometry (bots are on the body layer: never hooked).
func fire_at(peer_id: int, from: Vector3, dir: Vector3, time: float) -> Dictionary:
	var space = get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * RANGE, TacticalConfig.LAYER_WORLD)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		RangeAudio.util("grapple", "fire", from)
		return {"ok": false, "why": "no anchor in range"}
	var g := UtilState.GrappleHook.new()
	g.id = session.ids.next()
	g.peer_id = peer_id
	g.target = hit["position"]
	g.attached = true
	g.cooldown_until = time + COOLDOWN
	session.util.grapples[peer_id] = g
	RangeAudio.util("grapple", "fire", from)
	RangeAudio.util("grapple", "impact", g.target)
	session.events.util.emit("attached", "util_grapple", g.target)
	return {"ok": true, "why": ""}


func release(peer_id: int, why: String) -> void:
	var g: UtilState.GrappleHook = session.util.grapple_for(peer_id)
	if g == null:
		return
	g.attached = false
	var n := _node_for(peer_id)
	if n != null:
		n.grapple_pull = Vector3.ZERO  # velocity keeps its last value: momentum preserved
	RangeAudio.util("grapple", "release", n.eye_pos() if n != null else Vector3.ZERO)
	session.events.util.emit("released", "util_grapple", g.target)


func tick(dt: float, time: float, local_release: bool) -> void:
	_rope_mesh.clear_surfaces()
	var local_peer := session.local.peer_id if session.local != null else 1
	for peer_id in session.util.grapples:
		var g: UtilState.GrappleHook = session.util.grapple_for(peer_id)
		if g == null or not g.attached:
			continue
		if local_release and peer_id == local_peer:
			release(peer_id, "released")
			continue
		var n := _node_for(peer_id)
		if n == null or n.body.dead or not has_hook.call(peer_id):
			release(peer_id, "released")
			continue
		var to: Vector3 = g.target - n.global_position
		var dist := to.length()
		if dist < ARRIVE:
			release(peer_id, "arrived")
			continue
		var dirn := to / dist
		if dist < 5.0:
			# near the anchor: bias upward so the player crests ledges instead of grinding the wall
			dirn = (dirn + Vector3(0, 0.7 * (1.0 - dist / 5.0), 0)).normalized()
		n.grapple_pull = dirn * SPEED
		_rope_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		_rope_mesh.surface_add_vertex(n.eye_pos())
		_rope_mesh.surface_add_vertex(g.target)
		_rope_mesh.surface_end()
