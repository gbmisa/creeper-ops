class_name SmokeCastles2bFires
## Stage 21b P2: braziers + torches replace the bare interior lights (<= 12 lights per
## castle), cloth banners wire into the view's banners list, and the bailey standard /
## gate-hall banner rise with the stage progress. Fresh level builds only.


static func run(_g) -> void:
	for lvl in [Level01.build(), Level02.build()]:
		var grid: Grid = lvl.grid
		for row in lvl.castles.filter(func(c): return c.layout.get("plan", "") == "concentric"):
			_one(grid, row.id, row.layout)


static func _one(grid: Grid, id: String, lay: Dictionary) -> void:
	var root := Node3D.new()
	var banners: Array = []
	var fires: Array = []
	CastleInteriorMeshes.build(root, grid, lay, banners, fires)
	var kinds := {}
	for f in fires:
		kinds[f.kind] = int(kinds.get(f.kind, 0)) + 1
	var gh := 0
	var hall := 0
	for it in lay.interiors:
		if it.kind == "gatehouse":
			gh += 1
		elif it.kind == "hall":
			hall += 1
	SmokeTest._check("castles2b %s: braziers in every gate hall and the keep hall" % id,
		int(kinds.get("brazier", 0)) == gh + hall, "(%d fires)" % fires.size())
	SmokeTest._check("castles2b %s: two torches per gatehouse, none in towers" % id,
		int(kinds.get("torch", 0)) == 2 * gh)
	SmokeTest._check("castles2b %s: at most 12 lights per castle" % id, fires.size() <= 12,
		"(%d)" % fires.size())
	root.free()
	var r2 := Node3D.new()
	var cloth: Array = []
	var std := CastleBanners.build(r2, grid, lay, cloth)
	var want: int = 3 * (lay.gates.size() + 4 + 2)  # gate fronts, keep faces, standard, gate banner
	SmokeTest._check("castles2b %s: every cloth mesh lands in the banners list" % id,
		cloth.size() == want and cloth.all(func(m): return m is MeshInstance3D),
		"(%d cloth)" % cloth.size())
	_rise(id, std)
	r2.free()


## The standard and the gate banner hoist from the state's stage progress (read-only).
static func _rise(id: String, std: Dictionary) -> void:
	var v := { "standard": std.get("standard"), "gate_banner": std.get("gate_banner") }
	var st: Dictionary = v.standard
	var gb: Dictionary = v.gate_banner
	var ok: bool = st != null and gb != null
	if not ok:
		SmokeTest._check("castles2b %s: standard and gate banner built" % id, false)
		return
	var sn: Node3D = st.node
	var gn: Node3D = gb.node
	CastleBanners.animate_flags(v, { "stage": 1, "ring": { "progress": 0.5 }, "owner": "enemy" })
	var mid := absf(sn.position.y - (float(st.base_y) + 0.5 * float(st.travel))) < 0.01
	CastleBanners.animate_flags(v, { "stage": 2, "ring": { "progress": 0.0 }, "owner": "enemy" })
	var full := absf(sn.position.y - (float(st.base_y) + float(st.travel))) < 0.01
	CastleBanners.animate_flags(v, { "stage": 0, "ring": { "progress": 0.3 }, "owner": "enemy" })
	var gate := absf(gn.position.y - (float(gb.base_y) + 0.3 * float(gb.travel))) < 0.01
	var lowered := absf(sn.position.y - float(st.base_y)) < 0.01
	SmokeTest._check("castles2b %s: the standard rises with bailey progress" % id, mid and full)
	SmokeTest._check("castles2b %s: the gate banner rises with gate progress" % id, gate)
	SmokeTest._check("castles2b %s: a retaken ring lowers its flag" % id, lowered)
