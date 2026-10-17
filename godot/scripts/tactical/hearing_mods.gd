class_name HearingMods
extends RefCounted
## F134: Tarkov-style earmuffs. While the player wears a headset (Inventory slot "headset") footsteps and other quiet
## sounds are boosted and gunshots / explosions are compressed. One static reader; sound code adds the dB it returns.

const MODS := {
	"step_db": 8.0,      # bot footsteps louder
	"step_range": 1.5,   # ... and heard this much further
	"quiet_db": 4.0,     # other quiet 3D sounds (bot reloads / mechanics)
	"loud_db": -8.0,     # gunshots and explosions, 2D and 3D
}

static var inv: Inventory   # the player's inventory (set by PlayerWeapons.setup)


static func worn() -> bool:
	return inv != null and inv.equipped("headset") != null


static func step_db() -> float:
	return MODS["step_db"] if worn() else 0.0


static func step_range() -> float:
	return MODS["step_range"] if worn() else 1.0


static func quiet_db() -> float:
	return MODS["quiet_db"] if worn() else 0.0


static func loud_db() -> float:
	return MODS["loud_db"] if worn() else 0.0
