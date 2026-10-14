class_name ArmorDefs
## Armor rows. cls 1-6, max_dur in points, zones covered, blunt = throughput when stopped.

const DESTRUCT := {"aramid": 0.25, "uhmwpe": 0.45, "titanium": 0.55, "steel": 0.7, "ceramic": 0.8}

const ROWS := {
	"vest2": {"name": "Class 2 soft vest", "cls": 2, "mat": "aramid", "max_dur": 50.0, "zones": ["thorax", "stomach"], "blunt": 0.3, "ricochet": 0.0},
	"vest3": {"name": "Class 3 soft vest", "cls": 3, "mat": "uhmwpe", "max_dur": 55.0, "zones": ["thorax", "stomach"], "blunt": 0.28, "ricochet": 0.0},
	"plate4": {"name": "Class 4 plate carrier", "cls": 4, "mat": "ceramic", "max_dur": 50.0, "zones": ["thorax", "stomach"], "blunt": 0.25, "ricochet": 0.0},
	"steel6": {"name": "Class 6 steel plate", "cls": 6, "mat": "steel", "max_dur": 80.0, "zones": ["thorax"], "blunt": 0.2, "ricochet": 0.0},
	"helmet3": {"name": "Class 3 helmet", "cls": 3, "mat": "aramid", "max_dur": 30.0, "zones": ["head"], "blunt": 0.2, "ricochet": 0.4},
}

## Bench loadouts, in cycle order.
const LOADOUTS := [[], ["vest2"], ["plate4"], ["steel6", "helmet3"]]
const LOADOUT_NAMES := ["No armor", "Class 2", "Class 4", "Class 6 + helmet"]


static func of(id: String) -> Dictionary:
	var d: Dictionary = ROWS[id].duplicate()
	d["id"] = id
	d["destruct"] = DESTRUCT[d["mat"]]
	return d
