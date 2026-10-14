class_name Magazine
extends RefCounted
## A stack of rounds (ammo ids, top = last; mixed loads allowed). Also used for tubes and clips.

var cap := 30
var rounds: Array[String] = []


func _init(capacity: int = 30) -> void:
	cap = capacity


func count() -> int:
	return rounds.size()


func is_full() -> bool:
	return rounds.size() >= cap


func push(ammo_id: String) -> bool:
	if is_full():
		return false
	rounds.append(ammo_id)
	return true


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
