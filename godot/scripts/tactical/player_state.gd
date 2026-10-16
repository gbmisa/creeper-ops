class_name PlayerState
extends RefCounted
## Per-player multiplayer-ready state (MULTIPLAYER.md rule 1). Owns the inventory,
## stats and identity. The body (TacticalPlayer node) owns BodyHealth and physics; this owns data.
## `node` is null until the player spawns (tests may use the state without a body).

var peer_id := 0
var node: TacticalPlayer
var inv := Inventory.new()
var stats := {"kills": 0, "shots": 0, "hits": 0}
var is_local := false


func _init(p_peer_id := 0) -> void:
	peer_id = p_peer_id


func body() -> BodyHealth:
	return node.body if node != null else null


func to_dict() -> Dictionary:
	return {
		"peer_id": peer_id,
		"stats": stats.duplicate(),
		"inv": inv.to_dict(),
		"body": node.body.to_dict() if node != null else {},
	}


static func from_dict(d: Dictionary) -> PlayerState:
	var s := PlayerState.new(int(d.get("peer_id", 0)))
	# an old save's "recoil_mode" key (the removed Classic/Tarkov toggle, FB-I) is ignored
	s.stats = (d.get("stats", {}) as Dictionary).duplicate()
	s.inv = Inventory.from_dict(d.get("inv", {}) as Dictionary)
	return s
