class_name SkirmishData
## Skirmish map tables (all coordinates in metres on the 120 x 120 m map, x right, z toward the spawn edge).
## Layout (MAP-2, docs/tasks/SKIRMISH_MAP2.md): WEST = close-quarters old town (three columns of buildings,
## back alley on the wall, inner alley, cross streets) cut by the straight "sniper street" (x -50..-44) that the
## tower at its north end looks down; CENTRE = the checkpoint lane to the extract; EAST = open ground with two
## buildings (barracks, warehouse) and spaced cover (containers, low walls, cars) for bounding.

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

## rect [x0, z0, x1, z1], wall height, material, colour, openings per side (n/s: x coords, e/w: z coords; door [a, b],
## window [a, b, sill]). inner: [axis, fixed (absolute), from, to (relative to the rect corner), openings (absolute)].
const BUILDINGS := {
	# --- centre / east (unchanged) ---
	"hotel": {"rect": [-31.0, -15.0, -13.0, -1.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 2,
		"open": {"s": [[-24, -22], [-17, -15]], "n": [[-24, -22]], "e": [[-9, -7]], "w": [[-12, -10]]},
		"open2": {"s": [[-21, -19, 1.0], [-27, -25, 1.0]], "n": [[-21, -19, 1.0]], "e": [[-8, -6, 1.0]]}},
	"barracks": {"rect": [12.0, 0.0, 38.0, 10.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 1,
		"open": {"s": [[16, 18], [30, 32], [21, 23, 1.0], [33, 35, 1.0]], "n": [[24, 26]], "w": [[4, 6]], "e": [[4, 6]]},
		"inner": [["z", 25.0, 0.0, 10.0, [[4, 6]]]]},
	"warehouse": {"rect": [18.0, -38.0, 38.0, -26.0], "h": 4.0, "mat": "sheet_metal", "col": METAL, "floors": 1,
		"open": {"s": [[22, 25], [31, 34]], "n": [[26, 28]], "e": [[-33, -31, 1.0]], "w": [[-33, -31]]}},
	"shack": {"rect": [-3.0, -44.0, 3.0, -38.0], "h": 3.0, "mat": "concrete", "col": CONCRETE, "floors": 1,
		"open": {"s": [[-1, 1]], "e": [[-42, -40, 1.0]]}},
	# --- west old town, column 1 (x -57..-50; back alley behind it on the wall) ---
	"garage": {"rect": [-57.0, 20.0, -50.0, 32.0], "h": 3.5, "mat": "sheet_metal", "col": METAL, "floors": 1,
		"open": {"e": [[23, 27]], "w": [[29, 31]], "n": [[-55, -53]], "s": [[-55, -53, 1.0]]}},
	"storehouse": {"rect": [-57.0, -2.0, -50.0, 12.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 1,
		"open": {"e": [[0, 2], [8, 10, 1.0]], "w": [[7, 9]], "n": [[-55, -53]], "s": [[-54, -52]]},
		"inner": [["x", 5.0, 0.0, 7.0, [[-54.5, -52.5]]]]},
	"pumphouse": {"rect": [-57.0, -22.0, -51.0, -14.0], "h": 3.0, "mat": "concrete", "col": CONCRETE, "floors": 1,
		"open": {"e": [[-19, -17]], "n": [[-55, -53]], "s": [[-55, -53, 1.0]]}},
	# --- column 2 (x -44..-34, across the sniper street) ---
	"cottage": {"rect": [-44.0, 26.0, -35.0, 34.0], "h": 3.0, "mat": "plywood", "col": PLASTER, "floors": 1,
		"open": {"s": [[-41, -39]], "n": [[-38, -36]], "w": [[29, 31]], "e": [[29, 31, 1.0]]}},
	"clinic": {"rect": [-44.0, 4.0, -34.0, 18.0], "h": 3.0, "mat": "plywood", "col": PLASTER, "floors": 1,
		"open": {"w": [[6, 8], [14, 16, 1.0]], "e": [[13, 15], [6, 8, 1.0]], "s": [[-38, -36]], "n": [[-42, -40]]},
		"inner": [["x", 11.0, 0.0, 10.0, [[-40, -38]]]]},
	"bunkhouse": {"rect": [-44.0, -24.0, -34.0, -10.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 1,
		"open": {"w": [[-14, -12]], "e": [[-22, -20], [-15, -13, 1.0]], "n": [[-37, -35]], "s": [[-42, -40]]},
		"inner": [["z", -39.0, 0.0, 14.0, [[-18, -16]]]]},
	# --- column 3 (x -30..-18, round the hotel; the inner alley runs between columns 2 and 3) ---
	"row_a": {"rect": [-30.0, 4.0, -22.0, 14.0], "h": 3.0, "mat": "brick", "col": BRICK, "floors": 1,
		"open": {"s": [[-27, -25]], "n": [[-25, -23]], "e": [[8, 10]], "w": [[10, 12, 1.0]]}},
	"workshop": {"rect": [-30.0, 22.0, -20.0, 32.0], "h": 3.5, "mat": "sheet_metal", "col": METAL, "floors": 1,
		"open": {"s": [[-28, -24]], "n": [[-26, -24]], "e": [[25, 28]], "w": [[26, 28, 1.0]]}},
	"office": {"rect": [-30.0, -34.0, -18.0, -22.0], "h": 3.0, "mat": "concrete", "col": CONCRETE, "floors": 1,
		"open": {"s": [[-28, -26], [-22, -20, 1.0]], "n": [[-25, -23]], "e": [[-30, -28]], "w": [[-26, -24]]},
		"inner": [["z", -24.0, 0.0, 12.0, [[-30, -28]]]]},
}

## [kind, x, z, w, d, h] cover pieces; kind picks material / colour; markers are placed round each one
const COVER := [
	# centre lane (and the original east pieces)
	["barrier", -8, 44, 3.0, 0.6, 1.1], ["barrier", 8, 44, 3.0, 0.6, 1.1], ["barrier", 0, 34, 3.0, 0.6, 1.1],
	["barrier", -14, 22, 3.0, 0.6, 1.1], ["barrier", 14, 24, 3.0, 0.6, 1.1], ["barrier", 0, 14, 3.0, 0.6, 1.1],
	["barrier", -45, 20, 3.0, 0.6, 1.1], ["barrier", 46, 28, 3.0, 0.6, 1.1],
	["crate", 4, 28, 1.2, 1.2, 1.2], ["crate", -6, 28, 1.2, 1.2, 1.2], ["crate", 20, 18, 1.4, 1.4, 1.4],
	["crate", -18, 12, 1.2, 1.2, 1.2], ["crate", 8, 2, 1.2, 1.2, 1.2], ["crate", -8, -20, 1.2, 1.2, 1.2],
	["crate", -1, -26, 1.4, 1.4, 1.4], ["crate", 12, -12, 1.2, 1.2, 1.2], ["crate", 45, -10, 1.2, 1.2, 1.2],
	["crate", 46, -12, 1.2, 1.2, 1.2], ["crate", -40, -6, 1.4, 1.4, 1.4], ["crate", -38, -20, 1.2, 1.2, 1.2],
	["crate", -8, -45, 1.2, 1.2, 1.2], ["crate", 10, -46, 1.2, 1.2, 1.2], ["crate", 24, -44, 1.2, 1.2, 1.2],
	["truck", -10, 6, 2.5, 6.5, 2.5], ["truck", 6, -30, 2.5, 6.5, 2.5], ["car", 16, 36, 1.9, 4.4, 1.5],
	["car", -40, 40, 1.9, 4.4, 1.5], ["car", 48, -30, 1.9, 4.4, 1.5],
	["wall", 30, -18, 5.0, 0.4, 1.2], ["wall", 40, 14, 0.4, 5.0, 1.2],
	# F93: standing-height cover at the spawn (gap for the loot crate at 0, 50) and along the three early lanes
	["barrier", -2.5, 51.5, 3.0, 0.6, 1.8], ["barrier", 2.5, 51.5, 3.0, 0.6, 1.8],
	["truck", -12, 42, 2.5, 6.5, 2.5], ["wall", 12, 41, 4.0, 0.4, 1.8], ["barrier", 0, 26, 3.0, 0.6, 1.8],
	# MAP-2 west: hops along the sniper street, plaza, market street, interiors, the approach to the extract
	["car", -47, 8, 1.9, 4.4, 1.5], ["barrier", -48, -4, 3.0, 0.6, 1.1], ["crate", -47, -18, 1.2, 1.2, 1.2],
	["barrier", -47, 32, 3.0, 0.6, 1.1], ["wall", -35.5, 1.5, 3.0, 0.4, 1.2], ["wall", -36.5, 21, 0.4, 3.0, 1.2],
	["car", -53.5, 26, 1.9, 4.4, 1.5], ["crate", -36.5, 8, 1.2, 1.2, 1.2], ["crate", -25, 27, 1.2, 1.2, 1.2],
	["crate", -21, -30, 1.2, 1.2, 1.2], ["crate", -36, -30, 1.4, 1.4, 1.4], ["crate", -32, -37, 1.2, 1.2, 1.2],
	["barrier", -22, -39, 3.0, 0.6, 1.1], ["crate", -14, -28, 1.2, 1.2, 1.2], ["wall", -10, -40, 0.4, 4.0, 1.2],
	["barrier", -52, 42, 3.0, 0.6, 1.1], ["crate", -30, 39, 1.2, 1.2, 1.2], ["barrier", -22, 44, 3.0, 0.6, 1.1],
	# MAP-2 east: open ground, cover spaced for bounding; the east wall run stays sparse
	["container", 30, 32, 2.4, 6.0, 2.6], ["wall", 26, 22, 4.0, 0.4, 1.2], ["car", 52, 40, 1.9, 4.4, 1.5],
	["barrier", 36, 40, 3.0, 0.6, 1.1], ["crate", 44, 22, 1.2, 1.2, 1.2], ["barrier", 54, 16, 3.0, 0.6, 1.1],
	["container", 22, -14, 6.0, 2.4, 2.6], ["barrier", 40, -20, 3.0, 0.6, 1.1], ["crate", 52, -20, 1.2, 1.2, 1.2],
	["wall", 34, -6, 4.0, 0.4, 1.2], ["barrier", 40, -46, 3.0, 0.6, 1.1], ["wall", 48, -42, 0.4, 4.0, 1.2],
	["crate", 14, -36, 1.2, 1.2, 1.2],
]
const COVER_STYLE := {
	"barrier": ["concrete", Color(0.55, 0.55, 0.52)], "crate": ["wood_plank", WOOD], "truck": ["sheet_metal", Color(0.28, 0.34, 0.26)],
	"car": ["sheet_metal", Color(0.4, 0.2, 0.18)], "wall": ["brick", Color(0.5, 0.3, 0.25)],
	"container": ["sheet_metal", Color(0.22, 0.34, 0.42)],
}

## Tower: platform rect, height, ramp lane x range and its start z. It stands at the north end of the sniper street.
const TOWER := {"rect": [-51.0, -48.0, -41.0, -40.0], "top": 6.0, "lane_x": [-43.0, -41.0], "ramp_z0": -28.0}

## [x, z, loot]: loot items are {"kind": "ammo" | "meds"} (hook for the inventory branch).
const LOOT := [[-26, -13, ["ammo", "meds"]], [30, 8, ["ammo"]], [-41, 15, ["meds"]], [22, -36, ["ammo", "meds"]],
	[0, -41, ["ammo"]], [0, 50, ["ammo"]], [-54, 30, ["ammo"]], [-27, -31, ["meds"]]]

## Marksman overwatch spots (x, y, z): tower top, hotel upstairs window.
const SPOTS := [Vector3(-47, 6.0, -44), Vector3(-20, 3.0, -2.6)]

## Enemies: kind, start [x, z], patrol route [[x, z], ...], ally index (-1 none). Boss gets 2 rifleman followers.
## MAP-2: the west rifleman and both Runners patrol the old town (streets, alleys, interiors); the rest are unchanged.
const ENEMIES := [
	{"kind": "rifleman", "at": [0, 10], "route": [[-8, 12], [8, 12], [8, 22], [-8, 22]], "ally": 4},
	{"kind": "rifleman", "at": [25, 5], "route": [[16, 5], [34, 5], [30, 13], [20, 13]], "ally": -1},
	{"kind": "rifleman", "at": [-39, 22], "route": [[-39, 22], [-47, 22], [-47, 36], [-36, 38]], "ally": -1},
	{"kind": "rifleman", "at": [28, -31], "route": [[22, -31], [34, -31], [28, -22]], "ally": -1},
	{"kind": "rifleman", "at": [0, -20], "route": [[-4, -20], [6, -24], [-2, -14]], "ally": 0},
	{"kind": "pistol", "at": [-37, -3], "route": [[-37, -3], [-32.5, 10], [-32.5, 20], [-38, -8]], "ally": 7},
	{"kind": "pistol", "at": [-18, 18], "route": [[-18, 18], [-26, 18], [-26, 9], [-17, 8]], "ally": -1},
	{"kind": "shotgunner", "at": [-22, -12], "route": [[-26, -12], [-18, -12], [-20, -5], [-27, -5]], "ally": 5},
	{"kind": "marksman", "at": [-47, -44], "route": [], "ally": -1},
	{"kind": "boss", "at": [0, -34], "route": [[0, -34], [-10, -36], [8, -36], [0, -46]], "ally": -1},
]
