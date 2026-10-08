class_name AmmoDefs
extends RefCounted
## Improved ammo grades (STRONGHOLDS_DESIGN 5.3). Numbers live here; AmmoGrades holds the rules.
## Operative: crossbow grades cost Salvage per round (12 per 30), cluster rockets 15 per 3.
## Network: Snipers and Barracks (unit stock) take a Salvage surcharge on every ammo packet.
## A structure's magazine holds one grade: switching grade discards its graded rounds.

const STD := "std"
const IDS := ["std", "ap", "inc", "cluster"]
const GRADES := {
	"std": { "label": "Standard", "short": "", "color": Color("9ff6ff") },
	"ap": { "label": "Armour-piercing", "short": "AP", "color": Color("ffe27a"), "op_round": 12.0 / 30.0, "packet": 0.5,
		"bonus": 1.6, "targets": ["Brute", "Ravager", "Behemoth", "Warden"] },
	"inc": { "label": "Incendiary", "short": "INC", "color": Color("ff7a3a"), "op_round": 12.0 / 30.0, "packet": 0.5,
		"burn_dps": 2.0, "burn_time": 3.0, "clear": 1.0 },
	"cluster": { "label": "Cluster", "short": "CLU", "color": Color("ffb347"), "op_rocket": 15.0 / 3.0, "subs": 4,
		"sub_blast": 0.65, "sub_scale": 0.6, "spread": 1.4 },
}
## Which grades each weapon key can load (index 0 is always standard).
const WEAPONS := {
	"rifle": ["std", "ap", "inc"],
	"rocket": ["std", "cluster"],
	"sniper": ["std", "ap", "inc"],
	"barracks": ["std", "ap", "inc"],
}


static func label(id: String) -> String:
	return GRADES[id].label


static func short(id: String) -> String:
	return GRADES[id].short
