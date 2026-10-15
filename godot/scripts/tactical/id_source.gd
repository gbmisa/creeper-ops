class_name IdSource
extends RefCounted
## Session-owned id issuer for items and entities. In MP-2 the server issues these;
## offline the session does. Replaces static per-class counters (ItemDefs._uid).
## `note()` keeps issued ids above any loaded one (save/load round-trips).

var _next := 0


func next() -> int:
	_next += 1
	return _next


func note(u: int) -> void:
	_next = maxi(_next, u)
