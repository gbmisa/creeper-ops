class_name BotDefs
## Enemy roster, one row per kind (read by ScavBot). `rifleman` is the original Scav with its exact numbers.
## gun: WeaponDefs id. armor: ArmorDefs ids. speed: multiplier on the walk/move/run constants.
## sight: view range (m). hold: stop advancing inside this distance. fire: only shoots inside this distance.
## aim_mult: scales the aim error. aim_far: extra aim error up to 50 m. cd: pause between bursts (min, max).
## rush: never takes cover. flank_eager: flanks when it loses sight. windup: scope glint seconds before a shot.
## overwatch: holds a spot and relocates after `relocate` shots or when hit. followers: rifleman escorts (boss).

const ORDER := ["rifleman", "pistol", "shotgunner", "marksman", "boss"]

const ROWS := {
	"rifleman": {"name": "Scav", "gun": "ak47", "armor": ["vest2"], "speed": 1.0, "sight": 120.0, "hold": 30.0, "fire": 9999.0,
		"aim_mult": 1.0, "aim_far": 0.0, "cd": [0.45, 0.9], "rush": false, "flank_eager": false, "windup": 0.0,
		"overwatch": false, "relocate": 0, "followers": 0, "uniform": Color(0.2, 0.32, 0.2)},
	"pistol": {"name": "Runner", "gun": "m1911", "armor": [], "speed": 1.15, "sight": 120.0, "hold": 12.0, "fire": 20.0,
		"aim_mult": 1.0, "aim_far": 0.0, "cd": [0.35, 0.7], "rush": false, "flank_eager": true, "windup": 0.0,
		"overwatch": false, "relocate": 0, "followers": 0, "uniform": Color(0.36, 0.3, 0.2)},
	"shotgunner": {"name": "Breacher", "gun": "shotgun", "armor": ["vest3"], "speed": 1.0, "sight": 120.0, "hold": 8.0, "fire": 25.0,
		"aim_mult": 1.0, "aim_far": 2.0, "cd": [0.5, 0.9], "rush": true, "flank_eager": false, "windup": 0.0,
		"overwatch": false, "relocate": 0, "followers": 0, "uniform": Color(0.3, 0.22, 0.2)},
	"marksman": {"name": "Marksman", "gun": "sniper", "armor": [], "speed": 1.0, "sight": 200.0, "hold": 0.0, "fire": 300.0,
		"aim_mult": 0.35, "aim_far": 0.0, "cd": [2.5, 3.5], "rush": false, "flank_eager": false, "windup": 0.9,
		"overwatch": true, "relocate": 2, "followers": 0, "uniform": Color(0.22, 0.26, 0.2)},
	"boss": {"name": "Warlord", "gun": "p90", "armor": ["plate4", "helmet3"], "speed": 1.0, "sight": 120.0, "hold": 20.0, "fire": 9999.0,
		"aim_mult": 1.0, "aim_far": 0.0, "cd": [0.45, 0.9], "rush": false, "flank_eager": false, "windup": 0.0,
		"overwatch": false, "relocate": 0, "followers": 2, "uniform": Color(0.3, 0.1, 0.1)},
}

const FOLLOWER_LEASH := 15.0
const FOLLOWER_CLOSE := 8.0


static func of(kind: String) -> Dictionary:
	return ROWS[kind]
