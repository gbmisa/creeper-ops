class_name RifleModel
## Pulse Rifle viewmodel: a bronze-and-rune energy weapon. Receiver, iron emitter barrel with
## bronze rings and a glowing muzzle ring, a coil crystal on top, wooden stock, pistol grip and
## foregrip. No limbs, no string. Looks down -Z like every viewmodel. Returns the coil crystal
## (its material is unique: OperativeWeapons recolours the emission).

const MUZZLE := Vector3(0, 0.015, -0.47)


static func build(g: Node3D) -> MeshInstance3D:
	var bronze := WeaponModels._bronze()
	var iron := WeaponModels._iron()
	var dark := WeaponModels._wood_dark()
	var wood := WeaponModels._wood()
	var glow := StructureMeshes.mat_new(Color("7fe8ff"), 0.0, 0.3, Color("2a9fd0"), 1.6)
	StructureMeshes.box(g, Vector3(0.07, 0.085, 0.34), bronze, Vector3(0, 0.0, 0.03))
	StructureMeshes.box(g, Vector3(0.05, 0.02, 0.3), iron, Vector3(0, 0.052, 0.03))
	StructureMeshes.box(g, Vector3(0.076, 0.03, 0.12), dark, Vector3(0, -0.01, 0.1))
	for sx in [-1.0, 1.0]:  # rune strips down the flanks
		StructureMeshes.box(g, Vector3(0.004, 0.012, 0.2), glow, Vector3(sx * 0.036, 0.005, 0.0))
	var tube := WeaponModels._cyl(g, 0.03, 0.32, iron, Vector3(0, 0.015, -0.3))
	tube.rotation.x = PI / 2.0
	WeaponModels._band(g, Vector3(0, 0.015, -0.2), 0.038)
	WeaponModels._band(g, Vector3(0, 0.015, -0.33), 0.038)
	ShapeKit.taper(g, Vector3(0, 0.015, -0.44), Vector3(0, 0.015, -0.5), 0.03, 0.046, bronze, 8)
	var ring := StructureMeshes.torus(g, 0.03, 0.046, glow, Vector3(0, 0.015, -0.5))
	ring.rotation.x = PI / 2.0
	var coil := StructureMeshes.crystal(g, 0.026, 0.2, StructureMeshes.mat_new(Color("3fb8f0"), 0.0, 0.3, Color("2a9fd0"), 0.9), Vector3(0, 0.085, -0.04))
	coil.rotation.x = PI / 2.0
	ShapeKit.taper(g, Vector3(0, 0.0, 0.2), Vector3(0, -0.015, 0.4), 0.045, 0.03, wood, 6)
	StructureMeshes.box(g, Vector3(0.07, 0.11, 0.035), dark, Vector3(0, -0.02, 0.41)).rotation.x = -0.25
	ShapeKit.taper(g, Vector3(0, -0.03, 0.12), Vector3(0, -0.15, 0.16), 0.026, 0.017, dark, 5)
	StructureMeshes.box(g, Vector3(0.05, 0.07, 0.06), dark, Vector3(0, -0.06, -0.15))  # foregrip
	return coil
