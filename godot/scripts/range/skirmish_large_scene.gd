class_name SkirmishLargeScene
extends TacticalScene
## Scene root for the large Skirmish map (skirmish_large.tscn, R5 expand): ~220 m, four districts around the
## original compound, three random south-edge spawns, three extracts. Same wiring as SkirmishScene; only the
## game / data classes differ (SkirmishLargeGame, SkirmishLargeData). Bots, kit, loot and end screen are shared.


func map_id() -> String:
	return "skirmish_large"


func _build() -> void:
	_begin()
	session.mark_walk_in()
	skirmish = SkirmishLargeGame.new()
	add_child(skirmish)
	skirmish.build_world()
	_add_rack(SkirmishLargeData.RACK_POS, true)
	# 3 edge spawns, picked at random each run.
	_add_player(SkirmishLargeData.SPAWNS[randi_range(0, SkirmishLargeData.SPAWNS.size() - 1)])
	_add_feedback()
	_add_items()
	_add_inventory()
	var hud := _add_hud()
	skirmish.start(player, weapons, bal, hit_log, hud, session)
	bots.bots = skirmish.bots
	if session.saved_kit.is_empty():
		weapons.give("m1911")   # fallback only when no kit was deployed
	_add_menu()
