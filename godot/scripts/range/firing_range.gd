class_name FiringRange
extends TacticalScene
## Scene root for the Firing Range (firing_range.tscn). Wiring only: lanes, targets, benches, crate, deploy truck.
## The Skirmish is its own scene (SkirmishScene); shared steps live in TacticalScene.


func map_id() -> String:
	return "range"


func _build() -> void:
	_begin()
	RangeLayout.build(self)
	_add_rack()
	_add_player(RangeLayout.SPAWN)
	add_child(targets)
	_add_feedback()
	var bench := RangeBench.new()
	add_child(bench)
	bench.setup(weapons, player, targets, hit_log)
	_add_items()
	RangeCrate.build(self, world_items)
	var truck := RangeTruck.new()
	add_child(truck)
	truck.setup(weapons, player)
	_add_inventory()
	var workbench := RangeWorkbench.new()  # F11: weapon customization station
	add_child(workbench)
	workbench.setup(weapons, player, inv_ui)
	_add_hud()
	add_child(bots)
	bots.setup(session, weapons, bal, hit_log)
	_add_menu()
