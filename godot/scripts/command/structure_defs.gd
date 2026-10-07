class_name StructureDefs
## Data table for every structure, grouped into the four CW3-style build tabs.
## cost = energy packets that must physically arrive before it works (drop pods pay up front).
## link = connection radius (cells); relays = passes packets on. movable = can lift off and
## fly to a new spot (all weapons, titans and the Command Node; never the Nullifier).
## ammo: max rounds, per_packet = rounds one packet adds, per_shot (default 1).
## Tooltips live next to the numbers so in-game explanations never drift from real values.

const TABS := ["Structures", "Weapons", "Titans", "Orbital"]

## Build menu contents per tab. Entries are structure types, or "@action" for orbital actions.
const MENU := {
	"Structures": ["collector", "relay", "reactor", "storage", "barracks", "nullifier"],
	"Weapons": ["cannon", "mortar", "beam", "sniper"],
	"Titans": ["bertha", "thor", "forge"],
	"Orbital": ["beacon", "@lance", "@operative"],
}

static var ACTIONS := {
	"@lance": { "label": "Orbital Lance", "cost_text": "%d now" % Config.LANCE_COST,
		"desc": "Strike from orbit: after %ds, burns away creeper in a %.0f-cell radius anywhere you can see. Paid up front (%d), %ds cooldown." % [Config.LANCE_DELAY, Config.LANCE_RADIUS, Config.LANCE_COST, Config.LANCE_COOLDOWN] },
	"@operative": { "label": "Deploy Operative", "cost_text": "T",
		"desc": "Teleport the Operative to the selected Beacon (or the newest). Only the Operative can plant charges, enter the Rift and kill the Deep Core." },
}

