class_name RangeCheats
extends Node
## Debug cheats for the firing range / skirmish (Ctrl+KP5 menu). One instance per
## FiringRange (per-player state for MP; never a static). Every cheat goes through
## the single request() function so each becomes one RPC with server validation.
## Using any cheat sets cheats_used; the Skirmish end screen shows "CHEATS USED".
## Cheats are allowed only offline or for the host (enforced by the caller/MP layer).

# name -> {label, kind}: kind is "toggle", "action" or "cycle".
const DEFS := {
	"god": {"label": "God mode (no damage)", "kind": "toggle"},
	"inf_ammo": {"label": "Infinite ammo", "kind": "toggle"},
	"no_recoil": {"label": "No recoil + no sway", "kind": "toggle"},
	"noclip": {"label": "Noclip fly", "kind": "toggle"},
	"inf_stamina": {"label": "Infinite stamina", "kind": "toggle"},
	"heal": {"label": "Full heal", "kind": "action"},
	"kill_bots": {"label": "Kill all bots", "kind": "action"},
	"freeze_ai": {"label": "Freeze bot AI", "kind": "toggle"},
	"invisible": {"label": "Invisible to bots", "kind": "toggle"},
	"spawn_bot": {"label": "Spawn bot at crosshair", "kind": "action"},
	"give_guns": {"label": "Give every gun + attachment", "kind": "action"},
	"tp_crosshair": {"label": "Teleport to crosshair", "kind": "action"},
	"tp_extract": {"label": "Teleport to extract (Skirmish)", "kind": "action"},
	"instant_extract": {"label": "Instant extract (Skirmish)", "kind": "action"},
	"time_scale": {"label": "Time scale", "kind": "cycle"},
	"bot_debug": {"label": "Show bot debug", "kind": "toggle"},
	"hitboxes": {"label": "Show hitboxes", "kind": "toggle"},
	"navmesh": {"label": "Show navmesh", "kind": "toggle"},
	"fps": {"label": "FPS overlay", "kind": "toggle"},
	"reset": {"label": "Reset range/map", "kind": "action"},
}
const ORDER := ["god", "inf_ammo", "no_recoil", "noclip", "inf_stamina", "heal",
	"kill_bots", "freeze_ai", "invisible", "spawn_bot", "give_guns", "tp_crosshair",
	"tp_extract", "instant_extract", "time_scale", "bot_debug", "hitboxes",
	"navmesh", "fps", "reset"]
const TIME_SCALES := [1.0, 0.25, 2.0]
const SPAWN_KINDS := ["rifleman", "pistol", "shotgunner", "marksman", "boss"]

var flags := {}
var cheats_used := false
var time_scale_idx := 0
var spawn_kind_idx := 0

var fr: FiringRange
var _fps_label: Label
var _debug_nodes: Array = []  # nodes added by bot_debug / hitboxes / navmesh


func setup(f: FiringRange) -> void:
	fr = f
	for n in ORDER:
		flags[n] = false


func is_on(n: String) -> bool:
	return bool(flags.get(n, false))


func state_text(n: String) -> String:
	if DEFS[n]["kind"] == "cycle" and n == "time_scale":
		return "%gx" % TIME_SCALES[time_scale_idx]
	return "ON" if is_on(n) else "OFF"


## Single request function for every cheat (MP: one RPC per cheat).
func request(n: String) -> void:
	if not DEFS.has(n):
		return
	cheats_used = true
	match DEFS[n]["kind"]:
		"toggle":
			flags[n] = not is_on(n)
			_apply_toggle(n)
		"action":
			_do_action(n)
		"cycle":
			_cycle(n)
	if fr != null and fr.cheat_menu != null:
		fr.cheat_menu.refresh()


func _apply_toggle(n: String) -> void:
	var on := is_on(n)
	match n:
		"god":
			fr.player.god = on
		"invisible":
			fr.player.spot_mult = 0.0 if on else 1.0
		"noclip":
			fr.player.noclip = on
		"freeze_ai":
			for b in _bots():
				b.set_physics_process(not on)
		"bot_debug", "hitboxes", "navmesh":
			_refresh_debug()
		"fps":
			_refresh_fps()


func _do_action(n: String) -> void:
	match n:
		"heal":
			fr.player.body.reset()
		"kill_bots":
			for b in _bots():
				if is_instance_valid(b) and not b.body.dead:
					b.body.hit("thorax", 99999.0)
		"spawn_bot":
			_spawn_bot()
		"give_guns":
			_give_guns()
		"tp_crosshair":
			_tp_crosshair()
		"tp_extract":
			if fr.skirmish != null:
				fr.player.global_position = SkirmishData.EXTRACT + Vector3(0, 0.5, 0)
				fr.player.velocity = Vector3.ZERO
		"instant_extract":
			if fr.skirmish != null and not fr.skirmish.over:
				fr.skirmish.finish(true)
		"reset":
			fr.get_tree().reload_current_scene()


func _cycle(n: String) -> void:
	if n == "time_scale":
		time_scale_idx = (time_scale_idx + 1) % TIME_SCALES.size()
		Engine.time_scale = TIME_SCALES[time_scale_idx]


## Per-frame cheat effects. Called from FiringRange._process.
func apply_frame(_delta: float) -> void:
	if fr == null or fr.player == null:
		return
	if is_on("inf_stamina"):
		fr.player.leg_stamina = 1.0
	if is_on("inf_ammo"):
		_top_up_ammo()
	if is_on("fps") and is_instance_valid(_fps_label):
		_fps_label.text = "%d fps" % Engine.get_frames_per_second()


