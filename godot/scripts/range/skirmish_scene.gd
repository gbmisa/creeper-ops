class_name SkirmishScene
extends TacticalScene
## Scene root for the Skirmish map (skirmish.tscn, F82). Wiring only: SkirmishGame builds the map, bots, loot
## and extraction; the player arrives with the kit the deploy truck saved. No range rules run here.


func map_id() -> String:
	return "skirmish"


func _build() -> void:
	_begin()
	session.mark_walk_in()
	skirmish = SkirmishGame.new()
	add_child(skirmish)
	skirmish.build_world()
	_add_rack(SkirmishData.RACK_POS, true)
	_add_player(SkirmishData.SPAWN)
	_add_feedback()
	_add_items()
	_add_inventory()
	var hud := _add_hud()
	skirmish.start(player, weapons, bal, hit_log, hud, session)
	bots.bots = skirmish.bots
	if session.saved_kit.is_empty():
		weapons.give("m1911")   # fallback only when no kit was deployed
	_add_menu()
