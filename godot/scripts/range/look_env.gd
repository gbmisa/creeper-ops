class_name LookEnv
## Environment per map: HDRI sky, AgX, SDFGI, SSAO / SSIL, glow, light volumetric fog, tuned sun shadows.
## Range = clean base at golden hour; Skirmish = Outpost Kestrel, late-autumn dusk (low warm sun, cold shadows, ground mist).

const MAPS := {
	"range": {
		"hdri": "res://assets/hdri/qwantani_dusk_2_2k.hdr", "sun_rot": Vector3(-14, 25, 0), "sun_col": Color(1.0, 0.7, 0.46), "sun_e": 2.2,
		"amb_e": 3.2, "amb_tint": Color(1.0, 0.96, 0.9), "fog_col": Color(0.75, 0.55, 0.42), "fog_d": 0.0025, "fog_aniso": 0.5, "exp": 1.2,
		"sun_max": 110.0,
		"fill": 0.9, "proc": {"top": Color(0.3, 0.5, 0.82), "horizon": Color(0.98, 0.72, 0.5), "ground": Color(0.5, 0.42, 0.34), "curve": 0.16},
	},
	"skirmish": {
		"hdri": "res://assets/hdri/rogland_sunset_2k.hdr", "sun_rot": Vector3(-9, 150, 0), "sun_col": Color(1.0, 0.62, 0.36), "sun_e": 2.0,
		"amb_e": 1.15, "amb_tint": Color(0.66, 0.76, 1.0), "fog_col": Color(0.55, 0.6, 0.68), "fog_d": 0.011, "fog_aniso": 0.35, "exp": 0.95,
		"sun_max": 140.0,
	},
}


static func build(p: Node3D, map: String) -> void:
	var c: Dictionary = MAPS[map]
	var sky := Sky.new()
	if c.has("proc"):   # range: graded evening sky with a visible sun instead of the flat HDRI
		var pr := ProceduralSkyMaterial.new()
		pr.sky_top_color = c["proc"]["top"]
		pr.sky_horizon_color = c["proc"]["horizon"]
		pr.ground_horizon_color = c["proc"]["horizon"].darkened(0.2)
		pr.ground_bottom_color = c["proc"]["ground"]
		pr.sky_curve = c["proc"]["curve"]
		pr.sun_angle_max = 30.0
		pr.sun_curve = 0.15
		sky.sky_material = pr
	else:
		var pano := PanoramaSkyMaterial.new()
		pano.panorama = load(c["hdri"])
		sky.sky_material = pano
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_color = c["amb_tint"]
	env.ambient_light_energy = c["amb_e"]
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = c["exp"]
	env.tonemap_white = 6.0
	env.sdfgi_enabled = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.5
	env.sdfgi_use_occlusion = true
	env.sdfgi_energy = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 2.0
	env.ssil_enabled = true
	env.ssil_intensity = 0.8
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	env.fog_enabled = true
	env.fog_light_color = c["fog_col"]
	env.fog_density = 0.0006
	env.fog_sky_affect = 0.25
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = c["fog_d"]
	env.volumetric_fog_albedo = c["fog_col"]
	env.volumetric_fog_anisotropy = c["fog_aniso"]
	env.volumetric_fog_length = 120.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	p.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = c["sun_rot"]   # low sun; range keeps its original heading
	sun.light_color = c["sun_col"]
	sun.light_energy = c["sun_e"]
	sun.light_volumetric_fog_energy = 1.5
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = c["sun_max"]
	sun.directional_shadow_split_1 = 0.06
	sun.directional_shadow_split_2 = 0.18
	sun.directional_shadow_split_3 = 0.45
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.5
	p.add_child(sun)
	if c.has("fill"):   # range: shadowless warm fill from the opposite side so the booth, counter and berm faces are not black
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-28, c["sun_rot"].y + 180.0, 0)
		fill.light_color = Color(0.95, 0.85, 0.78)
		fill.light_energy = c["fill"]
		fill.shadow_enabled = false
		fill.light_specular = 0.0
		fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
		p.add_child(fill)
