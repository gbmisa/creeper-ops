class_name OperativeUpgrades
## Salvage upgrades for the Operative. Same shape as Upgrades, but each tier has its own
## cost from `costs` (not base + step). State is level-wide: reset() when a mission starts,
## and it is kept across death. Weapon and movement code uses mult(), level() and the
## helpers below, never DEFS. Pack waits for extractors (not this stage).

const DEFS := {
	"firepower": { "label": "Firepower", "costs": [20, 45, 80], "per": 0.25,
		"desc": "Rifle damage +25% per tier. Rocket magazine +1 per tier." },
	"armour": { "label": "Armour", "costs": [20, 45, 80], "per": 0.25, "shield": 30.0, "shield_at": 3,
		"desc": "Suit max +25% per tier. Tier 3 adds a 30-point shield that regens after a pause." },
	"mobility": { "label": "Mobility", "costs": [15, 35, 70], "per": 0.10, "air_at": 2, "jet_at": 3,
		"jet_levels": 1, "jet_rate": 4.0,
		"desc": "Sprint +10% per tier. Tier 2 double jump. Tier 3 jump jet (one more terrace)." },
	"unlock_railgun": { "label": "Railgun", "costs": [60],
		"desc": "Unlocks the Railgun on 4. Each shot costs 2 Salvage." },
	"unlock_plasma": { "label": "Plasma Thrower", "costs": [60],
		"desc": "Unlocks the Plasma Thrower on 5. Firing costs 1 Salvage per second." },
	"unlock_demo": { "label": "Demolition Charge", "costs": [40],
		"desc": "Unlocks the Demolition Charge on 6. Each charge costs 8 Salvage." },
}
const ORDER := ["firepower", "armour", "mobility", "unlock_railgun", "unlock_plasma", "unlock_demo"]

static var levels := {}


static func reset() -> void:
	levels = {}


static func level(id: String) -> int:
	return int(levels.get(id, 0))


static func cost(id: String) -> int:
	var costs: Array = DEFS[id].costs
	var lv := level(id)
	if lv >= costs.size():
		return int(costs.back())
	return int(costs[lv])


static func maxed(id: String) -> bool:
	return level(id) >= (DEFS[id].costs as Array).size()


## 1 + per * level. Unlocks have no per, so they stay at 1.
static func mult(id: String) -> float:
	return 1.0 + float(DEFS[id].get("per", 0.0)) * level(id)


static func suit_max() -> float:
	return Config.SUIT_MAX * mult("armour")


static func shield_max() -> float:
	var d: Dictionary = DEFS.armour
	return float(d.shield) if level("armour") >= int(d.shield_at) else 0.0


## Extra jumps after the ground hop (1 once Mobility is at least air_at).
static func air_jumps() -> int:
	return 1 if level("mobility") >= int(DEFS.mobility.air_at) else 0


## Metres of extra lift while jump is held (one terrace at jet_at, else 0).
static func jet_budget() -> float:
	var d: Dictionary = DEFS.mobility
	return Config.LEVEL_H * float(d.jet_levels) if level("mobility") >= int(d.jet_at) else 0.0


static func jet_rate() -> float:
	var d: Dictionary = DEFS.mobility
	return float(d.jet_rate) if level("mobility") >= int(d.jet_at) else 0.0


static func unlocked(weapon_id: String) -> bool:
	return level("unlock_" + weapon_id) > 0


## One free tier. Debug screenshots; a normal buy still spends Salvage.
static func grant(id: String) -> void:
	if DEFS.has(id) and not maxed(id):
		levels[id] = level(id) + 1


static func button_text(id: String) -> String:
	var d: Dictionary = DEFS[id]
	var lv := level(id)
	var mx: int = (d.costs as Array).size()
	if maxed(id):
		return "%s: owned" % d.label if mx == 1 else "%s %d/%d: MAX" % [d.label, lv, mx]
	if mx == 1:
		return "%s (%d Salvage)" % [d.label, cost(id)]
	return "%s %d→%d (%d Salvage)" % [d.label, lv, lv + 1, cost(id)]


## Returns "" on success, or why it failed.
static func buy(id: String, stockpile: Stockpile) -> String:
	if not DEFS.has(id):
		return "Unknown upgrade"
	if maxed(id):
		return "%s is maxed" % DEFS[id].label
	var price := cost(id)
	if stockpile == null or not stockpile.can_afford("salvage", price):
		return "Need %d Salvage" % price
	stockpile.spend("salvage", price)
	levels[id] = level(id) + 1
	return ""
