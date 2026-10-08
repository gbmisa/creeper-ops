class_name StructureDefs
## Data table for every structure, grouped into the four CW3-style build tabs.
## cost = energy packets that must physically arrive before it works (drop pods pay up front).
## link = connection radius (cells); relays = passes packets on. movable = can lift off and
## fly to a new spot (all weapons, titans and the Command Node; never the Nullifier).
## ammo: max rounds, per_packet = rounds one packet adds, per_shot (default 1).
## Tooltips live next to the numbers so in-game explanations never drift from real values.

const TABS := ["Structures", "Weapons", "Titans", "Orbital", "Castle"]

## Build menu contents per tab. Entries are structure types, or "@action" for orbital actions.
const MENU := {
	"Structures": ["collector", "relay", "outpost", "miner", "reactor", "storage", "barracks"],
	"Weapons": ["cannon", "mortar", "beam", "sniper", "nullifier"],
	"Titans": ["bertha", "thor", "forge", "terp", "@terp"],
	"Orbital": ["beacon", "@drop", "@lance", "@operative"],
	"Castle": ["@repeater", "@lobber", "@flak", "@repair"],
}

static var ACTIONS := _turret_actions().merged({
	"@drop": { "label": "Drop Pod", "cost_text": "%d-%d" % [int(Config.DROP_BASE), int(Config.DROP_MAX)],
		"desc": "Drop the Operative on any surface cell. Costs %d energy plus 1 per %.0f cells from the nearest Totem, capped at %d. The pod falls for %.0fs. Shield Domes block it." % [int(Config.DROP_BASE), Config.DROP_PER_CELLS, int(Config.DROP_MAX), Config.DROP_TIME] },
	"@lance": { "label": "Orbital Lance", "cost_text": "%d now" % Config.LANCE_COST,
		"desc": "Strike from orbit: after %ds, burns away creeper in a %.0f-cell radius anywhere you can see. Paid up front (%d), %ds cooldown." % [Config.LANCE_DELAY, Config.LANCE_RADIUS, Config.LANCE_COST, Config.LANCE_COOLDOWN] },
	"@operative": { "label": "Deploy Operative", "cost_text": "T",
		"desc": "Send the Operative to the selected Totem (or the newest). Free and instant while the teleporter is ready. Only the Operative can plant charges, enter the Rift and kill the Deep Core." },
	"@terp": { "label": "Terp Paint", "cost_text": "paint", "unlock": "terp",
		"desc": "Drag a rectangle to paint a target level (0-%d). It starts at the ground under the first cell; Page Up and Page Down change it, hold C to erase. Hatched until a Terp finishes the cell." % Config.MAX_LEVEL },
	"@repair": { "label": "Repair Wall", "cost_text": "Salvage",
		"desc": "Click a damaged wall of a castle you hold. Costs 1 Salvage per %d HP. A breach is rebuilt in stone." % int(Config.WALL_REPAIR_HP) },
})

