class_name CreatureGallery
## `--gallery=anim`: every creature model id in a row with Label3D labels, cycling
## animation clips every 2 s, for art screenshots of Opus's .glb work. Falls back to
## the procedural meshes when no .glb is present (the row still lays out).

const IDS := ["skitter", "spitter", "brute", "lancer", "burrower", "warden",
	"ravager", "spotter", "behemoth", "sentinel",
	"spore_bat", "gasbag", "wyvern", "soldier", "crawler", "hive_core"]
const CLIPS := ["idle", "walk", "attack", "hit", "die"]
const CYCLE := 2.0
const SPACING := 6.0
const X0 := 10.0
const Z := 86.0
const STRIP_X0 := 8
const STRIP_Z0 := 82
const STRIP_Z1 := 92


## Flatten the gallery strip south of everything on L1 (no castles, hives or
## landing zone there). Returns the level it was flattened to.
static func flatten(w: World) -> float:
	var grid: Grid = w.grid
	var level: float = grid.height_at(20, 86)
	var width := int(IDS.size() * SPACING) + 8
	var edits := []
	for z in range(STRIP_Z0, STRIP_Z1):
		for x in range(STRIP_X0, STRIP_X0 + width):
			edits.append({ "x": x, "z": z, "height": level })
	TerrainEdit.apply(w, edits)
	return level


static func run(g, only_id := "") -> void:
	var w: World = g.surface
	var grid: Grid = w.grid
	flatten(w)
	var ids: Array = IDS if only_id.is_empty() else [only_id]
	var driver := Driver.new()
	driver.name = "CreatureGallery"
	var xi := int(X0)
	var first_node: Node3D = null
	for id in ids:
		var spec := _spec(id)
		if spec.is_empty():
			continue
		var node: Node3D = CreatureAnim.make(id, float(spec.scale), spec.glow)
		if node == null:
			node = (spec.proc as Callable).call()
		node.position = grid.cell_ground(xi, int(Z))
		node.rotation.y = -PI / 2.0 + 0.7  # three-quarter view toward the command camera
		var label := Label3D.new()
		label.text = id
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 72
		label.position = Vector3(0, _label_h(id), 0)
		node.add_child(label)
		w.add_child(node)
		driver.items.append(node)
		if first_node == null:
			first_node = node
		xi += int(SPACING)
	w.add_child(driver)
	if only_id.is_empty():
		# Full row: focus the middle of the row in metres (the old code mixed
		# cells and metres), far enough back to fit ~100 m of models.
		var mid := grid.cell_ground(int(X0 + (xi - X0) * 0.5), int(Z))
		g.command.cam.focus(mid + Vector3(0, 2.0, 0))
		g.command.cam.dist = 115.0
	elif first_node != null:
		# Close-up: flyers hover, so aim at the model's AABB centre, not its feet.
		g.command.cam.focus(_aabb_centre(first_node))
		g.command.cam.dist = 18.0


## World-space centre of a model's meshes (for aiming the close-up camera).
static func _aabb_centre(node: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var a: AABB = m.global_transform * m.get_aabb()
		if first:
			box = a
		else:
			box = box.merge(a)
		first = false
	return box.get_center() if not first else node.global_position


## `--creatures`: one of each raider tier in a row near the command node, idle
## clips playing — for art screenshots of the .glb work in situ (A2).
## `--creatures=near`: also a row of the six hive part models behind them (A3).
static func spawn_near_base(g, mode := "") -> void:
	var w: World = g.surface
	var grid: Grid = w.grid
	var n0 = g.structures.command_node()
	var z0: int = int(n0.z) + 8
	var x: int = int(n0.x) - RaiderDefs.ROWS.size() * 2
	for tier in RaiderDefs.ROWS:
		var node := RaiderMeshes.make(tier)
		node.position = grid.cell_ground(x, z0)
		node.rotation.y = -PI / 2.0 + 0.7  # three-quarter view toward the command camera
		w.add_child(node)
		CreatureAnim.move(node, 0.0)  # idle clip when a model is present
		x += 4
	if str(mode) == "near":
		var hx: int = int(n0.x) - 15
		for kind in ["core", "pit", "spitter", "launcher", "mortar", "roost"]:
			var part := HiveMeshes.part(kind)
			part.position = grid.cell_ground(hx, z0 + 8)
			w.add_child(part)
			var model := CreatureAnim.of(part)
			if model != null:
				CreatureAnim.move(model, 0.0)
			hx += 5


static func _label_h(id: String) -> float:
	match id:
		"behemoth", "sentinel":
			return 4.5
		"gasbag", "wyvern":
			return 4.0
		_:
			return 3.0


static func _spec(id: String) -> Dictionary:
	for d in RaiderDefs.ROWS:
		if CreatureAnim.id_of(str(d.name)) == id:
			var tier: Dictionary = d
			return { "scale": RaiderMeshes.anim_scale(tier),
				"glow": CreatureAnim.creature_glow(tier.color),
				"proc": func() -> Node3D: return RaiderMeshes.make(tier) }
	if id == "sentinel":  # not in RAIDER_TIERS yet; same dict the old gallery uses
		var scol := Color("d04aff")
		return { "scale": 1.0, "glow": CreatureAnim.creature_glow(scol),
			"proc": func() -> Node3D: return RaiderMeshes.make({ "name": "Sentinel", "size": 1.0, "color": scol }) }
	for d in FlyerDefs.ROWS:
		if CreatureAnim.id_of(str(d.name)) == id:
			var row: Dictionary = d
			return { "scale": float(row.size), "glow": CreatureAnim.creature_glow(row.color),
				"proc": func() -> Node3D: return FlyerMeshes.make(row) }
	if id == "soldier" or id == "crawler":
		return { "scale": 1.0, "glow": CreatureAnim.creature_glow(Color("9dff7a")),
			"proc": func() -> Node3D: return UnitMeshes.make(id) }
	if id == "hive_core":
		return { "scale": 1.0, "glow": StructureMeshes.glow(Color("ff3355"), 1.4),
			"proc": func() -> Node3D: return HiveMeshes.part("core") }
	return {}


static func play_clip(node: Node3D, clip: String) -> void:
	match clip:
		"walk":
			CreatureAnim.move(node, 1.0)
		"idle":
			CreatureAnim.move(node, 0.0)
		"attack":
			CreatureAnim.attack(node)
		"hit":
			CreatureAnim.hit(node)
		"die":
			CreatureAnim.die(node, func() -> void: pass)


class Driver extends Node3D:
	var items: Array[Node3D] = []
	var t := 0.0
	var clip_i := 0

	func _process(dt: float) -> void:
		t += dt
		if t < CreatureGallery.CYCLE:
			return
		t = 0.0
		clip_i = (clip_i + 1) % CreatureGallery.CLIPS.size()
		var clip: String = CreatureGallery.CLIPS[clip_i]
		for n in items:
			CreatureGallery.play_clip(n, clip)
