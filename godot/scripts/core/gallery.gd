class_name Gallery
## `--gallery`: one of every structure (built), unit and raider tier (plus a Sentinel) in
## rows on a flattened strip south of the landing site, for art screenshots. Raiders and the
## Terp are bare meshes (no AI / no def on this branch). `--gallery=fps` also drops the
## Operative behind a soldier, facing the weapon row (scale check).

const X0 := 20
const X1 := 70
const Z0 := 67
const Z1 := 80
const WEAPON_Z := 70
const WEAPONS := [["cannon", 24], ["mortar", 28], ["beam", 32], ["sniper", 36], ["nullifier", 40],
	["bertha", 45], ["thor", 51], ["forge", 64]]
const TERP := Vector2i(57, 70)
const SUPPORT_Z := 74
const SUPPORT := [["collector", 34], ["relay", 37], ["outpost", 41], ["reactor", 45], ["storage", 48],
	["barracks", 52], ["beacon", 56]]
const RAIDER_Z := 77
## Stage 16 adds this tier; the gallery shows it already.
const SENTINEL := { "name": "Sentinel", "size": 1.0, "color": Color("d04aff") }


static func run(g, mode: String) -> void:
	var w: World = g.surface
	var level := w.grid.height_at(40, 66)
	var edits := []
	for z in range(Z0, Z1):
		for x in range(X0, X1):
			edits.append({ "x": x, "z": z, "height": level })
	TerrainEdit.apply(w, edits)
	for row in WEAPONS:
		var s: Structure = g.structures.place(row[0], row[1], WEAPON_Z, true)
		var tur := s.body.find_child("Turret", true, false) as Node3D
		if tur:
			tur.rotation.y = -0.6  # three-quarter view: heads swing toward the camera
	for row in SUPPORT:
		g.structures.place(row[0], row[1], SUPPORT_Z, true)
	var terp := StructureMeshes.make("terp")
	terp.position = w.grid.cell_ground(TERP.x, TERP.y)
	w.add_child(terp)
	_unit(g, w, "soldier", 25, 73)
	_unit(g, w, "crawler", 29, 74)
	var tiers: Array = RaiderDefs.ROWS.duplicate()
	tiers.append(SENTINEL)
	for i in tiers.size():
		var tier: Dictionary = tiers[i]
		var r := HazardMeshes.raider(tier)
		r.position = w.grid.cell_ground(24 + i * 4, RAIDER_Z)
		r.rotation.y = -PI / 2.0 + 0.7  # three-quarter view toward the command camera
		w.add_child(r)
	g.command.cam.focus(w.grid.cell_ground(43, 73))
	g.command.cam.dist = 70.0
	if mode == "fps":  # the Operative 6 m behind the soldier, looking at the cannon
		DebugHooks._drop(g, 40, 62, 0.0)
		g.fps.controller.spawn(w.grid, 25, 76, 0.12)
		g.fps.controller.pitch = 0.05


static func _unit(g, w: World, type: String, x: int, z: int) -> void:
	var p := w.grid.cell_ground(x, z)
	var u: Unit = g.units.spawn(type, p.x, p.z)
	u.heading = -PI / 2.0 + 0.7