func _top_up_ammo() -> void:
	var w := fr.weapons
	if w == null or w.gun == null:
		return
	var g: Gun = w.gun
	var cap := int(g.stat("mag"))
	var top_ammo := g.mag.top()
	while g.mag.count() < cap and top_ammo != "":
		g.mag.rounds.append(top_ammo)
	if g.chamber == "" and top_ammo != "" and g.def.get("action") != "tube":
		g.chamber = g.mag.pop() if g.mag.count() > 0 else ""


func _bots() -> Array:
	if fr.bots != null:
		return fr.bots.bots
	if fr.skirmish != null:
		return fr.skirmish.bots
	return []


func _crosshair_hit() -> Dictionary:
	var cam := fr.player.cam
	var from := cam.global_position
	var fwd := -cam.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * 300.0, TacticalConfig.BULLET_MASK)
	return cam.get_world_3d().direct_space_state.intersect_ray(q)


func _spawn_bot() -> void:
	var kind: String = SPAWN_KINDS[spawn_kind_idx]
	spawn_kind_idx = (spawn_kind_idx + 1) % SPAWN_KINDS.size()
	var hit := _crosshair_hit()
	var pos: Vector3 = hit["position"] if not hit.is_empty() else fr.player.global_position + Vector3(0, 0, -3)
	pos.y += 0.1
	var bot := ScavBot.new()
	var house = fr.bots.house if fr.bots != null else null
	if house == null and fr.skirmish != null:
		house = fr.skirmish.layout
	# house may still be null in tests; ScavBot.setup handles that.
	bot.setup(fr.player, fr.bal, house, "%s (cheat)" % BotDefs.of(kind)["name"], 900 + spawn_kind_idx, kind)
	(fr.bots if fr.bots != null else fr.skirmish).add_child(bot)
	bot.global_position = pos
	_bots().append(bot)


func _give_guns() -> void:
	var center := fr.player.global_position
	var i := 0
	for id in WeaponDefs.ORDER:
		var it := ItemDefs.make(id, {})
		var a := TAU * i / WeaponDefs.ORDER.size()
		fr.world_items.drop(it, center + Vector3(cos(a) * 2.0, 0.5, sin(a) * 2.0))
		i += 1
	for att in ["reddot", "suppressor", "vgrip", "laser", "extmag"]:
		fr.world_items.drop(ItemDefs.make(att, {}), center + Vector3(0, 0.5, -2.5))


func _tp_crosshair() -> void:
	var hit := _crosshair_hit()
	if hit.is_empty():
		return
	fr.player.global_position = (hit["position"] as Vector3) + Vector3(0, 0.1, 0)
	fr.player.velocity = Vector3.ZERO


func _refresh_debug() -> void:
	for n in _debug_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_debug_nodes.clear()
	if is_on("bot_debug"):
		for b in _bots():
			if not is_instance_valid(b):
				continue
			var l := Label3D.new()
			l.text = "%s\n%s" % [b.label_name, b.brain.state]
			l.font_size = 48
			l.pixel_size = 0.004
			l.position = Vector3(0, 2.2, 0)
			l.modulate = Color(0.4, 1.0, 0.6)
			b.add_child(l)
			_debug_nodes.append(l)
	if is_on("hitboxes"):
		for b in _bots():
			if not is_instance_valid(b):
				continue
			for z in b.rig:
				var shape := (b.rig[z] as CollisionShape3D).shape as BoxShape3D
				if shape == null:
					continue
				var m := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = shape.size
				m.mesh = box
				var mat := StandardMaterial3D.new()
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.albedo_color = Color(1, 0.2, 0.2, 0.35)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.material_override = mat
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				(b.rig[z] as Node3D).add_child(m)
				_debug_nodes.append(m)
	if is_on("navmesh"):
		var region := _nav_region()
		if region != null and region.navigation_mesh != null:
			var navmesh_view := _navmesh_debug_mesh(region.navigation_mesh)
			if navmesh_view != null:
				fr.add_child(navmesh_view)
				_debug_nodes.append(navmesh_view)


## Builds a translucent debug mesh from a NavigationMesh's polygons.
func _navmesh_debug_mesh(nm: NavigationMesh) -> MeshInstance3D:
	var verts: PackedVector3Array = nm.get_vertices()
	var polys: Array = nm.get_polygons()
	if verts.is_empty() or polys.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in polys:
		if p.size() < 3:
			continue
		for i in range(1, p.size() - 1):
			st.add_vertex(verts[p[0]])
			st.add_vertex(verts[p[i]])
			st.add_vertex(verts[p[i + 1]])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func _nav_region() -> NavigationRegion3D:
	if fr.bots != null and fr.bots.house != null:
		for c in fr.bots.house.get_children():
			if c is NavigationRegion3D:
				return c
	return null


func _refresh_fps() -> void:
	if is_on("fps") and not is_instance_valid(_fps_label):
		_fps_label = Label.new()
		_fps_label.add_theme_font_size_override("font_size", 18)
		_fps_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_fps_label.position = Vector2(-140, 10)
		fr.add_child(_fps_label)
	elif not is_on("fps") and is_instance_valid(_fps_label):
		_fps_label.queue_free()
		_fps_label = null
