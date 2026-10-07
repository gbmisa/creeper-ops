class_name WorldLook
## Environment, lighting and the cave ceiling for a World.


static func make_environment(cave: bool) -> WorldEnvironment:
	var e := Environment.new()
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.0
	e.glow_enabled = true
	e.glow_intensity = 0.4
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.2
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
		var sky := ProceduralSkyMaterial.new()
		sky.sky_top_color = Color("3a4f7a")
		sky.sky_horizon_color = Color("a89cb0")
		sky.ground_horizon_color = Color("6f6a80")
		sky.ground_bottom_color = Color("2a2830")
		sky.sun_angle_max = 20.0
		var s := Sky.new()
		s.sky_material = sky
		e.background_mode = Environment.BG_SKY
		e.sky = s
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = 0.7
		e.fog_enabled = true
		e.fog_light_color = Color("6f6a80")
		e.fog_density = 0.0016
		e.fog_sky_affect = 0.2
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
	sun.light_color = Color("fff0d8")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	sun.position = centre
	sun.look_at_from_position(centre + Vector3(0.45, 0.62, -0.35) * 100.0, centre, Vector3.UP)
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
