class_name UnitDefs
## Barracks-trained units. They can enter Blight (where nothing can be built), shoot enemies
## and clear creeper, but they CANNOT do objective actions (charges, the Rift, the Core).
## They are deliberately not self-sufficient: every shot and every spray spends 1 ammo, and
## an empty (or badly hurt) unit walks back to a barracks to restock from its packet-fed
## supply. climb/drop = max terrain levels up/down between neighbouring cells.

const ORDER := ["soldier", "crawler"]
const KEYS := { "soldier": "train_soldier", "crawler": "train_crawler" }  # Keybinds actions
const RETREAT_HP := 0.25   # fraction of HP at which a unit heads home on its own
const DOCK_HEAL := 8.0     # HP/s while docked at a barracks

const DEFS := {
	"soldier": { "label": "Soldier", "cost": 6, "train_time": 2.0, "hp": 35.0, "speed": 5.5, "climb": 1.1, "drop": 3.0,
		"radius": 0.45, "ammo": 24.0,
		"gun": { "range": 14.0, "damage": 1.0, "rate": 0.35 },
		"clear": { "range": 3.0, "power": 0.35, "splash": 0.0, "rate": 0.45 },
		"creeper_mult": 1.0,
		"desc": "Cheap infantry (6 packets). Climbs steep ground, picks off raiders, chips at shallow creeper. Carries 24 rounds, then must walk home to resupply." },
	"crawler": { "label": "Crawler", "cost": 18, "train_time": 4.0, "hp": 130.0, "speed": 4.2, "climb": 1.0, "drop": 1.0,
		"radius": 0.9, "ammo": 16.0,
		"gun": { "range": 18.0, "damage": 3.0, "rate": 0.9 },
		"clear": { "range": 3.5, "power": 1.1, "splash": 1.5, "rate": 0.4 },
		"creeper_mult": 0.35,
		"desc": "Armored sprayer (18 packets). Wide creeper splash, shrugs off shallow creeper, needs gentle slopes. 16 charges per trip home." },
}
