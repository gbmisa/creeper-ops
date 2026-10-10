class_name EngineDefs
extends RefCounted
## Salvage Engines (Stage 9b): ancient machines the Operative hooks into from first person.
## Level rows are { id, x, z, kind, reserve?, hive?, castle? } in the level's `engines` list.
##   hive: "<hive name>"   ships nothing until that hive is razed
##   castle: "<castle id>" ships only while the player holds that castle
## Body cells are raised `top` levels over the floor (solid to everyone). A stair of one-level
## steps climbs the south face to the top (walkers go up one level at a time).
## Sockets: face = "top" | "n" | "s" | "e" | "w"; u = cells along the face from the centre;
## level = floor-relative height of the ground the Operative stands on; lift = metres up.

const HOOK_TIME := 2.5        # seconds holding E
const HOOK_RANGE := 1.5       # metres from the socket (horizontal)
const HOOK_REACH_Y := 1.7     # metres of height difference (chest to socket) still in reach
const LINK := 8.0             # cells: a connected relaying structure must be this close
const RATE := 6.0             # seconds per Salvage, per hooked socket
const HIVE_R := 9.0           # an engine this close to a live hive counts as inside it
const CAVE_CASH := 0.4        # cave engines pay this share of their reserve once, by hand
const KINDS := {
	"wreck": { "name": "Fallen Titan", "w": 5, "d": 3, "top": 4, "stair": true, "reserve": 120.0,
		"sockets": [ { "face": "top", "u": 0.0, "lift": 0.9 }, { "face": "n", "u": 1.0, "level": 0, "lift": 1.5 } ] },
	"bore": { "name": "Buried Bore", "w": 3, "d": 3, "top": 3, "stair": false, "reserve": 60.0,
		"sockets": [ { "face": "s", "u": 0.0, "level": 0, "lift": 1.4 } ] },
	"forge": { "name": "Ruined Forge", "w": 5, "d": 5, "top": 4, "stair": true, "reserve": 250.0,
		"sockets": [ { "face": "top", "u": 0.0, "lift": 0.9 }, { "face": "e", "u": 0.0, "level": 0, "lift": 1.5 },
			{ "face": "s", "u": -1.0, "level": 2, "lift": 1.1 } ] },
}


static func kind(row: Dictionary) -> Dictionary:
	return KINDS[str(row.kind)]


static func reserve_of(row: Dictionary) -> float:
	return float(row.get("reserve", kind(row).reserve))


## Footprint cells (the solid body) of a row, from its centre cell.
static func body_cells(row: Dictionary) -> Array[Vector2i]:
	var k := kind(row)
	var out: Array[Vector2i] = []
	for dz in int(k.d):
		for dx in int(k.w):
			out.append(Vector2i(int(row.x) - int(k.w) / 2 + dx, int(row.z) - int(k.d) / 2 + dz))
	return out
