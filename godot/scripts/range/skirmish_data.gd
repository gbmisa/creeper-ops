class_name SkirmishData
## Skirmish map tables (all coordinates in metres on the 120 x 120 m map, x right, z toward the spawn edge).

const HALF := 60.0
const SPAWN := Vector3(0, 0.05, 54.0)
const RACK_POS := Vector3(-5.0, 0, 59.2)
const EXTRACT := Vector3(0, 0, -52.0)
const EXTRACT_R := 4.0
const EXTRACT_TIME := 2.0
const WALL_H := 4.0

const BRICK := Color(0.55, 0.3, 0.24)
const CONCRETE := Color(0.5, 0.5, 0.47)
const PLASTER := Color(0.62, 0.56, 0.46)
const WOOD := Color(0.45, 0.33, 0.2)
const METAL := Color(0.3, 0.34, 0.3)

## rect [x0, z0, x1, z1], wall height, material, colour, openings per side (door [a, b], window [a, b, sill]), roof
const BUILDINGS := {
	"hotel": {"rect": [-31.0, -15.0, -13.0, -1.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 2,
		"open": {"s": [[-24, -22], [-17, -15]], "n": [[-24, -22]], "e": [[-9, -7]], "w": [[-12, -10]]},
		"open2": {"s": [[-21, -19, 1.0], [-27, -25, 1.0]], "n": [[-21, -19, 1.0]], "e": [[-8, -6, 1.0]]}},
	"barracks": {"rect": [12.0, 0.0, 38.0, 10.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 1,
		"open": {"s": [[16, 18], [30, 32], [21, 23, 1.0], [33, 35, 1.0]], "n": [[24, 26]], "w": [[4, 6]], "e": [[4, 6]]},
		"inner": [["z", 25.0, 0.0, 10.0, [[4, 6]]]]},
	"cottage": {"rect": [-34.0, 26.0, -25.0, 34.0], "h": 3.0, "mat": "plywood", "col": PLASTER, "floors": 1,
		"open": {"s": [[-31, -29]], "e": [[29, 31, 1.0]], "w": [[29, 31]]}},
	"warehouse": {"rect": [18.0, -38.0, 38.0, -26.0], "h": 4.0, "mat": "sheet_metal", "col": METAL, "floors": 1,
		"open": {"s": [[22, 25], [31, 34]], "n": [[26, 28]], "e": [[-33, -31, 1.0]], "w": [[-33, -31]]}},
	"shack": {"rect": [-3.0, -44.0, 3.0, -38.0], "h": 3.0, "mat": "concrete", "col": CONCRETE, "floors": 1,
		"open": {"s": [[-1, 1]], "e": [[-42, -40, 1.0]]}},
}

## [kind, x, z, w, d, h] cover pieces; kind picks material / colour; markers are placed round each one
const COVER := [
	["barrier", -8, 44, 3.0, 0.6, 1.1], ["barrier", 8, 44, 3.0, 0.6, 1.1], ["barrier", 0, 34, 3.0, 0.6, 1.1],
	["barrier", -14, 22, 3.0, 0.6, 1.1], ["barrier", 14, 24, 3.0, 0.6, 1.1], ["barrier", 0, 14, 3.0, 0.6, 1.1],
	["barrier", -45, 20, 3.0, 0.6, 1.1], ["barrier", 46, 28, 3.0, 0.6, 1.1],
	["crate", 4, 28, 1.2, 1.2, 1.2], ["crate", -6, 28, 1.2, 1.2, 1.2], ["crate", 20, 18, 1.4, 1.4, 1.4],
	["crate", -18, 12, 1.2, 1.2, 1.2], ["crate", 8, 2, 1.2, 1.2, 1.2], ["crate", -8, -20, 1.2, 1.2, 1.2],
	["crate", -1, -26, 1.4, 1.4, 1.4], ["crate", 12, -12, 1.2, 1.2, 1.2], ["crate", 45, -10, 1.2, 1.2, 1.2],
	["crate", 46, -12, 1.2, 1.2, 1.2], ["crate", -40, -10, 1.4, 1.4, 1.4], ["crate", -38, -20, 1.2, 1.2, 1.2],
	["crate", -8, -45, 1.2, 1.2, 1.2], ["crate", 10, -46, 1.2, 1.2, 1.2], ["crate", 24, -44, 1.2, 1.2, 1.2],
	["truck", -10, 6, 2.5, 6.5, 2.5], ["truck", 6, -30, 2.5, 6.5, 2.5], ["car", 16, 36, 1.9, 4.4, 1.5],
	["car", -40, 40, 1.9, 4.4, 1.5], ["car", 48, -30, 1.9, 4.4, 1.5],
	["wall", 30, -18, 5.0, 0.4, 1.2], ["wall", -26, 10, 5.0, 0.4, 1.2], ["wall", 40, 14, 0.4, 5.0, 1.2],
]
const COVER_STYLE := {
	"barrier": ["concrete", Color(0.55, 0.55, 0.52)], "crate": ["wood_plank", WOOD], "truck": ["sheet_metal", Color(0.28, 0.34, 0.26)],
	"car": ["sheet_metal", Color(0.4, 0.2, 0.18)], "wall": ["brick", Color(0.5, 0.3, 0.25)],
}

## Tower: platform rect, height, ramp lane x range and its start z.
const TOWER := {"rect": [-51.0, -48.0, -41.0, -40.0], "top": 6.0, "lane_x": [-43.0, -41.0], "ramp_z0": -28.0}

## [x, z, loot]: loot items are {"kind": "ammo" | "meds"} (hook for the inventory branch).
const LOOT := [[-26, -13, ["ammo", "meds"]], [30, 8, ["ammo"]], [-29, 31, ["meds"]], [22, -36, ["ammo", "meds"]],
	[0, -41, ["ammo"]], [0, 50, ["ammo"]]]

## Marksman overwatch spots (x, y, z): tower top, hotel upstairs window.
const SPOTS := [Vector3(-47, 6.0, -44), Vector3(-20, 3.0, -2.6)]

## Enemies: kind, start [x, z], patrol route [[x, z], ...], ally index (-1 none). Boss gets 2 rifleman followers.
const ENEMIES := [
	{"kind": "rifleman", "at": [0, 10], "route": [[-8, 12], [8, 12], [8, 22], [-8, 22]], "ally": 4},
	{"kind": "rifleman", "at": [25, 5], "route": [[16, 5], [34, 5], [30, 13], [20, 13]], "ally": -1},
	{"kind": "rifleman", "at": [-29, 30], "route": [[-29, 30], [-22, 36], [-30, 38]], "ally": -1},
	{"kind": "rifleman", "at": [28, -31], "route": [[22, -31], [34, -31], [28, -22]], "ally": -1},
	{"kind": "rifleman", "at": [0, -20], "route": [[-4, -20], [6, -24], [-2, -14]], "ally": 0},
	{"kind": "pistol", "at": [10, -15], "route": [[10, -15], [16, -8], [8, -4]], "ally": 7},
	{"kind": "pistol", "at": [-14, 28], "route": [[-14, 28], [-6, 32], [-22, 28]], "ally": -1},
	{"kind": "shotgunner", "at": [-22, -12], "route": [[-26, -12], [-18, -12], [-20, -5], [-27, -5]], "ally": 5},
	{"kind": "marksman", "at": [-47, -44], "route": [], "ally": -1},
	{"kind": "boss", "at": [0, -34], "route": [[0, -34], [-10, -36], [8, -36], [0, -46]], "ally": -1},
]
