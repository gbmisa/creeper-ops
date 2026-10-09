class_name CastleReadability
## Stage 21b P4: command-view readability. Roof slabs fade while the command view is
## active (one-line hook in GameFlow.set_mode next to WorldLook.set_command_view, via
## the fade_alpha uniform on the shared slab ShaderMaterial). Small progress bars float
## over the gate hall and the bailey standard while that stage runs, paired with
## CastleBanners' standard/gate_banner descriptors (read-only on c.stage / c.ring).
## Trebuchet reach on hover: no free terrain-shader ring uniform exists (ring_a/ring_b
## are selection/ghost, shells[8] is mortar/telegraph) — logged under Suggestions.


## Called from GameFlow.set_mode: fade the shared slab material in/out.
static func set_command_view(on: bool) -> void:
	CastleInteriorMeshes.slab_mat().set_shader_parameter("fade_alpha",
		CastleDefs.ROOF_FADE_ALPHA if on else 1.0)


## Two horizontal progress bars; returns { bar_gate?, bar_bailey? } descriptors.
## Needs v["standard"] / v["gate_banner"] from CastleBanners (absent on Stage 7 rows).
static func build_markers(root: Node3D, lay: Dictionary, v: Dictionary) -> Dictionary:
	var out := {}
	if lay.get("plan", "") != "concentric":
		return out
	var stages: Array = lay.get("stages", [])
	if v.has("gate_banner"):
		var gb: Dictionary = v["gate_banner"]
		var gp: Vector3 = (gb["node"] as Node3D).position
		var gy: float = float(gb["base_y"]) + float(gb["travel"]) + 3.4
		out["bar_gate"] = _bar(root, Vector3(gp.x, gy, gp.z), stages.find("gate"))
	if v.has("standard"):
		var st: Dictionary = v["standard"]
		var sp: Vector3 = (st["node"] as Node3D).position
		var sy: float = float(st["base_y"]) + CastleDefs.STANDARD_H + 1.4
		out["bar_bailey"] = _bar(root, Vector3(sp.x, sy, sp.z), stages.find("bailey"))
	return out


## A dark back bar and an amber fill bar (fill anchored left, scaled by progress).
static func _bar(root: Node3D, at: Vector3, stage_idx: int) -> Dictionary:
	var node := Node3D.new()
	node.position = at
	node.visible = false
	root.add_child(node)
	var w := CastleDefs.STAGE_BAR_W
	StructureMeshes.box(node, Vector3(w + 0.3, 0.14, 0.55),
		StructureMeshes.mat(Color("14161c"), 0.2, 0.8), Vector3.ZERO)
	var fg := StructureMeshes.box(node, Vector3(1, 0.18, 0.36),
		StructureMeshes.mat(Color("ffb347"), 0.0, 0.5, Color("ffb347"), 0.8), Vector3.ZERO)
	return { "node": node, "fg": fg, "w": w, "stage_idx": stage_idx }


## Show the running stage's bar, filled by ring.progress (read-only).
static func animate_markers(v: Dictionary, c: Dictionary) -> void:
	for key in ["bar_gate", "bar_bailey"]:
		if not v.has(key):
			continue
		var d: Dictionary = v[key]
		var idx: int = d["stage_idx"]
		var running: bool = c.get("state") == "hostile" and idx >= 0 and int(c.get("stage", 99)) == idx
		var node: Node3D = d["node"]
		node.visible = running
		if not running:
			continue
		var p := clampf(float((c.get("ring", {}) as Dictionary).get("progress", 0.0)), 0.0, 1.0)
		var fg: MeshInstance3D = d["fg"]
		var w: float = d["w"]
		fg.scale.x = maxf(p, 0.001) * w
		fg.position.x = -w * 0.5 + fg.scale.x * 0.5
