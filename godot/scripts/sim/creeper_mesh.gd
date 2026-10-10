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
var _prev_field := PackedFloat32Array()
var _prev_height := PackedFloat32Array()
var _tops := PackedFloat32Array()  # _build_surface scratch: highest wet neighbour level


## Color ramp for the rendered fluid (creeper blue; anti-creeper overrides with teal).
func _fluid_colors() -> Dictionary:
	return {
		"shallow": Color(0.07, 0.2, 0.52),
		"deep": Color(0.008, 0.025, 0.11),
		"glow": Color(0.12, 0.40, 1.0),
		"sheen": Color(0.45, 0.6, 0.95),
	}


## The simulated field this mesh renders (creeper depth; anti-creeper overrides).
func _fluid_field() -> PackedFloat32Array:
	return sim.depth


## Sample the GPU sim textures directly, or upload from the CPU copy each tick.
func _wants_gpu_tex() -> bool:
	return sim.is_gpu()


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
	m.custom_aabb = AABB(Vector3(0, -4, 0), Vector3(g.w * Config.CELL, (Config.SPIRE_MAX_LEVEL + Config.MAX_DEPTH) * Config.LEVEL_H, g.h * Config.CELL))
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
	var col := _fluid_colors()
	mat.set_shader_parameter("shallow", col["shallow"])
	mat.set_shader_parameter("deep", col["deep"])
	mat.set_shader_parameter("glow", col["glow"])
	mat.set_shader_parameter("sheen", col["sheen"])
	material_override = mat
	if _wants_gpu_tex():
		mat.set_shader_parameter("surf_tex", sim.surf_tex)
		mat.set_shader_parameter("depth_tex", sim.depth_tex)
		return
	_surf.resize(g.w * g.h)
	_surf_img = Image.create_from_data(g.w, g.h, false, Image.FORMAT_RF, _surf.to_byte_array())
	_surf_tex = ImageTexture.create_from_image(_surf_img)
	_depth_img = Image.create_from_data(g.w, g.h, false, Image.FORMAT_RF, _fluid_field().to_byte_array())
	_depth_tex = ImageTexture.create_from_image(_depth_img)
	mat.set_shader_parameter("surf_tex", _surf_tex)
	mat.set_shader_parameter("depth_tex", _depth_tex)


## Push the latest surface to the GPU (only for the world being rendered, once per sim tick).
## Skipped when neither the field nor the ground changed (an empty anti-creeper field).
func refresh() -> void:
	if _wants_gpu_tex() or sim.ticks == _last_tick:
		return
	_last_tick = sim.ticks
	var g := sim.grid
	var field := _fluid_field()
	if field == _prev_field and g.height == _prev_height:
		return
	_prev_field = field  # copy-on-write: shares the buffer until the sim writes again
	_prev_height = g.height
	_build_surface()
	_surf_img.set_data(g.w, g.h, false, Image.FORMAT_RF, _surf.to_byte_array())
	_surf_tex.update(_surf_img)
	_depth_img.set_data(g.w, g.h, false, Image.FORMAT_RF, field.to_byte_array())
	_depth_tex.update(_depth_img)


## One pass sets wet and hidden cells; only dry neighbours of wet cells need the
## highest-neighbour rule, so that work scales with the creeper, not the map.
func _build_surface() -> void:
	var g := sim.grid
	var w := g.w
	var hh := g.h
	var height := g.height
	var depth := _fluid_field()
	var wet_min := Config.MIN_DEPTH
	var wet := PackedInt32Array()
	for i in w * hh:
		var d := depth[i]
		if d > wet_min:
			_surf[i] = height[i] + maxf(d, MIN_VIS)
			wet.append(i)
		else:
			_surf[i] = height[i] - HIDDEN
	if wet.is_empty():
		return
	_tops.resize(w * hh)
	_tops.fill(-INF)
	var shore := PackedInt32Array()
	for i in wet:
		var x := i % w
		var z := i / w
		var v := _surf[i]
		for dz in range(-1, 2):
			var zz := z + dz
			if zz < 0 or zz >= hh:
				continue
			for dx in range(-1, 2):
				var xx := x + dx
				if xx < 0 or xx >= w:
					continue
				var j := zz * w + xx
				if depth[j] > wet_min:
					continue
				if _tops[j] == -INF:
					shore.append(j)
				_tops[j] = maxf(_tops[j], v)
	for j in shore:
		var top := _tops[j]
		var h := height[j]
		_surf[j] = h - SHORE_DIP if top >= h else top - 0.02
