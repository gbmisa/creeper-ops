class_name TownData
## MAP-3 "Town": 160 x 160 m (HALF 80), x right, z toward the spawn edge (south). Same constant names as SkirmishData, so
## SkirmishLayout / SkirmishGame read either one through their `data` var. docs/tasks/MAP3_town.md has the plan.
## Route: FOB (z 62..80, rack + gate north) -> farm / orchard outskirts -> town (main street x -4..4, market street
## z 4..10, square, walled courtyards, back alleys) -> industrial yard (2.5 m wall, gates S + W) -> extract (0, -74).
## West lanes (x < -62): walled gardens, the slow flank. East (x > 46): cemetery + fields watched by the overwatch.

const HALF := 80.0
const SPAWN := Vector3(0, 0.05, 74.0)
const RACK_POS := Vector3(-5.0, 0, 77.2)
const EXTRACT := Vector3(0, 0, -74.0)
const EXTRACT_R := 4.0
const EXTRACT_TIME := 2.0
const WALL_H := 4.0

const CONCRETE := Color(0.5, 0.5, 0.47)
const PLASTER := Color(0.62, 0.56, 0.46)
const WOOD := Color(0.45, 0.33, 0.2)

const BUILDINGS := TownBuildings.ALL
const COVER := TownCover.ALL
const WALLS := TownWalls.ALL
const ROADS := TownWalls.ROADS

const COVER_STYLE := {
	"barrier": ["concrete", Color(0.55, 0.55, 0.52)], "crate": ["wood_plank", WOOD], "truck": ["sheet_metal", Color(0.28, 0.34, 0.26)],
	"car": ["sheet_metal", Color(0.4, 0.2, 0.18)], "wall": ["brick", Color(0.5, 0.3, 0.25)],
	"container": ["sheet_metal", Color(0.22, 0.34, 0.42)], "tree": ["wood_plank", Color(0.3, 0.22, 0.14)],
	"grave": ["concrete", Color(0.58, 0.58, 0.55)],
}
## Free-standing wall styles: [material, colour].
const WALL_STYLE := {
	"court": ["brick", Color(0.5, 0.34, 0.27)], "hesco": ["concrete", Color(0.55, 0.5, 0.38)], "ditch": ["dirt_berm", Color(0.3, 0.27, 0.17)],
	"yard": ["concrete", Color(0.46, 0.46, 0.44)], "low": ["concrete", Color(0.52, 0.52, 0.48)],
}
const ROAD_COL := Color(0.2, 0.2, 0.21)

## No tower on this map: the overwatch building does the marksman's job.
const TOWER := {}

const LOOT := []
const SPOTS: Array[Vector3] = []
const ENEMIES := []
const PATROL := [Vector2(0, 40), Vector2(0, 7), Vector2(-30, 7), Vector2(30, 7), Vector2(0, -20), Vector2(0, -50)]
