class_name CastleTurrets
## Turrets on the sockets of a castle you hold (design §3.2, pulled forward from 9a). They
## don't use packets: each level is bought with Salvage, from command mode (Castle tab tools
## on a socket) or with E in first person. State lives in the castle dict as plain data:
##   c.sockets = [{ cell: Vector2i, turret: "" | type, level: 0..3, hp, cd }]
## Firing, creeper damage and visuals: CastleTurretFire. While any turret stands a siege
## can't retake the castle; a retake destroys them all.

const DEFS := {
	"repeater": { "label": "Repeater", "costs": [25, 40, 70], "hp": [80.0, 120.0, 180.0], "range": 18.0,
		"interval": 0.6, "power": [2.0, 3.0, 4.5], "targets": "raiders", "color": Color("ffd166"),
		"desc": "Anti-raider gun: fast shots at raiders in range 18." },
	"lobber": { "label": "Lobber", "costs": [30, 45, 75], "hp": [80.0, 120.0, 180.0], "range": 14.0,
		"interval": 3.0, "power": [4.8, 6.0, 7.2], "splash": 2.0, "targets": "creeper", "color": Color("ff9f43"),
		"desc": "Clears creeper in and near the walls: lobs a mortar shell at 60% strength, range 14." },
	"flak": { "label": "Flak", "costs": [25, 40, 70], "hp": [80.0, 120.0, 180.0], "range": 20.0,
		"interval": 0.8, "power": [3.0, 4.5, 6.0], "targets": "air", "color": Color("ff6b6b"),
		"desc": "Air only: bursts spore volleys (and flyers, later) in range 20." },
}
const ORDER := ["repeater", "lobber", "flak"]


## 4 wall corners plus the wall cell beside each gate, all on the wall walk.
static func socket_cells(lay: Dictionary) -> Array[Vector2i]:
	var r: Rect2i = lay.rect
	var out: Array[Vector2i] = [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y),
		Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]
	var n := r.size.x
	for gt in lay.gates:
		out.append(CastleShape._at(r, gt.side, n / 2 - 2, 0))
	return out


static func new_sockets(lay: Dictionary) -> Array:
	return socket_cells(lay).map(func(cell): return { "cell": cell, "turret": "", "level": 0, "hp": 0.0, "cd": 0.0 })


## Index of the socket on or right next to `cell`, or -1.
static func socket_at(c: Dictionary, cell: Vector2i) -> int:
	for i in c.sockets.size():
		var s: Vector2i = c.sockets[i].cell
		if absi(s.x - cell.x) <= 1 and absi(s.y - cell.y) <= 1:
			return i
	return -1


static func alive(s: Dictionary) -> bool:
	return s.turret != "" and s.hp > 0.0


static func any_alive(c: Dictionary) -> bool:
	return c.get("sockets", []).any(func(s): return alive(s))


## What buying `type` at socket i would do: { ok, reason, cost, level }.
static func check(c: Dictionary, i: int, type: String, salvage: float) -> Dictionary:
	if c.owner != "player":
		return { "ok": false, "reason": "Capture %s before arming its sockets" % c.name }
	if i < 0:
		return { "ok": false, "reason": "Pick a turret socket: wall corners and beside the gate" }
	var s: Dictionary = c.sockets[i]
	var def: Dictionary = DEFS[type]
	if s.turret != "" and s.turret != type:
		return { "ok": false, "reason": "That socket holds a %s (recycle it first)" % DEFS[s.turret].label }
	if s.level >= 3:
		return { "ok": false, "reason": "%s is at level III" % def.label }
	var cost: int = def.costs[s.level]
	if salvage + 0.001 < cost:
		return { "ok": false, "reason": "%s %s needs %d Salvage" % [def.label, _roman(s.level + 1), cost] }
	return { "ok": true, "reason": "", "cost": cost, "level": s.level + 1 }


## Buys (or upgrades) `type` at socket i. Returns "" or the reason it failed.
static func buy(c: Dictionary, i: int, type: String, stockpile: Stockpile) -> String:
	var res := check(c, i, type, stockpile.salvage)
	if not res.ok:
		return res.reason
	stockpile.spend("salvage", res.cost)
	var s: Dictionary = c.sockets[i]
	s.turret = type
	s.level = res.level
	s.hp = DEFS[type].hp[s.level - 1]
	Bus.say("%s %s armed on %s." % [DEFS[type].label, _roman(s.level), c.name], "good")
	return ""


## E in first person: upgrades what stands there, or arms an empty socket with a Repeater.
static func use_label(c: Dictionary, i: int, salvage: float) -> String:
	var s: Dictionary = c.sockets[i]
	var type: String = s.turret if s.turret != "" else "repeater"
	var res := check(c, i, type, salvage)
	if res.ok:
		return "[%s] %s %s (%d Salvage)" % [Keybinds.short("use"), DEFS[type].label, _roman(res.level), res.cost]
	return res.reason


static func clear(c: Dictionary) -> void:
	for s in c.get("sockets", []):
		s.turret = ""
		s.level = 0
		s.hp = 0.0


static func _roman(n: int) -> String:
	return ["", "I", "II", "III"][clampi(n, 0, 3)]
