class_name Upgrades
## CW3 Forge: Aether buys permanent, mission-wide upgrades. Aether comes from objectives,
## Spore Nests and Aether Towers the Operative captures and holds (aether_towers.gd). Spending
## needs a finished, connected Forge. Static state: one mission per run; reset() on start.
## Effects are multipliers that systems read through mult()/bonus().

## cost = base + step * level. per = effect per level. Numbers follow the CW3 Forge.
const DEFS := {
	"energy": { "label": "Energy Efficiency", "base": 20, "step": 20, "max": 10, "per": 0.20,
		"desc": "+20% energy from the Node, collectors and reactors" },
	"build": { "label": "Build Speed", "base": 10, "step": 10, "max": 10, "per": 0.20,
		"desc": "+20% packet request rate while building" },
	"packet": { "label": "Packet Speed", "base": 10, "step": 10, "max": 10, "per": 0.15,
		"desc": "+15% packet travel speed" },
	"storage": { "label": "Energy Storage", "base": 10, "step": 10, "max": 20, "per": 25.0,
		"desc": "+25 energy bank" },
	"fire_rate": { "label": "Fire Rate", "base": 20, "step": 20, "max": 5, "per": 0.12,
		"desc": "+12% weapon fire rate" },
	"range": { "label": "Fire Range", "base": 20, "step": 20, "max": 5, "per": 0.08,
		"desc": "+8% weapon range" },
	"move": { "label": "Move Speed", "base": 10, "step": 10, "max": 5, "per": 0.25,
		"desc": "+25% flying speed for weapons and the Node" },
}
const ORDER := ["energy", "build", "packet", "storage", "fire_rate", "range", "move"]

## Aether rewards (objective ids from Objectives.LIST, plus per nest).
const REWARDS := { "e1": 25, "e2": 25, "spire": 30, "core": 40, "nest": 10 }

static var aether := 0
static var levels := {}
static var _frac := 0.0  # tower trickle below 1 Aether


static func reset() -> void:
	aether = 0
	levels = {}
	_frac = 0.0


static func level(id: String) -> int:
	return levels.get(id, 0)


static func cost(id: String) -> int:
	var d: Dictionary = DEFS[id]
	return d.base + d.step * level(id)


static func maxed(id: String) -> bool:
	return level(id) >= DEFS[id].max


## Multiplier 1 + per*level (energy, build, packet, fire_rate, range, move).
static func mult(id: String) -> float:
	return 1.0 + DEFS[id].per * level(id)


## Flat bonus per*level (storage).
static func bonus(id: String) -> float:
	return DEFS[id].per * level(id)


static func gain(n: int, why: String) -> void:
	aether += n
	Bus.say("+%d Aether (%s). Spend it at a Forge." % [n, why], "good")


## Silent income from held Aether Towers.
static func trickle(amount: float) -> void:
	_frac += amount
	var whole := floori(_frac)
	aether += whole
	_frac -= whole


## Returns "" on success, or why it failed.
static func buy(id: String, forge_ready: bool) -> String:
	if not forge_ready:
		return "Build a Forge (Titans tab) and connect it first"
	if maxed(id):
		return "%s is maxed" % DEFS[id].label
	if aether < cost(id):
		return "Need %d Aether" % cost(id)
	aether -= cost(id)
	levels[id] = level(id) + 1
	return ""
