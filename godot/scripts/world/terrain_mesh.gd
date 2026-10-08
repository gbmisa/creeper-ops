class_name TerrainMesh
## Terraced heightfield terrain. Inside the map, vertices sit EXACTLY on Grid.smooth_y (no
## decorative roughness), on the same vertex lattice and triangle split as the creeper mesh,
## so creeper can never dip under the ground. Beyond the map edge a decorative rim rises.
## Overlays (collector field, ghost footprint, range rings) are drawn by terrain.gdshader.
## Static helpers only; TerrainChunks (terrain_chunks.gd) owns the meshes and rebuilds the
## chunks a TerrainEdit touches.

const MARGIN := 14  # decorative cells beyond each edge

const PALETTES := {
	"surface": { "low": Color("3d4a2c"), "mid": Color("5d6b3a"), "high": Color("8b8566"),
		"peak": Color("b9b2a0"), "rock": Color("5a5550"), "blight": Color("4a2a5c") },
	"cave": { "low": Color("2c2633"), "mid": Color("3a3244"), "high": Color("4a3f55"),
		"peak": Color("4a3f55"), "rock": Color("3a3440"), "blight": Color("46205a") },
}


const STONE := Color("8a8478")
const SPIRE := Color("2a2730")  # obsidian
const SPIRE_VEIN := Color("5a4a6a")  # dull violet glassy streaks

static func sample_height(grid: Grid, wx: float, wz: float, noise: Noise2D, cave: bool) -> float:
	var size := grid.world_size()
	var cx := clampf(wx, 0.0, size.x)
	var cz := clampf(wz, 0.0, size.y)
	var y := grid.smooth_y(cx, cz)
	var outside := Vector2(wx - cx, wz - cz).length() / Config.CELL
	if outside > 0.0:
		y = maxf(y, 0.0) + outside * (2.2 if cave else 1.4) + noise.fbm(wx / 18.0, wz / 18.0) * outside * 0.9
		y += (noise.fbm(wx / 3.1, wz / 3.1, 2) - 0.5) * 0.3
	return y


## Builds a lattice mesh from x0,z0 with nx*nz vertices at `step` spacing. Shared by the
## terrain (with colours) and the creeper (flat; its shader displaces it).
static func lattice_indices(nx: int, nz: int) -> PackedInt32Array:
	var idx := PackedInt32Array()
	idx.resize((nx - 1) * (nz - 1) * 6)
	var k := 0
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var c := a + nx
			idx[k] = a; idx[k + 1] = a + 1; idx[k + 2] = c
			idx[k + 3] = a + 1; idx[k + 4] = c + 1; idx[k + 5] = c
			k += 6
	return idx


## Mesh for the extended-cell range [c0, c1) on both axes (extended cell = grid cell +
## MARGIN, so the decorative rim is chunked too). Normals come from sample_height, not from
## neighbouring vertices, so neighbouring chunks meet without seams. TerrainChunks calls this.
static func build_region(grid: Grid, cave: bool, noise: Noise2D, c0: Vector2i, c1: Vector2i) -> ArrayMesh:
	var pal: Dictionary = PALETTES["cave" if cave else "surface"]
	var step := Config.CELL / Config.DETAIL
	var nx := (c1.x - c0.x) * Config.DETAIL + 1
	var nz := (c1.y - c0.y) * Config.DETAIL + 1
	var x0 := (c0.x - MARGIN) * Config.CELL
	var z0 := (c0.y - MARGIN) * Config.CELL
	var n := nx * nz
	var verts := PackedVector3Array()
	verts.resize(n)
	var normals := PackedVector3Array()
	normals.resize(n)
	var colors := PackedColorArray()
	colors.resize(n)
	for j in nz:
		for i in nx:
			var wx := x0 + i * step
			var wz := z0 + j * step
			var k := j * nx + i
			verts[k] = Vector3(wx, sample_height(grid, wx, wz, noise, cave), wz)
			var l := sample_height(grid, wx - step, wz, noise, cave)
			var r := sample_height(grid, wx + step, wz, noise, cave)
			var d := sample_height(grid, wx, wz - step, noise, cave)
			var u := sample_height(grid, wx, wz + step, noise, cave)
			normals[k] = Vector3(l - r, 2.0 * step, d - u).normalized()
			colors[k] = _colour(grid, verts[k], normals[k], pal, noise)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = lattice_indices(nx, nz)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _colour(grid: Grid, p: Vector3, nrm: Vector3, pal: Dictionary, noise: Noise2D) -> Color:
	var t := clampf(p.y / (Config.MAX_LEVEL * Config.LEVEL_H), 0.0, 1.0)
	var c: Color
	if t < 0.35:
		c = pal.low.lerp(pal.mid, t / 0.35)
	elif t < 0.75:
		c = pal.mid.lerp(pal.high, (t - 0.35) / 0.4)
	else:
		c = pal.high.lerp(pal.peak, (t - 0.75) / 0.25)
	c *= 0.85 + 0.3 * noise.fbm(p.x / 11.0, p.z / 11.0, 2)
	# Alternate levels get a slightly different shade so terraces read from above (CW3 style).
	c *= 0.93 + 0.07 * float(int(roundf(p.y / Config.LEVEL_H)) % 2)
	var steep := 1.0 - nrm.y
	if steep > 0.12:
		var rock: Color = pal.rock * (0.8 + 0.4 * noise.fbm(p.x / 2.0, p.y / 2.0))
		c = c.lerp(rock, minf(1.0, (steep - 0.12) * 3.0))
	var size := grid.world_size()
	if p.x < 0.0 or p.z < 0.0 or p.x > size.x or p.z > size.y:  # decorative rim: bare rock
		c = c.lerp(pal.rock * (0.75 + 0.4 * noise.fbm(p.x / 5.0, p.z / 5.0)), 0.8)
	var cell := grid.world_to_cell(p.x, p.z)
	if grid.in_bounds(cell.x, cell.y):  # castle stone and spire obsidian (CastleShape)
		match grid.material[grid.idx(cell.x, cell.y)]:
			Grid.Mat.STONE, Grid.Mat.PLATED:
				c = STONE * (0.85 + 0.3 * noise.fbm(p.x / 1.5, p.y / 1.5 + p.z / 1.5))
			Grid.Mat.SPIRE:
				c = SPIRE.lerp(SPIRE_VEIN, clampf(noise.fbm(p.x / 3.0, p.y / 2.0 + p.z / 3.0) * 2.0 - 0.9, 0.0, 1.0))
	if grid.zone_at(cell.x, cell.y) == Grid.Zone.BLIGHT:
		c = c.lerp(pal.blight, 0.55)
	c.a = 1.0
	return c


## Grid heights as a float texture (one texel per cell) for shaders.
static func height_texture(grid: Grid) -> ImageTexture:
	var img := Image.create_from_data(grid.w, grid.h, false, Image.FORMAT_RF, grid.height.to_byte_array())
	return ImageTexture.create_from_image(img)


## Tiling grain texture so flat ground isn't one flat colour.
static func grain_texture() -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.05
	fn.fractal_octaves = 3
	nt.noise = fn
	nt.seamless = true
	nt.width = 256
	nt.height = 256
	return nt
