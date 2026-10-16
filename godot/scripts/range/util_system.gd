class_name UtilSystem
extends Node3D
## Utility items (RANGE5 Track UTIL): grappling hook, frag / smoke / flash grenades, binoculars.
## Steps the session's UtilState entities (server-owned in MP-2); visuals and audio subscribe to
## session.events. Works in both maps: FiringRange wires it once, Skirmish reuses the same player.

const GRAPPLE_RANGE := Grapple.RANGE  # re-exported for callers/tests
const FRAG_FUSE := 4.0
const FRAG_RADIUS := 12.0
const FRAG_DMG := 130.0
const SMOKE_FUSE := 2.0
const SMOKE_TIME := 25.0
const SMOKE_RADIUS := 6.0
const FLASH_FUSE := 1.2
const FLASH_RADIUS := 18.0
const FLASH_TIME := 4.0
const THROW_SPEED := 14.0
const FLEE_RADIUS := 9.0

var player: TacticalPlayer
var weapons: PlayerWeapons
var session: RangeSession
var bal: Ballistics
var get_bots: Callable

var grapple: Grapple
var _time := 0.0
var _cook := {}  # {slot, item, t} while a frag is being cooked
var _binoc := false
var _flash_t := 0.0
var _arc: MeshInstance3D
var _arc_mesh: ImmediateMesh
var _overlay: CanvasLayer
var _flash_rect: ColorRect
var _binoc_label: Label
var _smoke_visuals := {}  # smoke id -> Array[MeshInstance3D]


func setup(p: TacticalPlayer, w: PlayerWeapons, s: RangeSession, b: Ballistics, bots_fn: Callable) -> void:
	player = p
	weapons = w
	session = s
	bal = b
	get_bots = bots_fn
	grapple = Grapple.new()
	add_child(grapple)
	grapple.setup(s, _has_hook)
	_arc_mesh = ImmediateMesh.new()
	_arc = MeshInstance3D.new()
	_arc.mesh = _arc_mesh
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_arc)
	_overlay = CanvasLayer.new()
	_overlay.layer = 9
	add_child(_overlay)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_flash_rect)
	_binoc_label = Label.new()
	_binoc_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_binoc_label.position.y = 40
	_binoc_label.visible = false
	_overlay.add_child(_binoc_label)


func _peer() -> int:
	return session.local.peer_id if session.local != null else 1


func _node_for(peer_id: int) -> TacticalPlayer:
	for s in session.players:
		if s.peer_id == peer_id:
			return s.node
	return null


## MULTIPLAYER.md rule 4: the one entry for using a utility slot. {ok, why}.
func request_use(peer_id: int, slot: String) -> Dictionary:
	if slot != "utility1" and slot != "utility2":
		return {"ok": false, "why": "not a utility slot"}
	var inv := _inv_for(peer_id)
	if inv == null:
		return {"ok": false, "why": "no such player"}
	var item = inv.equipped(slot)
	if item == null or ItemDefs.def_of(item)["kind"] != "utility":
		return {"ok": false, "why": "nothing equipped"}
	match item["id"]:
		"util_grapple":
			return fire_grapple(peer_id)
		"util_frag":
			return _start_cook(peer_id, slot, item)
		"util_smoke":
			return throw_grenade(peer_id, "util_smoke", SMOKE_FUSE)
		"util_flash":
			return throw_grenade(peer_id, "util_flash", FLASH_FUSE)
		"util_binoculars":
			_toggle_binoc(peer_id)
			return {"ok": true, "why": ""}
	return {"ok": false, "why": "unknown utility"}


func _state_for(peer_id: int) -> PlayerState:
	for s in session.players:
		if s.peer_id == peer_id:
			return s
	return null


## The live inventory for a peer: the local player's is PlayerWeapons.inv (the one the UI,
## crates and meds all mutate); PlayerState.inv is the MP-2 replica slot for remote peers.
func _inv_for(peer_id: int) -> Inventory:
	if session.local != null and peer_id == session.local.peer_id:
		return weapons.inv
	var st := _state_for(peer_id)
	return st.inv if st != null else null


func _physics_process(dt: float) -> void:
	_time += dt
	var local_release := _tick_input()
	_tick_grenades(dt)
	_tick_smoke()
	grapple.tick(dt, _time, local_release)
	_tick_overlays(dt)


