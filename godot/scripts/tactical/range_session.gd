class_name RangeSession
extends RefCounted
## Per-session multiplayer-ready state (MULTIPLAYER.md rules 1-8). FiringRange creates one per
## map load; systems take what they need from it. No autoloads, no per-player statics.
## Offline there is exactly one player (players[0] == local); MP-2 adds remote PlayerStates.

var players: Array[PlayerState] = []
var local: PlayerState
var ids := IdSource.new()
var seed := 0
var events := TacEvents.new()
var noise := BotNoise.new()
var maps := RangeMaps.new()
var saved_kit := {}  # was static RangeLoadout.saved: carried kit between maps
var _seed_counter := 0


func _init(p_seed := 0) -> void:
	seed = p_seed


## Registers a player. Peer 1 is the local player offline; MP-2 assigns server-issued ids.
func add_player(peer_id: int, p_is_local: bool) -> PlayerState:
	var s := PlayerState.new(peer_id)
	s.is_local = p_is_local
	s.inv.ids = ids
	players.append(s)
	if p_is_local:
		local = s
	return s


## Deterministic per-entity seed derived from the session seed (MULTIPLAYER.md rule 5).
func next_seed() -> int:
	_seed_counter += 1
	return seed * 131071 + _seed_counter * 7919 + 17


## Nearest living player to a point (bots target this, not a singleton).
func nearest_player(pos: Vector3) -> PlayerState:
	var best: PlayerState = null
	var best_d := INF
	for s in players:
		if s.node == null or s.node.body.dead:
			continue
		var d := pos.distance_squared_to(s.node.global_position)
		if d < best_d:
			best_d = d
			best = s
	return best


## Carry-out kit: save the inventory, then go to the Skirmish map (was RangeLoadout.deploy).
func deploy(inv: Inventory) -> void:
	save_kit(inv)
	maps.go("skirmish")


## Save the kit without changing map (tests).
func save_kit(inv: Inventory) -> void:
	saved_kit = inv.to_dict()
	RangeMaps.carried_kit = saved_kit  # F6: survives the scene reload (fresh session each map)


## KIA: the kit is lost, the next start uses the default kit (was RangeLoadout.clear).
func clear_kit() -> void:
	saved_kit = {}
	RangeMaps.carried_kit = {}
