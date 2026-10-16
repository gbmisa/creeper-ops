class_name Magazine
extends RefCounted
## A stack of rounds of ONE ammo type (F79; ids kept per round for simple pop/count). Also used for tubes and clips.
## push() refuses a round of another type; the loader must empty the mag first (or pick the matching type).

var cap := 30
var rounds: Array[String] = []


func _init(capacity: int = 30) -> void:
	cap = capacity


func count() -> int:
	return rounds.size()


func is_full() -> bool:
	return rounds.size() >= cap


func push(ammo_id: String) -> bool:
	if is_full() or not accepts(ammo_id):
		return false
	rounds.append(ammo_id)
	return true


## True if a round of this type may join (an empty magazine takes any type).
func accepts(ammo_id: String) -> bool:
	return rounds.is_empty() or rounds[0] == ammo_id


## Old saves / hand-built lists: every round becomes the first round's type.
func normalize() -> void:
	for i in range(1, rounds.size()):
		rounds[i] = rounds[0]


func pop() -> String:
	return rounds.pop_back() if not rounds.is_empty() else ""


func top() -> String:
	return rounds.back() if not rounds.is_empty() else ""


func fill(ammo_id: String) -> void:
	rounds.clear()
	for i in cap:
		rounds.append(ammo_id)


## Tarkov-style estimate (exact for small magazines).
func estimate() -> String:
	var n := rounds.size()
	if n == 0:
		return "Empty"
	if cap <= TacticalConfig.EXACT_COUNT_MAX_CAP:
		return "%d round%s" % [n, "" if n == 1 else "s"]
	var f := float(n) / float(cap)
	for row in TacticalConfig.MAG_WORDS:
		if f >= row[0]:
			return row[1]
	return "Almost empty"


## Plain-data snapshot (MULTIPLAYER.md rule 6).
func to_dict() -> Dictionary:
	return {"cap": cap, "rounds": rounds.duplicate()}


static func from_dict(d: Dictionary) -> Magazine:
	var m := Magazine.new(int(d.get("cap", 30)))
	for r in d.get("rounds", []):
		m.rounds.append(str(r))
	m.normalize()
	return m