func _can_act() -> bool:
	return player.enabled and not weapons.ui_open and not player.body.dead


## Returns true when the local player pressed jump or use this frame (grapple release).
func _tick_input() -> bool:
	if not _can_act():
		_cancel_cook()
		return false
	var frame = player.input.frame
	if frame.act("t_util_1"):
		_use_slot("utility1")
	elif frame.act("t_util_2"):
		_use_slot("utility2")
	# frag cooking: hold to cook, release to throw, 4 s burns in hand
	if not _cook.is_empty():
		var action: String = "t_util_1" if _cook["slot"] == "utility1" else "t_util_2"
		if frame.held(action):
			_cook["t"] = float(_cook["t"]) + get_physics_process_delta_time()
			_draw_arc()
			if float(_cook["t"]) >= FRAG_FUSE:
				_cook_off_in_hand()
		else:
			_throw_cooked()
	# grapple release: jump / use (arrival is handled in Grapple.tick)
	var g: UtilState.GrappleHook = session.util.grapple_for(_peer())
	if g != null and g.attached:
		return frame.act("t_jump") or frame.act("t_use")
	return false


func _use_slot(slot: String) -> void:
	var r := request_use(_peer(), slot)
	if not r["ok"]:
		weapons.message.emit(r["why"])


func _start_cook(peer_id: int, slot: String, item: Dictionary) -> Dictionary:
	if not _cook.is_empty():
		return {"ok": false, "why": "already cooking"}
	_cook = {"slot": slot, "item": item, "t": 0.0}
	var n := _node_for(peer_id)
	RangeAudio.util("frag", "pin", n.eye_pos() if n != null else Vector3.ZERO)
	session.events.util.emit("cook", "util_frag", n.eye_pos() if n != null else Vector3.ZERO)
	return {"ok": true, "why": ""}


func _cancel_cook() -> void:
	_cook = {}
	_arc_mesh.clear_surfaces()


func _cook_off_in_hand() -> void:
	var item: Dictionary = _cook["item"]
	_consume(_peer(), item)
	_cancel_cook()
	_detonate_frag(player.eye_pos(), _peer())


func _throw_cooked() -> void:
	var item: Dictionary = _cook["item"]
	var fuse := FRAG_FUSE - float(_cook["t"])
	_cancel_cook()
	_spawn_thrown("frag", maxf(0.2, fuse), item)


## Throw a smoke / flash immediately (no cooking). {ok, why}.
func throw_grenade(peer_id: int, item_id: String, fuse: float) -> Dictionary:
	var inv := _inv_for(peer_id)
	if inv == null:
		return {"ok": false, "why": "no such player"}
	var kind := "smoke" if item_id == "util_smoke" else "flash"
	var item = inv.equipped("utility1")
	if item == null or item["id"] != item_id:
		item = inv.equipped("utility2")
	if item == null or item["id"] != item_id:
		return {"ok": false, "why": "not equipped"}
	_spawn_thrown(kind, fuse, item, peer_id)
	return {"ok": true, "why": ""}


func _consume(peer_id: int, item: Dictionary) -> void:
	var inv := _inv_for(peer_id)
	if inv != null and not item.is_empty():
		inv.request_remove(item)
	weapons.sync()


func _throw_from(peer_id: int) -> Array:
	var n := _node_for(peer_id)
	var from: Vector3 = n.eye_pos() if n != null else player.eye_pos()
	var dir := Vector3.ZERO
	if n != null:
		dir = -n.cam.global_basis.z
	else:
		dir = -player.cam.global_basis.z
	return [from + dir * 0.5, dir]


func _spawn_thrown(kind: String, fuse: float, item: Dictionary = {}, peer_id: int = -1) -> void:
	if peer_id < 0:
		peer_id = _peer()
	var inv := _inv_for(peer_id)
	var t := _throw_from(peer_id)
	var g := UtilState.ThrownUtil.new()
	g.id = session.ids.next()
	g.rng.seed = session.next_seed()
	g.kind = kind
	g.owner_peer = peer_id
	g.pos = t[0]
	g.vel = t[1] * THROW_SPEED + Vector3(0, 2.5, 0)
	g.fuse = fuse
	session.util.grenades.append(g)
	RangeAudio.util(kind, "throw", g.pos)
	session.events.util.emit("thrown", "util_" + kind, g.pos)
	if inv != null and not item.is_empty():
		inv.request_remove(item)
	weapons.sync()


