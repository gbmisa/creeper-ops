class_name WorldLook
## Environment, lighting and the cave ceiling for a World.


## Surface: warm fantasy dusk (amber sun low in the east, violet-blue zenith).
## The cave keeps its colours. Both get SSAO; GL compatibility (Xvfb) ignores it.
static func make_environment(cave: bool) -> WorldEnvironment:
	var e := Environment.new()
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.0
	e.glow_enabled = true
	e.glow_intensity = 0.4
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.2
	e.ssao_enabled = true
	e.ssao_radius = 1.5
	e.ssao_intensity = 1.5
	if cave:
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color("120b1c")
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color("6a5a90")
		e.ambient_light_energy = 0.9
		e.fog_enabled = true
		e.fog_light_color = Color("1a1028")
		e.fog_density = 0.02
	else:
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = load("res://shaders/dusk_sky.gdshader")
		var s := Sky.new()
		s.sky_material = sky_mat
		e.background_mode = Environment.BG_SKY
		e.sky = s
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = 0.9
		e.fog_enabled = true
		e.fog_light_color = Color("c4a090")
		# 1 - exp(-density * metres). 0.0032 is about 40% haze at 160 m, Level 1's far edge.
		e.fog_density = 0.0032
		e.fog_aerial_perspective = 0.7
		e.fog_sun_scatter = 0.3
		e.fog_sky_affect = 0.28
		e.adjustment_enabled = true
		e.adjustment_saturation = 1.06
	var we := WorldEnvironment.new()
	we.environment = e
	return we


static func add_lights(world: Node3D, g: Grid, cave: bool) -> void:
	var size := g.world_size()
	var centre := Vector3(size.x * 0.5, 0, size.y * 0.5)
	if cave:
		var amb := OmniLight3D.new()
		amb.position = centre + Vector3(0, 7.5, 0)
		amb.omni_range = maxf(size.x, size.y)
		amb.light_energy = 0.6
		amb.light_color = Color("a08cd0")
		world.add_child(amb)
		world.add_child(_ceiling(g, 8.5))
		return
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe2c0")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.72  # dusk shadows must not hide the tile grid
	sun.directional_shadow_max_distance = 260.0
	sun.position = centre
	sun.look_at_from_position(centre + Vector3(0.45, 0.82, -0.3) * 100.0, centre, Vector3.UP)
	world.add_child(sun)


static func _ceiling(g: Grid, y: float) -> MeshInstance3D:
	var size := g.world_size()
	var pm := PlaneMesh.new()
	pm.size = size + Vector2(60, 60)
	pm.flip_faces = true
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3(size.x * 0.5, y, size.y * 0.5)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("1c1426")
	m.roughness = 1.0
	mi.material_override = m
	return mi