static var DEFS := {
	"node": { "label": "Command Node", "hp": 500.0, "link": 10.0, "relays": true, "sender": true, "link_y": 3.2, "footprint": 1,
		"movable": true, "move_speed": 2.5, "wet_time": 90.0, "buildable": false,
		"desc": "Your base and a packet sender. Turns energy into packets; a request launches from the nearest sender. It can lift off and relocate (this Node sends nothing while flying). If it falls, you lose." },
	"collector": { "tab": "Structures", "label": "Collector", "cost": 5, "hp": 30.0, "link": 6.0, "relays": true, "link_y": 0.9,
		"desc": "Claims the dry land in a 7x7 square around it (green tiles) for energy, ~0.25/s when the field is full. Overlapping fields share tiles, so space them out. Relays packets (link 6)." },
	"relay": { "tab": "Structures", "label": "Relay", "cost": 10, "hp": 25.0, "link": 13.0, "relays": true, "link_y": 2.9,
		"desc": "Long-range network node (link 13). Packets hop relay to relay along the shortest path." },
	"outpost": { "tab": "Structures", "label": "Outpost", "cost": 40, "hp": 200.0, "link": 6.0, "relays": true, "sender": true,
		"link_y": 1.7, "footprint": 1, "movable": false,
		"desc": "A packet sender away from the Command Node (link 6). Structures take packets from whichever sender is nearest, so a front stays supplied while the Node is flying. Adds %d to the shared energy bank and produces none. Costs %d Ore up front, then 40 packets. Cannot be moved." % [int(Config.OUTPOST_STORAGE), int(Config.OUTPOST_ORE)] },
	"miner": { "tab": "Structures", "label": "Miner", "cost": 15, "hp": 40.0, "link": 4.0, "link_y": 1.6, "movable": false,
		"desc": "Sits on an ore vein and ships 1 Ore back along the relays every %.0fs. The vein holds %d. While the relays are cut it stores %d, then waits. Creeper destroys it on contact. Not movable." % [Config.MINER_INTERVAL, int(Config.ORE_DEPOSIT), int(Config.MINER_BUFFER)] },
	"reactor": { "tab": "Structures", "label": "Reactor", "cost": 50, "hp": 60.0, "link": 4.0, "link_y": 1.2, "income": 0.4,
		"desc": "Generates a flat +0.4 energy/s (two full collector fields). Expensive, but needs no land." },
	"storage": { "tab": "Structures", "label": "Storage", "cost": 15, "hp": 50.0, "link": 4.0, "link_y": 1.0, "storage": 30.0,
		"desc": "Raises your energy bank by 30 so you can save up for titans and nullifiers." },
	"barracks": { "tab": "Structures", "label": "Barracks", "cost": 50, "hp": 140.0, "link": 5.0, "link_y": 2.0, "footprint": 1,
		"ammo": { "max": 30.0, "per_packet": 3.0 },
		"desc": "Trains Soldiers and Crawlers (max %d per barracks) that can enter Blight. Units carry limited ammo and must walk back here to resupply from its packet-fed stock." % Config.UNITS_PER_BARRACKS },
	"nullifier": { "tab": "Weapons", "label": "Nullifier", "cost": 100, "hp": 70.0, "link": 4.0, "link_y": 1.2,
		"weapon": true, "wet_time": 8.0, "range": Config.NULLIFY_RANGE,  # reach to the emitter; Forge Fire Range extends it
		"desc": "Build within range (10 cells, more with Forge Fire Range) of an UNSHIELDED emitter. Creeper wears it down (8 s to die, or to undo its construction), but it takes none while charging. When its 100 packets arrive it charges for 2 s and destroys the emitter. Cannot be moved." },
	"cannon": { "tab": "Weapons", "label": "Pulse Cannon", "cost": 25, "hp": 40.0, "link": 4.0, "link_y": 0.9,
		"movable": true, "move_speed": 7.0, "range": 9.0, "fire_rate": 0.267, "power": 1.0, "hits": 12, "splash": 6.0, "weapon": true,
		"ammo": { "max": 40.0, "per_packet": 4.0 }, "targets": "creeper",
		"desc": "Fires at the nearest creeper within range 9. Each shot strips up to 12 depth, 1 per cell, nearest cells first, never above the impact ground. Holds 40 shots; each ammo packet adds 4, so a firing cannon drinks ~0.9 packets/s. Survives 12 s in creeper. Movable." },
	"mortar": { "tab": "Weapons", "label": "Mortar", "cost": 40, "hp": 55.0, "link": 4.0, "link_y": 1.4,
		"movable": true, "move_speed": 5.0, "range": 13.0, "fire_rate": 3.0, "power": 3.5, "splash": 4.0, "weapon": true, "wet_time": 16.0,
		"ammo": { "max": 15.0, "per_packet": 1.0, "per_shot": 3.0 }, "targets": "creeper",
		"desc": "Lobs a shell at the deepest pool within range 13: every wet cell within 4 loses 3.5 depth. 3 packets per shell, holds 5 shells. Survives 16 s in creeper. Movable." },
	"beam": { "tab": "Weapons", "label": "Beam", "cost": 20, "hp": 45.0, "link": 4.0, "link_y": 1.6,
		"movable": true, "move_speed": 6.0, "range": 23.0, "fire_rate": 0.15, "power": 1.0, "weapon": true, "wet_time": 1.6,
		"ammo": { "max": 20.0, "per_packet": 5.0 }, "targets": "air",
		"desc": "Surface-to-air laser: burns flying enemies within range 23 (spore volleys and flyers). Ignores creeper and ground raiders. Fragile: dies after 1.6 s in creeper. Movable." },
	"sniper": { "tab": "Weapons", "label": "Sniper", "cost": 75, "hp": 40.0, "link": 4.0, "link_y": 1.8,
		"movable": true, "move_speed": 6.0, "range": 20.0, "fire_rate": 1.5, "power": 4.0, "weapon": true,
		"ammo": { "max": 60.0, "per_packet": 1.0, "per_shot": 5.0 }, "targets": "raiders",
		"desc": "Long-range rifle that picks off nest raiders within range 20 (Skitters die in one shot; later tiers take several). 5 packets per shot, holds 12. Can't hurt nests: those still need units or the Operative. Movable." },
	"bertha": { "tab": "Titans", "label": "Big Bertha", "cost": 250, "hp": 220.0, "link": 5.0, "link_y": 2.6, "footprint": 1,
		"movable": true, "move_speed": 3.0, "range": 200.0, "min_range": 5, "fire_rate": 10.0, "power": 100.0, "splash": 10.0,
		"weapon": true, "wet_time": 160.0,
		"ammo": { "max": 150.0, "per_packet": 1.0, "per_shot": 150.0 }, "targets": "creeper",
		"desc": "Titan artillery with no range limit: shells the deepest pool on the map (never within 5 cells of itself), wiping 100 depth from every cell within 10. One shell costs 150 packets. Survives 160 s in creeper. Slow to move." },
	"thor": { "tab": "Titans", "label": "Thor", "cost": 600, "hp": 320.0, "link": 6.0, "link_y": 1.0, "footprint": 1,
		"movable": true, "move_speed": 6.0, "flying": true, "roams": true, "range": 12.0, "fire_rate": 0.12, "power": 1.0, "hits": 6, "splash": 3.0,
		"weapon": true, "ammo": { "max": 80.0, "per_packet": 4.0 }, "targets": "creeper",
		"desc": "Titan gunship. Hovers, so creeper can't touch it. Fills its 80-shot magazine in the network, then fires from it wherever it goes, even in flight or out of network range. Rapid fire into the nearest creeper within range 12." },
	"forge": { "tab": "Titans", "label": "Forge", "cost": 100, "hp": 260.0, "link": 5.0, "link_y": 2.4, "footprint": 2, "unique": true,
		"desc": "Titan workshop (5x5, needs level ground). Spend Aether on permanent upgrades: energy, build speed, packet speed, storage, fire rate, range, move speed. Aether comes from objectives, nests and castles the Operative captures and holds." },
	"keep": { "label": "Castle Keep", "cost": 0, "hp": 300.0, "link": 10.0, "relays": true, "sender": true, "link_y": 4.0,
		"movable": false, "buildable": false, "reserve": true, "wet_time": 60.0,
		"desc": "Your held castle's keep. A packet sender and relay (link 10): structures nearby take packets from it, like an Outpost. Comes with the castle and falls with it." },
	"beacon": { "tab": "Orbital", "label": "Totem", "cost": 10, "hp": 40.0, "link": 0.0, "needs_network": false, "link_y": 1.0, "drop_pod": true,
		"desc": "Operative arrival point, dropped from orbit: no network, paid up front, not in Blight. Deploying here (T) is free and instant. Recalling within %.0f m is free and does not cool the teleporter down." % Config.TOTEM_FREE_RADIUS },
	"terp": { "tab": "Titans", "label": "Terp", "cost": 25, "hp": 80.0, "link": 6.0, "link_y": 1.5,
		"work_range": 7.0, "movable": false, "unlock": "terp",
		"desc": "Raises or lowers painted ground one level at a time, within 7 cells. Each level costs %d packets and takes %.0fs once they arrive. Earth only. Link 6. Not movable." % [Config.TERP_PACKETS, Config.TERP_STEP_TIME] },
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
	if type == "outpost":
		return "%d Ore + %d" % [int(Config.OUTPOST_ORE), int(d.cost)]
	return ("%d now" % d.cost) if d.get("drop_pod", false) else str(d.cost)


static func label(type: String) -> String:
	return ACTIONS[type].label if type.begins_with("@") else DEFS[type].label


static func desc(type: String) -> String:
	return ACTIONS[type].desc if type.begins_with("@") else DEFS[type].desc


## "" when this structure or @action is available. Level files list ids in "unlocks";
## a def with no "unlock" is always available. One reader so callers never open level files.
static func lock_reason(level: Dictionary, type: String) -> String:
	var id := ""
	if type.begins_with("@"):
		id = str(ACTIONS.get(type, {}).get("unlock", ""))
	elif DEFS.has(type):
		id = str(DEFS[type].get("unlock", ""))
	if id == "" or (level.get("unlocks", []) as Array).has(id):
		return ""
	return "Not available on this level"


## Debug and tests add an id to the live level dict. Does not touch level files.
static func grant_unlock(level: Dictionary, id: String) -> void:
	if id == "":
		return
	if not level.has("unlocks"):
		level["unlocks"] = []
	var list: Array = level.unlocks
	if not list.has(id):
		list.append(id)


## Castle tab: turrets bought with Salvage on the sockets of a castle you hold.
static func _turret_actions() -> Dictionary:
	var out := {}
	for t in CastleTurrets.ORDER:
		var d: Dictionary = CastleTurrets.DEFS[t]
		out["@" + t] = { "label": d.label, "cost_text": "%s Salv" % "/".join(d.costs.map(func(n): return str(n))),
			"desc": "%s Click a socket (wall corners, beside the gate) of a castle you hold; click again to upgrade (I-III). Paid in Salvage, no packets." % d.desc }
	return out