func _tick_grenades(dt: float) -> void:
	var space = get_world_3d().direct_space_state
	var done := []
	for g in session.util.grenades:
		g = g as UtilState.ThrownUtil
		g.fuse -= dt
		if g.fuse <= 0.0:
			_detonate(g)
			done.append(g)
			continue
		if not g.landed:
			_step_grenade(g, dt, space)
		elif g.kind == "frag":
			_flee_check(g)
	for g in done:
		session.util.grenades.erase(g)


func _step_grenade(g: UtilState.ThrownUtil, dt: float, space: PhysicsDirectSpaceState3D) -> void:
	g.vel.y -= TacticalConfig.GRAVITY * dt
	var to: Vector3 = g.pos + g.vel * dt
	var q := PhysicsRayQueryParameters3D.create(g.pos, to, TacticalConfig.LAYER_WORLD)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		g.pos = to
		return
	g.pos = hit["position"]
	var n: Vector3 = hit["normal"]
	var sp := g.vel.length()
	if sp > 3.0:
		g.vel = g.vel - 2.0 * g.vel.dot(n) * n
		g.vel *= 0.35
		RangeAudio.util(g.kind, "bounce", g.pos)
	else:
		g.landed = true
		g.vel = Vector3.ZERO


func _flee_check(g: UtilState.ThrownUtil) -> void:
	for b in get_bots.call():
		if not (b as ScavBot).body.dead and (b as ScavBot).global_position.distance_to(g.pos) < FLEE_RADIUS:
			(b as ScavBot).flee_from(g.pos)


func _detonate(g: UtilState.ThrownUtil) -> void:
	match g.kind:
		"frag":
			_detonate_frag(g.pos, g.owner_peer)
		"smoke":
			_detonate_smoke(g.pos)
		"flash":
			_detonate_flash(g.pos)


func _shot(dmg: float) -> Dictionary:
	return {"dmg": dmg, "pen": 25.0, "armor_dmg": 0.4, "ammo": {"frag": 0.8},
		"lbleed": 0.35, "hbleed": 0.15, "glance": 0.0}


func _detonate_frag(pos: Vector3, owner_peer: int) -> void:
	RangeAudio.util("frag", "blast", pos)
	session.events.util.emit("detonated", "util_frag", pos)
	session.noise.emit(pos, 45.0, "blast", self)
	var space = get_world_3d().direct_space_state
	for b in get_bots.call():
		var bot := b as ScavBot
		if bot.body.dead:
			continue
		var d: float = bot.global_position.distance_to(pos)
		if d < FRAG_RADIUS:
			var chest: Vector3 = bot.global_position + Vector3(0, 1.2, 0)
			if BotPerception.los(space, pos + Vector3(0, 0.3, 0), [chest], session.util.smokes):
				bot.body.shoot("thorax", _shot(FRAG_DMG * (1.0 - d / FRAG_RADIUS)))
				bot.hurt_t = 1.5
	var p := _node_for(owner_peer)
	if p != null and not p.god and not p.body.dead:
		var d: float = p.global_position.distance_to(pos)
		if d < FRAG_RADIUS and BotPerception.los(space, pos + Vector3(0, 0.3, 0), [p.eye_pos()], session.util.smokes):
			p.body.shoot("thorax", _shot(FRAG_DMG * (1.0 - d / FRAG_RADIUS)))
			p.on_hit({"origin": pos})


func _detonate_smoke(pos: Vector3) -> void:
	RangeAudio.util("smoke", "hiss", pos)
	var s := UtilState.SmokeVolume.new()
	s.id = session.ids.next()
	s.pos = pos + Vector3(0, 0.8, 0)
	s.radius = SMOKE_RADIUS
	s.until = _time + SMOKE_TIME
	session.util.smokes.append(s)
	_make_smoke_visual(s)
	session.events.util.emit("detonated", "util_smoke", pos)


