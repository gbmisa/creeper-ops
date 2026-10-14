class_name RangeTargets
extends Node3D
## All range targets: steel plates, paper silhouettes, armored dummies (15/30/60 m), the penetration wall
## (a dummy behind each panel) and the moving target. Also the armor loadout and reset for all of them.

## x of each lane's target, so nothing stands in another's line of fire
const PLATE_X := [-1.5, 1.5, -1.5, 1.5, -1.5, 1.5]
const DUMMIES := [[15, 5.0], [30, 9.0], [60, 13.0]]
const PAPERS := [[25, 15.0], [50, 17.0]]
## material, thickness (m): the penetration wall, left side of the lane at 20 m
const WALL := [["plywood", 0.02], ["wood_plank", 0.04], ["sheet_metal", 0.01], ["brick", 0.1], ["concrete", 0.15]]
const WALL_X0 := -16.0
const WALL_STEP := 3.0
const WALL_Z := -20.0
const RAIL := Vector3(-9.0, 9.0, 2.5)
const RAIL_Z := -48.0

var plates: Array[SteelPlate] = []
var papers: Array[PaperTarget] = []
var dummies: Array[RangeDummy] = []
var wall_dummies := {}  # material id -> Dummy
var mover: RangeDummy
var loadout := 0


func _init() -> void:
	name = "RangeTargets"


func _ready() -> void:
	for i in RangeLayout.DISTANCES.size():
		var p := SteelPlate.new()
		add_child(p)
		p.setup(RangeLayout.DISTANCES[i], PLATE_X[i])
		plates.append(p)
	for row in PAPERS:
		var t := PaperTarget.new()
		add_child(t)
		t.setup(row[0], row[1])
		papers.append(t)
	for row in DUMMIES:
		_dummy("Dummy %d m" % row[0], Vector3(row[1], 0, -float(row[0])))
	for i in WALL.size():
		var x := WALL_X0 + WALL_STEP * i
		_panel(WALL[i][0], WALL[i][1], x)
		wall_dummies[WALL[i][0]] = _dummy("Wall dummy (%s)" % WALL[i][0], Vector3(x, 0, WALL_Z - 0.9))
	mover = _dummy("Moving 48 m", Vector3(RAIL.x, 0, RAIL_Z))
	mover.rail = RAIL
	_signs()


func _dummy(nm: String, pos: Vector3) -> RangeDummy:
	var d := RangeDummy.new()
	d.label_name = nm
	d.position = pos
	add_child(d)
	dummies.append(d)
	return d


func _panel(mat: String, thick: float, x: float) -> void:
	var col: Color = MaterialDefs.of(mat)["color"]
	RangeLayout.box(self, "panel_" + mat, Vector3(x, 1.1, WALL_Z), Vector3(2.4, 2.2, thick), mat, thick, col)
	var l := Label3D.new()
	l.text = "%s %d cm" % [mat.replace("_", " "), roundi(thick * 100.0)]
	l.pixel_size = 0.007
	l.font_size = 48
	l.outline_size = 10
	l.position = Vector3(x, 2.45, WALL_Z + 0.05)
	l.modulate = Color(1, 0.95, 0.75)
	add_child(l)


func _signs() -> void:
	for row in [["PENETRATION WALL", Vector3(WALL_X0 + WALL_STEP * 2, 3.1, WALL_Z)]]:
		var l := Label3D.new()
		l.text = row[0]
		l.pixel_size = 0.007
		l.font_size = 64
		l.outline_size = 12
		l.position = row[1]
		add_child(l)


## Loadout index into ArmorDefs.LOADOUTS for every dummy.
func set_loadout(idx: int) -> void:
	loadout = idx % ArmorDefs.LOADOUTS.size()
	for d in dummies:
		d.loadout = loadout
		d.set_loadout(loadout)


func reset_all() -> void:
	for p in plates:
		p.reset()
	for t in papers:
		t.reset()
	for d in dummies:
		d.respawn()


## Ballistics.impact on plates and paper. Returns a hit-log line, or "".
func on_impact(info: Dictionary) -> String:
	var p: Vector3 = info["pos"]
	for pl in plates:
		if pl.contains(p):
			pl.hit()
			return "Steel plate %d m | %s | %s" % [pl.dist, info["kind"], info["ammo"]]
	for t in papers:
		if t.contains(p):
			return "Paper %d m | %s | %s" % [t.dist, t.add_mark(p), info["ammo"]]
	return ""
