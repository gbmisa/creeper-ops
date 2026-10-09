class_name SmokeCastles2bReadability
## Stage 21b P4: roofs fade while the command view is active, and small progress bars
## float over the gate hall and the bailey standard while that stage runs (read-only on
## c.stage / c.ring). Trebuchet reach on hover: no free terrain-shader ring uniform —
## Suggestions in the progress log, not implemented.


static func run(_g) -> void:
	CastleReadability.set_command_view(true)
	var m := CastleInteriorMeshes.slab_mat()
	var faded: bool = absf(float(m.get_shader_parameter("fade_alpha")) - CastleDefs.ROOF_FADE_ALPHA) < 0.001
	CastleReadability.set_command_view(false)
	var solid: bool = absf(float(m.get_shader_parameter("fade_alpha")) - 1.0) < 0.001
	SmokeTest._check("castles2b readability: roofs fade in command view", faded and solid)
	for lvl in [Level01.build(), Level02.build()]:
		var grid: Grid = lvl.grid
		for row in lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric"):
			_one(grid, row.id, row.layout)


static func _one(grid: Grid, id: String, lay: Dictionary) -> void:
	var root := Node3D.new()
	var banners: Array = []
	var cloth: Dictionary = CastleBanners.build(root, grid, lay, banners)
	var v := {}
	for k in cloth:
		v[k] = cloth[k]
	var marks: Dictionary = CastleReadability.build_markers(root, lay, v)
	for k in marks:
		v[k] = marks[k]
	SmokeTest._check("castles2b %s: progress bars over the gate hall and the standard" % id,
		marks.has("bar_gate") and marks.has("bar_bailey"))
	if not (marks.has("bar_gate") and marks.has("bar_bailey")):
		root.free()
		return
	var bg: Dictionary = v["bar_gate"]
	var bb: Dictionary = v["bar_bailey"]
	CastleReadability.animate_markers(v, { "state": "hostile", "stage": 0, "ring": { "progress": 0.4 } })
	var gate_on: bool = (bg["node"] as Node3D).visible \
		and absf((bg["fg"] as MeshInstance3D).scale.x - 0.4 * float(bg["w"])) < 0.01 \
		and not (bb["node"] as Node3D).visible
	CastleReadability.animate_markers(v, { "state": "hostile", "stage": 1, "ring": { "progress": 0.7 } })
	var bailey_on: bool = (bb["node"] as Node3D).visible \
		and absf((bb["fg"] as MeshInstance3D).scale.x - 0.7 * float(bb["w"])) < 0.01 \
		and not (bg["node"] as Node3D).visible
	CastleReadability.animate_markers(v, { "state": "hostile", "stage": 2, "ring": { "progress": 0.9 } })
	var keep_off: bool = not (bg["node"] as Node3D).visible and not (bb["node"] as Node3D).visible
	CastleReadability.animate_markers(v, { "state": "held", "stage": 2, "ring": { "progress": 0.0 } })
	var held_off: bool = not (bg["node"] as Node3D).visible and not (bb["node"] as Node3D).visible
	SmokeTest._check("castles2b %s: the bars track the running stage" % id,
		gate_on and bailey_on and keep_off and held_off)
	root.free()