func _detonate_flash(pos: Vector3) -> void:
	RangeAudio.util("flash", "bang", pos)
	session.events.util.emit("detonated", "util_flash", pos)
	session.noise.emit(pos, 60.0, "blast", self)
	var space = get_world_3d().direct_space_state
	for b in get_bots.call():
		var bot := b as ScavBot
		if bot.body.dead:
			continue
		if bot.global_position.distance_to(pos) > FLASH_RADIUS:
			continue
		if not BotPerception.los(space, pos, [bot.eye()], session.util.smokes):
			continue
		if BotPerception.in_view(bot.eye(), -bot.global_basis.z, pos):
			bot.stagger(FLASH_TIME)
	var p := player
	if p.global_position.distance_to(pos) < 30.0:
		var to: Vector3 = (pos - p.cam.global_position).normalized()
		var facing := -p.cam.global_basis.z
		if rad_to_deg(facing.angle_to(to)) < 65.0 \
				and BotPerception.los(space, pos, [p.cam.global_position], session.util.smokes):
			_flash_t = FLASH_TIME
			RangeAudio.util("flash", "tinnitus", p.eye_pos())


func _tick_smoke() -> void:
	var gone := []
	for s in session.util.smokes:
		s = s as UtilState.SmokeVolume
		if s.until < _time:
			gone.append(s)
	for s in gone:
		session.util.smokes.erase(s)
		for v in _smoke_visuals.get(s.id, []):
			(v as Node3D).queue_free()
		_smoke_visuals.erase(s.id)


## --- Grappling hook (delegated to grapple.gd) ---

func fire_grapple(peer_id: int) -> Dictionary:
	return grapple.fire(peer_id, _time)


func fire_grapple_at(peer_id: int, from: Vector3, dir: Vector3) -> Dictionary:
	return grapple.fire_at(peer_id, from, dir, _time)


func release_grapple(peer_id: int, why: String) -> void:
	grapple.release(peer_id, why)


func _has_hook(peer_id: int) -> bool:
	var inv := _inv_for(peer_id)
	if inv == null:
		return false
	for slot in ["utility1", "utility2"]:
		var it = inv.equipped(slot)
		if it != null and it["id"] == "util_grapple":
			return true
	return false


## --- Binoculars ---

func _toggle_binoc(peer_id: int) -> void:
	var n := _node_for(peer_id)
	if n == null:
		return
	_binoc = not _binoc
	if _binoc:
		n.cam.fov = TacticalPlayer.BASE_FOV / 8.0
		_binoc_label.visible = true
		RangeAudio.util("binoculars", "raise", n.eye_pos())
	else:
		n.cam.fov = TacticalPlayer.BASE_FOV
		_binoc_label.visible = false
		RangeAudio.util("binoculars", "lower", n.eye_pos())


func _tick_overlays(dt: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= dt
		_flash_rect.color = Color(1, 1, 1, clampf(_flash_t / FLASH_TIME, 0.0, 1.0))
	elif _flash_rect.color.a > 0.0:
		_flash_rect.color.a = 0.0
	if _binoc:
		var space = get_world_3d().direct_space_state
		var from: Vector3 = player.cam.global_position
		var q := PhysicsRayQueryParameters3D.create(from, from - player.cam.global_basis.z * 500.0, TacticalConfig.LAYER_WORLD)
		var hit := space.intersect_ray(q)
		_binoc_label.text = "%.0f m" % from.distance_to(hit["position"]) if not hit.is_empty() else "---"


## --- Throw arc preview (while cooking) ---

func _draw_arc() -> void:
	_arc_mesh.clear_surfaces()
	var t := _throw_from(_peer())
	var p: Vector3 = t[0]
	var v: Vector3 = t[1] * THROW_SPEED + Vector3(0, 2.5, 0)
	var dt := 0.09
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 24:
		_arc_mesh.surface_add_vertex(p)
		v.y -= TacticalConfig.GRAVITY * dt
		p += v * dt
		if p.y < 0.02:
			break
	_arc_mesh.surface_add_vertex(p)
	_arc_mesh.surface_end()


## --- Visuals ---

func _make_smoke_visual(s: UtilState.SmokeVolume) -> void:
	var vis := []
	for i in 5:
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = s.radius * (0.55 + 0.15 * i)
		sp.height = sp.radius * 1.2
		m.mesh = sp
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.75, 0.75, 0.78, 0.35)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = s.pos + Vector3(randf_range(-2, 2), randf_range(0, 2.5), randf_range(-2, 2))
		add_child(m)
		vis.append(m)
	_smoke_visuals[s.id] = vis
