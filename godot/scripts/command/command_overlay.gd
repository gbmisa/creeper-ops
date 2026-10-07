class_name CommandOverlay
extends RefCounted
## Command-mode visuals on the ground, all drawn by terrain.gdshader (smooth tints, nothing
## that can clip): the placement/move/landing ghost footprint, a range ring for the tool or
## the selection, the selection ring, and network cover while placing networked structures.
## Also owns the translucent 3D ghost model of what you're about to place.

var world: World
var mat: ShaderMaterial
var ghost_node: Node3D = null
var ghost_type := ""
var ghost_mat: StandardMaterial3D = null


func _init(w: World) -> void:
	world = w
	mat = w.terrain_mat


func _set_ghost_model(type: String) -> void:
	if type == ghost_type:
		return
	if ghost_node:
		ghost_node.queue_free()
		ghost_node = null
	ghost_type = type
	if type == "" or not StructureDefs.DEFS.has(type):
		return
	ghost_node = StructureMeshes.ghost(type, true)
	world.add_child(ghost_node)
	for mi in ghost_node.find_children("*", "MeshInstance3D", true, false):
		ghost_mat = (mi as MeshInstance3D).material_override
		break


## type: structure type being placed/moved/landed ("" = none). at: ground point.
func show_ghost(type: String, at: Vector3, ok: bool, radius_m: float, range_m: float, cover: Array[Vector4]) -> void:
	_set_ghost_model(type)
	if ghost_node:
		ghost_node.visible = true
		var hover := Mover.HOVER if StructureDefs.DEFS[type].get("flying", false) else 0.0
		ghost_node.position = at + Vector3(0, 0.05 + hover, 0)
		ghost_mat.albedo_color = Color(0.45, 1.0, 0.8, 0.7) if ok else Color(1.0, 0.35, 0.35, 0.7)
	var half := (Config.COLLECT_RADIUS + 0.5) * Config.CELL
	mat.set_shader_parameter("field_preview", Vector4(at.x, at.z, half, 1.0 if type == "collector" else 0.0))
	mat.set_shader_parameter("ghost", Vector4(at.x, at.z, radius_m, 1.0))
	mat.set_shader_parameter("ghost_ok", 1.0 if ok else 0.0)
	mat.set_shader_parameter("ring_a", Vector4(at.x, at.z, range_m, 1.0 if range_m > 0.0 else 0.0))
	mat.set_shader_parameter("ring_a_color", Color(0.37, 0.83, 1.0) if ok else Color(1.0, 0.4, 0.4))
	var pc := PackedVector4Array(cover)
	pc.resize(96)
	mat.set_shader_parameter("nodes", pc)
	mat.set_shader_parameter("node_count", cover.size())
	mat.set_shader_parameter("show_cover", 1.0 if not cover.is_empty() else 0.0)


func hide_ghost() -> void:
	if ghost_node:
		ghost_node.visible = false
	mat.set_shader_parameter("ghost", Vector4.ZERO)
	mat.set_shader_parameter("field_preview", Vector4.ZERO)
	mat.set_shader_parameter("ring_a", Vector4.ZERO)
	mat.set_shader_parameter("show_cover", 0.0)


## Selection ring + (for weapons) its firing range, drawn as ring_b / ring_a.
func show_selection(s: Structure, group: Array[Structure], tool_active: bool) -> void:
	var rings := PackedVector4Array()
	if group.size() > 1:  # a box-selected group: one ring each, no range ring
		for g in group.slice(0, 48):
			rings.append(Vector4(g.pos.x, g.pos.z, StructureDefs.radius_m(g.type) + 0.7, 1.0))
		s = null
		if not tool_active:
			mat.set_shader_parameter("ring_a", Vector4.ZERO)
	var n := rings.size()
	rings.resize(48)
	mat.set_shader_parameter("sels", rings)
	mat.set_shader_parameter("sel_count", n)
	if s == null:
		mat.set_shader_parameter("ring_b", Vector4.ZERO)
		return
	var p := s.pos
	mat.set_shader_parameter("ring_b", Vector4(p.x, p.z, StructureDefs.radius_m(s.type) + 0.6, 1.0))
	if not tool_active:
		var r: float = WeaponLogic.range_cells(s) * Config.CELL
		mat.set_shader_parameter("ring_a", Vector4(p.x, p.z, r, 1.0 if r > 0.0 else 0.0))
		mat.set_shader_parameter("ring_a_color", Color(1.0, 0.75, 0.3))


func set_overlay_visible(on: bool) -> void:
	mat.set_shader_parameter("show_overlay", 1.0 if on else 0.0)
	if not on:
		hide_ghost()
		mat.set_shader_parameter("ring_b", Vector4.ZERO)
		mat.set_shader_parameter("sel_count", 0)