static var DEFS := {
	"node": { "label": "Command Node", "hp": 500.0, "link": 10.0, "relays": true, "link_y": 3.2, "footprint": 1,
		"movable": true, "move_speed": 2.5, "creeper_resist": 0.6, "buildable": false,
		"desc": "Your base and the network root. Turns energy into packets and launches one whenever a structure asks. It can lift off and relocate (no packets while flying). If it falls, you lose." },
	"collector": { "tab": "Structures", "label": "Collector", "cost": 5, "hp": 30.0, "link": 6.0, "relays": true, "link_y": 0.9,
		"desc": "Claims the dry land in a 7x7 square around it (green tiles) for energy, ~0.25/s when the field is full. Overlapping fields share tiles, so space them out. Relays packets (link 6)." },
	"relay": { "tab": "Structures", "label": "Relay", "cost": 10, "hp": 25.0, "link": 13.0, "relays": true, "link_y": 2.9,
		"desc": "Long-range network node (link 13). Packets hop relay to relay along the shortest path." },
	"reactor": { "tab": "Structures", "label": "Reactor", "cost": 50, "hp": 60.0, "link": 4.0, "link_y": 1.2, "income": 0.4,
		"desc": "Generates a flat +0.4 energy/s (two full collector fields). Expensive, but needs no land." },
	"storage": { "tab": "Structures", "label": "Storage", "cost": 15, "hp": 50.0, "link": 4.0, "link_y": 1.0, "storage": 30.0,
		"desc": "Raises your energy bank by 30 so you can save up for titans and nullifiers." },
	"barracks": { "tab": "Structures", "label": "Barracks", "cost": 50, "hp": 140.0, "link": 5.0, "link_y": 2.0, "footprint": 1,
		"ammo": { "max": 30.0, "per_packet": 3.0 },
		"desc": "Trains Soldiers and Crawlers (max %d per barracks) that can enter Blight. Units carry limited ammo and must walk back here to resupply from its packet-fed stock." % Config.UNITS_PER_BARRACKS },
	"nullifier": { "tab": "Structures", "label": "Nullifier", "cost": 100, "hp": 70.0, "link": 4.0, "link_y": 1.2,
		"desc": "Build within 4 cells of an UNSHIELDED emitter, on ground you've cleared of creeper. Creeper destroys it instantly, built or not, so keep the emitter suppressed. When its 100 packets arrive it charges for 8 s and destroys the emitter. Cannot be moved." },
	"cannon": { "tab": "Weapons", "label": "Pulse Cannon", "cost": 25, "hp": 40.0, "link": 4.0, "link_y": 0.9,
		"movable": true, "move_speed": 7.0, "range": 8.0, "fire_rate": 0.27, "power": 1.3,
		"ammo": { "max": 40.0, "per_packet": 4.0 }, "targets": "creeper",
		"desc": "Fast shots that strip creeper from the nearest wet cell in range 8. Holds 40 shots; each ammo packet adds 4, so a firing cannon drinks ~0.9 packets/s. Movable." },
	"mortar": { "tab": "Weapons", "label": "Mortar", "cost": 40, "hp": 55.0, "link": 4.0, "link_y": 1.4,
		"movable": true, "move_speed": 5.0, "range": 16.0, "fire_rate": 3.0, "power": 8.0, "splash": 2.5,
		"ammo": { "max": 15.0, "per_packet": 1.0, "per_shot": 3.0 }, "targets": "creeper",
		"desc": "Lobs a shell at the deepest pool within range 16, gutting a 2.5-cell splash. 3 packets per shell, holds 5 shells. Movable." },
	"beam": { "tab": "Weapons", "label": "Beam", "cost": 40, "hp": 45.0, "link": 4.0, "link_y": 1.6,
		"movable": true, "move_speed": 6.0, "range": 14.0, "fire_rate": 0.15, "power": 1.0,
		"ammo": { "max": 20.0, "per_packet": 5.0 }, "targets": "air",
		"desc": "Surface-to-air laser: burns flying enemies within range 14 (spore volleys now, flyers later). Ignores creeper and ground raiders. Movable." },
	"sniper": { "tab": "Weapons", "label": "Sniper", "cost": 50, "hp": 40.0, "link": 4.0, "link_y": 1.8,
		"movable": true, "move_speed": 6.0, "range": 26.0, "fire_rate": 1.2, "power": 4.0,
		"ammo": { "max": 6.0, "per_packet": 2.0 }, "targets": "raiders",
		"desc": "Long-range rifle that picks off nest raiders within range 26 (Skitters die in one shot; later tiers take several). Can't hurt nests: those still need units or the Operative. Movable." },
	"bertha": { "tab": "Titans", "label": "Big Bertha", "cost": 300, "hp": 220.0, "link": 5.0, "link_y": 2.6, "footprint": 1,
		"movable": true, "move_speed": 3.0, "range": 40.0, "fire_rate": 5.0, "power": 14.0, "splash": 4.5,
		"ammo": { "max": 20.0, "per_packet": 1.0, "per_shot": 5.0 }, "targets": "creeper",
		"desc": "Titan artillery. Range 40: hits the deepest pool almost anywhere, 4.5-cell splash. Every shell costs 5 packets. Slow to move." },
	"thor": { "tab": "Titans", "label": "Thor", "cost": 600, "hp": 320.0, "link": 6.0, "link_y": 1.0, "footprint": 1,
		"movable": true, "move_speed": 6.0, "flying": true, "range": 12.0, "fire_rate": 0.12, "power": 1.6,
		"ammo": { "max": 80.0, "per_packet": 4.0 }, "targets": "creeper",
		"desc": "Titan gunship. Hovers, so creeper can't touch it and it can park over pools. Rapid fire into the nearest creeper within range 12, but it drinks packets." },
	"forge": { "tab": "Titans", "label": "Forge", "cost": 100, "hp": 260.0, "link": 5.0, "link_y": 2.4, "footprint": 2, "unique": true,
		"desc": "Titan workshop (5x5, needs level ground). Spend Aether on permanent upgrades: energy, build speed, packet speed, storage, fire rate, range, move speed. Aether comes from objectives, nests and Aether Towers the Operative captures and holds." },
	"beacon": { "tab": "Orbital", "label": "Beacon", "cost": 10, "hp": 40.0, "link": 0.0, "needs_network": false, "link_y": 1.0, "drop_pod": true,
		"desc": "Operative drop point, dropped from orbit: needs no network, paid up front, but not in Blight. Select it, then press T to send the Operative down." },
}


static func get_def(type: String) -> Dictionary:
	return DEFS[type]


static func footprint(type: String) -> int:
	return DEFS[type].get("footprint", 0)


## Footprint radius in metres, for the ground ghost and selection ring.
static func radius_m(type: String) -> float:
	return (footprint(type) + 0.5) * Config.CELL


static func cost_text(type: String) -> String:
	if type.begins_with("@"):
		return ACTIONS[type].cost_text
	var d: Dictionary = DEFS[type]
	return ("%d now" % d.cost) if d.get("drop_pod", false) else str(d.cost)


static func label(type: String) -> String:
	return ACTIONS[type].label if type.begins_with("@") else DEFS[type].label


static func desc(type: String) -> String:
	return ACTIONS[type].desc if type.begins_with("@") else DEFS[type].desc
