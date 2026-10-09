class_name WeaponModels
## First-person viewmodels. Each looks down -Z and stays inside the old arbalest's
## footprint, so the gun node's screen position and scale can stay put.
## Military palette: furniture is olive polymer (the _wood helpers, ~0.7 rough); metal is
## gunmetal (the _bronze/_iron helpers, 0.8 metallic, 0.35 rough). Helper names predate it.

const WOOD := Color("4f5632")
const WOOD_DARK := Color("33381f")
const BRONZE := Color("5c5d5b")
const IRON := Color("2f3236")


static func _wood() -> StandardMaterial3D:
	return StructureMeshes.mat(WOOD, 0.0, 0.7)


static func _wood_dark() -> StandardMaterial3D:
	return StructureMeshes.mat(WOOD_DARK, 0.0, 0.72)


static func _bronze() -> StandardMaterial3D:
	return StructureMeshes.mat(BRONZE, 0.8, 0.35)


static func _iron() -> StandardMaterial3D:
	return StructureMeshes.mat(IRON, 0.8, 0.35)


static func _named(g: Node3D, id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
	g.add_child(n)
	return n


static func _cyl(g: Node3D, r: float, h: float, m: Material, at: Vector3) -> MeshInstance3D:
	var mi := StructureMeshes.cyl(g, r, r, h, m, 0.0, 10)
	mi.position = at
	return mi


## Thin iron washer around a stock or tube that runs along Z.
static func _band(g: Node3D, at: Vector3, r: float) -> void:
	var mi := _cyl(g, r, 0.016, _iron(), at)
	mi.rotation.x = PI / 2.0


## Fantasy crossbow. Returns the sight crystal; its material is unique because the
## caller recolours the emission when the loadout changes.
static func crossbow(g: Node3D) -> MeshInstance3D:
	var wood := _wood()
	var dark := _wood_dark()
	var bronze := _bronze()
	var iron := _iron()
	# Tiller, thick at the shoulder (+Z) and slim under the prod.
	ShapeKit.taper(g, Vector3(0, 0.0, 0.18), Vector3(0, -0.004, -0.02), 0.046, 0.028, wood, 6)
	ShapeKit.taper(g, Vector3(0, -0.004, -0.02), Vector3(0, 0.0, -0.16), 0.028, 0.02, wood, 6)
	var butt := StructureMeshes.box(g, Vector3(0.11, 0.07, 0.05), dark, Vector3(0, 0.012, 0.24))
	butt.rotation.x = -0.4
	ShapeKit.taper(g, Vector3(0, -0.02, 0.1), Vector3(0, -0.13, 0.15), 0.026, 0.015, dark, 5)
	StructureMeshes.box(g, Vector3(0.05, 0.018, 0.04), dark, Vector3(0, -0.132, 0.155))
	_band(g, Vector3(0, 0.0, 0.15), 0.05)
	_band(g, Vector3(0, -0.004, 0.02), 0.034)
	_band(g, Vector3(0, 0.0, -0.12), 0.026)
	# Bronze riser, then a recurve limb each side: four segments, thick at the centre.
	StructureMeshes.box(g, Vector3(0.05, 0.035, 0.04), bronze, Vector3(0, 0.03, -0.14))
	var tip_r := _limb(g, 1.0, bronze)
	var tip_l := _limb(g, -1.0, bronze)
	var nut := Vector3(0, 0.04, -0.05)
	var string := _named(g, "string")  # moves forward on a shot (OperativeFeel)
	var cord := StructureMeshes.mat_new(Color("c9b88f"), 0.0, 0.7, Color("c9b88f"), 0.12)
	ShapeKit.rod(string, tip_r, nut, 0.005, cord, 4)
	ShapeKit.rod(string, tip_l, nut, 0.005, cord, 4)
	StructureMeshes.box(g, Vector3(0.022, 0.016, 0.02), iron, nut)
	# Loaded bolt: shaft, iron head, two vanes at the nock.
	var bolt := _named(g, "bolt")  # hidden for a moment after each shot
	ShapeKit.taper(bolt, Vector3(0, 0.048, -0.07), Vector3(0, 0.048, -0.34), 0.012, 0.007, wood, 5)
	ShapeKit.taper(bolt, Vector3(0, 0.048, -0.32), Vector3(0, 0.048, -0.44), 0.016, 0.0, iron, 4)
	for sx in [-1.0, 1.0]:
		var vane := StructureMeshes.box(bolt, Vector3(0.01, 0.04, 0.06), dark, Vector3(sx * 0.016, 0.06, -0.1))
		vane.rotation.z = sx * 0.5
	var coil := StructureMeshes.crystal(g, 0.026, 0.11, StructureMeshes.mat_new(Color("3fb8f0"), 0.0, 0.3, Color("2a9fd0"), 0.9), Vector3(0, 0.09, -0.02))
	coil.rotation.x = PI / 2.0
	return coil


## One recurve limb. Returns the tip.
static func _limb(g: Node3D, side: float, m: Material) -> Vector3:
	var pts := PackedVector3Array([
		Vector3(side * 0.03, 0.05, -0.14),
		Vector3(side * 0.11, 0.12, -0.22),
		Vector3(side * 0.2, 0.09, -0.14),
		Vector3(side * 0.28, 0.04, -0.05),
		Vector3(side * 0.32, 0.012, 0.03),
	])
	var radii := [0.036, 0.026, 0.016, 0.01, 0.005]
	for i in 4:
		ShapeKit.taper(g, pts[i], pts[i + 1], radii[i], radii[i + 1], m, 5)
	var tip: Vector3 = pts[4]
	return tip


## Null sprayer: canister, grip, wand, flared nozzle. Not a bow.
static func sprayer(g: Node3D) -> void:
	var bronze := _bronze()
	var iron := _iron()
	var glass := StructureMeshes.mat(Color("3faa22"), 0.15, 0.28, Color("3faa22"), 0.55)
	_cyl(g, 0.058, 0.05, bronze, Vector3(0.01, -0.02, 0.08))
	_cyl(g, 0.04, 0.08, glass, Vector3(0.01, 0.045, 0.08))
	_cyl(g, 0.06, 0.028, iron, Vector3(0.01, 0.1, 0.08))
	ShapeKit.taper(g, Vector3(0, 0.0, 0.05), Vector3(0, -0.12, 0.11), 0.024, 0.014, _wood_dark(), 5)
	ShapeKit.rod(g, Vector3(0.01, 0.04, 0.02), Vector3(0, 0.02, -0.22), 0.011, iron, 6)
	ShapeKit.taper(g, Vector3(0, 0.02, -0.2), Vector3(0, 0.02, -0.36), 0.016, 0.046, bronze, 8)
	var lip := StructureMeshes.torus(g, 0.034, 0.05, iron, Vector3(0, 0.02, -0.35))
	lip.rotation.x = PI / 2.0


## Rocket launcher: a fat tube, muzzle ring, rear bell, stock and grip.
static func launcher(g: Node3D) -> void:
	var iron := _iron()
	var bronze := _bronze()
	var tube := _cyl(g, 0.07, 0.46, iron, Vector3(0, 0.03, -0.02))
	tube.rotation.x = PI / 2.0
	var bore := _cyl(g, 0.042, 0.06, StructureMeshes.mat(Color("1c1916"), 0.5, 0.55), Vector3(0, 0.03, -0.26))
	bore.rotation.x = PI / 2.0
	var ring := StructureMeshes.torus(g, 0.052, 0.078, bronze, Vector3(0, 0.03, -0.25))
	ring.rotation.x = PI / 2.0
	ShapeKit.taper(g, Vector3(0, 0.03, 0.18), Vector3(0, 0.03, 0.32), 0.07, 0.105, bronze, 10)
	_band(g, Vector3(0, 0.03, 0.08), 0.078)
	_band(g, Vector3(0, 0.03, -0.14), 0.078)
	# Stock sits under the tube (tube bottom is about y = -0.04).
	ShapeKit.taper(g, Vector3(0, -0.06, 0.1), Vector3(0, -0.03, 0.3), 0.026, 0.036, _wood(), 5)
	var rest := StructureMeshes.box(g, Vector3(0.09, 0.045, 0.04), _wood_dark(), Vector3(0, -0.02, 0.33))
	rest.rotation.x = -0.35
	ShapeKit.taper(g, Vector3(0, -0.05, 0.02), Vector3(0, -0.13, 0.08), 0.022, 0.014, _wood_dark(), 5)
	var gem := StructureMeshes.crystal(g, 0.018, 0.055, StructureMeshes.mat(Color("ff8a1a"), 0.0, 0.3, Color("ff8a1a"), 0.8), Vector3(0.075, 0.06, 0.0))
	gem.rotation.z = PI / 2.0
