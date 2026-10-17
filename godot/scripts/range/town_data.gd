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

## [x, z, loot]: ammo / meds crates. FOB (0, 70) sits in the gap of the F93 cover pair; the rest are spread along the routes,
## more in the risky spots (municipal, overwatch, yard, extract).
const LOOT := [[0, 70, ["ammo"]], [16, 70, ["meds"]], [-41, 46, ["meds"]], [-23, 55, ["ammo"]], [45, 52, ["ammo"]],
	[-9, -8, ["ammo", "meds"]], [-41, -3, ["meds"]], [33, -4, ["ammo"]], [73, 2.5, ["meds"]], [58, -30, ["ammo", "meds"]],
	[-30, -58, ["ammo", "meds"]], [24, -58, ["ammo"]], [-73, 2, ["ammo"]], [14, -74, ["ammo", "meds"]],
	[-68, -50, ["ammo"]], [-59, -70, ["meds"]]]

## Marksman overwatch spots (x, y, z): overwatch 2F south window, then the municipal 2F square-side window.
const SPOTS: Array[Vector3] = [Vector3(54, 3.0, -23.4), Vector3(-8, 3.5, -3.4)]

## Street lamps [x, z] (post + warm light): FOB gate, barricades, square, yard gate, extract.
const LAMPS := [[-5, 64], [5, 64], [-4.8, 28], [4.8, 28], [-10, 13], [10, 13], [-10, 0], [10, 0], [-12, 51], [-6, -31], [6, -31],
	[-11, -72], [11, -72], [-10, 72], [17, 76]]

## Enemies (rows keep the SkirmishData shape; the boss is the last row so its followers append after the roster):
## checkpoint pair behind the south barricades, two market-street patrols, house / courtyard ambushers, the marksman,
## two Runners flanking (west lanes, orchard), yard guards, annex + municipal ambushers, boss + 2 at the extract.
const ENEMIES := [
	{"kind": "rifleman", "at": [-6, 29], "route": [[-6, 29], [-3, 27]], "ally": 1},
	{"kind": "rifleman", "at": [6, 29], "route": [[6, 29], [3, 27]], "ally": 0},
	{"kind": "rifleman", "at": [-34, 7.5], "route": [[-38, 7.5], [-16, 7.5]], "ally": 3},
	{"kind": "pistol", "at": [18, 8], "route": [[16, 7.5], [42, 7.5]], "ally": 2},
	{"kind": "shotgunner", "at": [-44, -1], "route": [[-44, -1], [-41, -4]], "ally": -1},
	{"kind": "rifleman", "at": [31, 15], "route": [[31, 15], [31, 17]], "ally": -1},
	{"kind": "rifleman", "at": [-40, 25.5], "route": [[-44, 26], [-52, 25]], "ally": -1},
	{"kind": "marksman", "at": [54, -23.4], "route": [], "ally": -1},
	{"kind": "pistol", "at": [-62, -26], "route": [[-62, -26], [-62, -5], [-62, 20], [-62, 30]], "ally": -1},
	{"kind": "pistol", "at": [17.5, 45], "route": [[17.5, 45], [38, 45], [38, 57], [17.5, 57]], "ally": -1},
	{"kind": "rifleman", "at": [-8, -37], "route": [[-8, -37], [8, -37]], "ally": 11},
	{"kind": "shotgunner", "at": [-30, -52], "route": [[-30, -52], [-22, -52]], "ally": 10},
	{"kind": "rifleman", "at": [16, -48], "route": [[16, -48], [26, -48], [26, -56]], "ally": -1},
	{"kind": "rifleman", "at": [-10, -22], "route": [[-10, -22], [-10, -20]], "ally": -1},
	{"kind": "rifleman", "at": [-9, -8], "route": [[-9, -8], [-12, -6]], "ally": -1},
	{"kind": "rifleman", "at": [-59, -58], "route": [[-59, -58], [-59, -56]], "ally": -1},
	{"kind": "shotgunner", "at": [-70, -40], "route": [[-70, -40], [-70, -38]], "ally": -1},
	{"kind": "boss", "at": [0, -76], "route": [[0, -76], [-10, -74], [10, -74], [0, -72]], "ally": -1},
]
const PATROL := [Vector2(0, 40), Vector2(0, 7), Vector2(-30, 7), Vector2(30, 7), Vector2(0, -20), Vector2(0, -50)]
