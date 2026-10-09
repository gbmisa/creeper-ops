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
		e.background_color = Color("0d1420")
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color("54648f")  # colder than the old violet
		e.ambient_light_energy = 1.0
		e.fog_enabled = true
		e.fog_light_color = Color("0d1420")
		e.fog_density = 0.028
	else:
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = load("res://shaders/dusk_sky.gdshader")
		var s := Sky.new()
		s.sky_material = sky_mat
		e.background_mode = Environment.BG_SKY
		e.sky = s
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = 0.9
		e.ambient_light_color = Color("8f98a8")  # neutral share so the warm cloud sky doesn't tint the map yellow
		e.ambient_light_sky_contribution = 0.6
		e.fog_enabled = true
		e.fog_light_color = Color("c4a090")
		# 1 - exp(-density * metres). 0.0032 is about 40% haze at 160 m, Level 1's far edge.
		e.fog_density = FOG_FPS * 0.25  # missions start in command view; set_command_view switches
		e.fog_aerial_perspective = 0.2
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
		amb.light_color = Color("8a9cc8")
		world.add_child(amb)
		world.add_child(_ceiling(g, 8.5))
		world.add_child(_shafts(g))
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
	m.albedo_color = Color("141a26")
	m.roughness = 1.0
	mi.material_override = m
	return mi


## Light shafts from the cave ceiling: additive cones at deterministic open cells
## near the centre (the cave has no Rift; these stand in for ceiling openings).
static func _shafts(g: Grid) -> Node3D:
	var root := Node3D.new()
	root.name = "LightShafts"
	var rng := RandomNumberGenerator.new()
	rng.seed = g.w * 73856093 ^ g.h * 19349663
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.55, 0.7, 0.9, 0.10)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var placed := 0
	var tries := 0
	while placed < 6 and tries < 60:
		tries += 1
		var x := rng.randi_range(int(g.w * 0.3), int(g.w * 0.7))
		var z := rng.randi_range(int(g.h * 0.3), int(g.h * 0.7))
		if g.height_at(x, z) > 3.0:
			continue  # want open floor, not a rock pillar
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7
		cm.bottom_radius = 2.4
		cm.height = 8.0
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((x + 0.5) * Config.CELL, 8.5 - 4.0, (z + 0.5) * Config.CELL)
		root.add_child(mi)
		placed += 1
	return root


## The command camera looks down from 40-120 m, so first-person haze would wash out the whole
## map. Command mode keeps a quarter of the density and little aerial tint.
const FOG_FPS := 0.0032
static func set_command_view(we: WorldEnvironment, command: bool) -> void:
	var e := we.environment
	if e.background_mode != Environment.BG_SKY:
		return  # the cave keeps its own fog
	e.fog_density = FOG_FPS * (0.25 if command else 1.0)
	e.fog_aerial_perspective = 0.2 if command else 0.7
