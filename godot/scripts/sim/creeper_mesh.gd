class_name CreeperMesh
extends MeshInstance3D
## Creeper surface: a flat lattice (same vertices and triangle split as the terrain) that
## creeper.gdshader lifts to a per-cell "display level" with the terrain's terraced weights.
## The display level is what makes it read as a fluid, not a sheet draped over the ground:
##   wet cell            -> ground + depth (at least MIN_VIS so it never z-fights)
##   dry, creeper above  -> just under its own ground: the surface dives in at the shoreline
##   dry, creeper below  -> the neighbour's level: the surface runs flat into the cliff wall
##   dry, no creeper     -> well under the ground (hidden)
## Because the display level is never above a dry cell's ground and both meshes share the
## same interpolation, the shader can discard anything under the terrain cleanly.
## With the GPU sim, the compute shader builds the display level and both textures are
## sampled straight from the GPU (refresh() does nothing).

const MIN_VIS := 0.12   # levels: thinnest creeper we draw
const SHORE_DIP := 0.35 # levels below ground a shoreline cell's surface sits
const HIDDEN := 2.0

var sim: CreeperSim
var _surf := PackedFloat32Array()
var _surf_img: Image
var _surf_tex: ImageTexture
var _depth_img: Image
var _depth_tex: ImageTexture
var _last_tick := -1


func setup(creeper: CreeperSim, height_tex: Texture2D) -> void:
	sim = creeper
	var g := creeper.grid
	var step := Config.CELL / Config.DETAIL
	var nx := g.w * Config.DETAIL + 1
	var nz := g.h * Config.DETAIL + 1
	var verts := PackedVector3Array()
	verts.resize(nx * nz)
	for j in nz:
		for i in nx:
			verts[j * nx + i] = Vector3(i * step, 0.0, j * step)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = TerrainMesh.lattice_indices(nx, nz)
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# The shader moves vertices up to MAX_DEPTH levels; keep culling honest.
	m.custom_aabb = AABB(Vector3(0, -4, 0), Vector3(g.w * Config.CELL, (Config.MAX_LEVEL + Config.MAX_DEPTH) * Config.LEVEL_H, g.h * Config.CELL))
	mesh = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	name = "Creeper"

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/creeper.gdshader")
	mat.set_shader_parameter("height_tex", height_tex)
	mat.set_shader_parameter("cells", Vector2(g.w, g.h))
	mat.set_shader_parameter("cell", Config.CELL)
	mat.set_shader_parameter("level_h", Config.LEVEL_H)
	mat.set_shader_parameter("band", Config.TERRACE_BAND)
	material_override = mat
	if sim.is_gpu():
		mat.set_shader_parameter("surf_tex", sim.surf_tex)
		mat.set_shader_parameter("depth_tex", sim.depth_tex)
		return
	_surf.resize(g.w * g.h)
	_surf_img = Image.create_from_data(g.w, g.h, false, Image.FORMAT_RF, _surf.to_byte_array())
	_surf_tex = ImageTexture.create_from_image(_surf_img)
	_depth_img = Image.create_from_data(g.w, g.h, false, Image.FORMAT_RF, sim.depth.to_byte_array())
	_depth_tex = ImageTexture.create_from_image(_depth_img)
	mat.set_shader_parameter("surf_tex", _surf_tex)
	mat.set_shader_parameter("depth_tex", _depth_tex)


## Push the latest surface to the GPU (only for the world being rendered, once per sim tick).
func refresh() -> void:
	if sim.is_gpu() or sim.ticks == _last_tick:
		return
	_last_tick = sim.ticks
	_build_surface()
	var g := sim.grid
	_surf_img.set_data(g.w, g.h, false, Image.FORMAT_RF, _surf.to_byte_array())
	_surf_tex.update(_surf_img)
	_depth_img.set_data(g.w, g.h, false, Image.FORMAT_RF, sim.depth.to_byte_array())
	_depth_tex.update(_depth_img)


func _build_surface() -> void:
	var g := sim.grid
	var w := g.w
	var hh := g.h
	var height := g.height
	var depth := sim.depth
	var wet_min := Config.MIN_DEPTH
	for z in hh:
		for x in w:
			var i := z * w + x
			var h := height[i]
			var d := depth[i]
			if d > wet_min:
				_surf[i] = h + maxf(d, MIN_VIS)
				continue
			# Highest creeper level among the 8 neighbours.
			var top := -INF
			for dz in range(-1, 2):
				var zz := z + dz
				if zz < 0 or zz >= hh:
					continue
				for dx in range(-1, 2):
					var xx := x + dx
					if xx < 0 or xx >= w or (dx == 0 and dz == 0):
						continue
					var j := zz * w + xx
					if depth[j] > wet_min:
						top = maxf(top, height[j] + maxf(depth[j], MIN_VIS))
			if top == -INF:
				_surf[i] = h - HIDDEN
			elif top >= h:
				_surf[i] = h - SHORE_DIP
			else:
				_surf[i] = top - 0.02
