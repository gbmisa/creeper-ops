class_name LookPropDefs
## Decorative prop placements (visual only, no collision). [id, x, z, yaw_deg, scale, tint]. LookProps drops any entry that
## would overlap a building, a cover piece, the spawn or a bot route, so these never change a fire lane.
const DIR := "res://assets/models/props/"
const TINT := {   # per prop: multiplies the flat colour baked into the glb
	"sandbags": Color(0.62, 0.58, 0.45), "jersey": Color(0.95, 0.95, 0.9), "drum": Color(1.0, 1.0, 1.0),
	"pallets": Color(1.0, 0.95, 0.85), "fueltank": Color(1.0, 1.0, 1.0), "generator": Color(1.0, 1.0, 1.0),
	"lightmast": Color(1.0, 1.0, 1.0), "camonet": Color(1.0, 1.0, 1.0), "wreck": Color(1.0, 0.85, 0.75),
	"radar": Color(1.0, 1.0, 1.0), "crate": Color(0.85, 0.9, 0.75),
}
const SKIRMISH := [
	["radar", -54.5, -27.0, 90, 1.0], ["wreck", 54.0, -44.0, 40, 1.0], ["wreck", -54.0, 14.0, -20, 1.0], ["wreck", 52.0, 46.0, 100, 1.0],
	["fueltank", 52.5, -8.0, 0, 1.0], ["fueltank", 52.5, -3.0, 0, 1.0], ["generator", -22.0, 52.0, 10, 1.0], ["generator", 40.5, -26.5, 90, 1.0],
	["lightmast", -24.0, 50.0, 0, 1.0], ["lightmast", 23.0, 49.0, 0, 1.0], ["lightmast", 6.0, -14.0, 0, 1.0], ["lightmast", -38.0, 14.0, 0, 1.0],
	["camonet", 14.0, -32.0, 90, 1.0], ["camonet", -20.0, 40.0, 0, 1.0],
	["sandbags", -47.0, -35.0, 0, 0.8], ["sandbags", -50.0, -33.0, 90, 0.8], ["sandbags", 3.5, 49.0, 0, 0.8], ["sandbags", -3.5, 49.0, 0, 0.8],
	["sandbags", 39.5, 5.0, 90, 0.8], ["sandbags", -12.5, -4.0, 0, 0.8], ["sandbags", 35.5, -23.0, 0, 0.8],
	["jersey", 9.0, 47.0, 0, 1.0], ["jersey", -9.0, 47.0, 0, 1.0], ["jersey", 12.0, 47.0, 20, 1.0], ["jersey", -12.0, 47.0, -20, 1.0],
	["jersey", 55.0, 20.0, 90, 1.0], ["jersey", -55.0, -10.0, 90, 1.0], ["jersey", 44.0, -42.0, 0, 1.0],
	["drum", -15.0, 3.0, 0, 1.0], ["drum", -15.8, 3.6, 30, 1.0], ["drum", 11.0, -31.0, 0, 1.0], ["drum", 11.6, -30.2, 0, 1.0], ["drum", 41.0, -27.0, 0, 1.0],
	["drum", -36.0, 36.0, 0, 1.0], ["drum", 48.0, 5.0, 0, 1.0], ["drum", -55.0, 30.0, 0, 1.0], ["drum", -54.2, 30.6, 0, 1.0],
	["pallets", 40.5, -33.0, 20, 1.0], ["pallets", 17.0, -24.0, 0, 1.0], ["pallets", 40.5, 8.0, 0, 1.0], ["pallets", -36.0, -22.0, 0, 1.0], ["pallets", 5.0, -49.0, 0, 1.0],
]
const RANGE := [
	["generator", 17.5, 8.0, 180, 1.0], ["drum", 18.2, 6.0, 0, 1.0], ["drum", 18.2, 5.0, 0, 1.0], ["pallets", 17.5, 3.0, 0, 1.0],
["lightmast", 11.0, 9.0, 0, 1.0], ["lightmast", -11.0, 9.0, 0, 1.0],
]
