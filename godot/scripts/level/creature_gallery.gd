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


static func run(g) -> void:
	var w: World = g.surface
	var grid: Grid = w.grid
	var level: float = grid.height_at(20, 86)
	var width := int(IDS.size() * SPACING) + 8
	var edits := []
	for z in range(82, 92):
		for x in range(8, 8 + width):
			edits.append({ "x": x, "z": z, "height": level })
	TerrainEdit.apply(w, edits)
	var driver := Driver.new()
	driver.name = "CreatureGallery"
	var xi := int(X0)
	for id in IDS:
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
		xi += int(SPACING)
	w.add_child(driver)
	g.command.cam.focus(Vector3((X0 + xi) * 0.5, grid.cell_ground(20, 86).y, Z))
	g.command.cam.dist = 70.0


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
				"glow": StructureMeshes.glow(tier.color, 1.0),
				"proc": func() -> Node3D: return RaiderMeshes.make(tier) }
	if id == "sentinel":  # not in RAIDER_TIERS yet; same dict the old gallery uses
		var scol := Color("d04aff")
		return { "scale": 1.0, "glow": StructureMeshes.glow(scol, 1.0),
			"proc": func() -> Node3D: return RaiderMeshes.make({ "name": "Sentinel", "size": 1.0, "color": scol }) }
	for d in FlyerDefs.ROWS:
		if CreatureAnim.id_of(str(d.name)) == id:
			var row: Dictionary = d
			return { "scale": float(row.size), "glow": StructureMeshes.glow(row.color, 1.1),
				"proc": func() -> Node3D: return FlyerMeshes.make(row) }
	if id == "soldier" or id == "crawler":
		return { "scale": 1.0, "glow": StructureMeshes.glow(Color("9dff7a"), 2.0),
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
