class_name EnemyStructures
## Enemy structure table (§4.5). The hub spends build progress, not packets.
## `cost` 1 finishes in ENEMY_BUILD_BASE seconds when every multiplier is 1.
## Rubble rebuilds at half that cost. Ore deposits (and Miners) arrive in Stage 9a.


const WEAVER_HP := 12.0
const SHELL_MORTAR := 18.0
const SHELL_BERTHA := 100.0
const DEFS := {
	"leech": {"label": "Leech", "hp": 60.0, "cost": 1.0, "color": Color("c45cff")},
	"pylon": {"label": "Blight Pylon", "hp": 80.0, "cost": 1.0, "radius": 6.0, "color": Color("6a3a8a")},
	"spitter": {"label": "Spitter Tower", "hp": 70.0, "cost": 1.0, "salvage": 0.0, "color": Color("d6ff3a")},
	"lancer": {"label": "Lancer Spire", "hp": 90.0, "cost": 1.0, "range": 32.0, "damage": 25.0,
		"interval": 1.5, "color": Color("e6d2ff")},
	"dome": {"label": "Shield Dome", "hp": 120.0, "cost": 1.0, "radius": 8.0, "lance": 0.5, "no_charge": true,
		"color": Color("d4a6ff")},
	"pump": {"label": "Creeper Pump", "hp": 100.0, "cost": 1.0, "amount": 1.0, "every": 2.0,
		"color": Color("3d7bff")},
	"mortar": {"label": "Enemy Mortar", "hp": 80.0, "cost": 1.0, "color": Color("ff6a4a")},
}


static func slots(pressure: float) -> int:
	return 2 if pressure >= Config.ENEMY_SLOTS_PRESSURE else 1


## Progress per second. A full moat (intake == PUMP_REF) doubles the base rate.
static func rate(intake: float, depth: float, leeches: int, pressure: float) -> float:
	var pump := 1.0 + maxf(0.0, intake) / Config.PUMP_REF
	var creep := 1.0 + maxf(0.0, depth) * 0.25
	var mine := 1.0 + 0.25 * float(maxi(leeches, 0))
	return Config.ENEMY_BUILD_BASE * pump * creep * mine * (1.0 + maxf(0.0, pressure))


static func mesh(kind: String) -> Node3D:
	var root := Node3D.new()
	var def: Dictionary = DEFS[kind]
	var col: Color = def.color
	var body := StructureMeshes.mat(col.darkened(0.45), 0.35, 0.5)
	var glow := StructureMeshes.glow(col, 1.3)
	match kind:
		"leech":
			StructureMeshes.ball(root, 0.42, glow, Vector3(0, 0.45, 0), 8)
		"pylon":
			StructureMeshes.cyl(root, 0.28, 0.45, 2.4, body, 0.0, 6)
			StructureMeshes.ball(root, 0.26, glow, Vector3(0, 2.5, 0), 8)
		"spitter":
			StructureMeshes.cyl(root, 0.55, 0.4, 1.1, body, 0.0, 7)
			StructureMeshes.ball(root, 0.32, glow, Vector3(0.55, 1.15, 0), 8)
		"lancer":
			StructureMeshes.cyl(root, 0.16, 0.42, 3.4, body, 0.0, 6)
			StructureMeshes.ball(root, 0.2, glow, Vector3(0, 3.5, 0), 8)
		"dome":
			var shell := HazardMeshes.shield(2.4)
			shell.position.y = 1.3
			root.add_child(shell)
		"pump":
			StructureMeshes.cyl(root, 0.7, 0.45, 0.9, body, 0.0, 8)
			StructureMeshes.ball(root, 0.32, glow, Vector3(0, 1.15, 0), 8)
		_:
			StructureMeshes.cyl(root, 0.5, 0.35, 0.7, body, 0.0, 8)
			StructureMeshes.cyl(root, 0.12, 0.12, 1.3, glow, 0.5, 6)
	return root


static func weaver() -> Node3D:
	var root := Node3D.new()
	StructureMeshes.ball(root, 0.26, StructureMeshes.glow(Color("e8d0ff"), 1.5), Vector3(0, 0.55, 0), 8)
	return root
